#!/usr/bin/env bash

set -o errexit -o pipefail

# bootstrap requires that ${LIBPROCESS_IP} or ${MESOS_CONTAINER_IP} be set
if [ -z ${LIBPROCESS_IP+x} ]; then
    CONTAINER_IP=$(LIBPROCESS_IP="0.0.0.0" bootstrap -get-task-ip);
    export LIBPROCESS_IP="${CONTAINER_IP}"
else
    CONTAINER_IP=$(bootstrap -get-task-ip)
fi

export CONTAINER_IP
echo "CONTAINER_IP: ${CONTAINER_IP}"
echo "LIBPROCESS_IP: ${LIBPROCESS_IP}"

if [ -z ${MESOS_CONTAINER_IP+x} ]; then
    export MESOS_CONTAINER_IP="${CONTAINER_IP}"
fi
echo "MESOS_CONTAINER_IP: ${MESOS_CONTAINER_IP}"

# Are we running under Mesos?
if [ ${MESOS_SANDBOX+x} ]; then
    DASK_COMPUTED_ADDRESS=""
    RAY_COMPUTED_ADDRESS=""

    # FQDN for a task is <TASK_NAME>.<FRAMEWORK_HOST>
    # <FRAMEWORK_HOST> = <FRAMEWORK_NAME>.<DOMAIN>
    # <DOMAIN> could either be an autoip or a l4lb address depending on network setup
    
    # Default to marathon unless we're running under the control of a DC/OS SDK framework
    FRAMEWORK_NAME=${FRAMEWORK_NAME:-"marathon"}

    # Register with the "notebook" app in the common/intersecting namespace, by default
    DASK_SCHEDULER_APP=${DASK_SCHEDULER_APP:-"notebook"}
    RAY_REDIS_APP=${RAY_REDIS_APP:-"notebook"}
    if [ "${LIBPROCESS_IP}" == "0.0.0.0" ]; then
        # Use the Spartan autoip address because the container is assigned an IP via CNI
        AUTOIP_SUFFIX="${FRAMEWORK_NAME}.autoip.dcos.thisdcos.directory"
        AUTOIP_PREFIX=$(python -c \
            "import os; print(
             '-'.join(os.getenv('MARATHON_APP_ID', '/worker').split('/')[::-1][:-1][1:]))"
        )
        DASK_COMPUTED_ADDRESS="${DASK_SCHEDULER_APP}-${AUTOIP_PREFIX}.${AUTOIP_SUFFIX}:8786"
        RAY_COMPUTED_ADDRESS="${RAY_REDIS_APP}-${AUTOIP_PREFIX}.${AUTOIP_SUFFIX}:6379"
    else
        # Use the L4LB address because the container is bound to the agent IP
        L4LB_SUFFIX="${FRAMEWORK_NAME}.l4lb.thisdcos.directory"
        L4LB_PREFIX=$(python -c \
            "import os; print(
             ''.join(os.getenv('MARATHON_APP_ID', '/worker').split('/')[:-1]))"
        )
        DASK_COMPUTED_ADDRESS="${L4LB_PREFIX}${DASK_SCHEDULER_APP}.${L4LB_SUFFIX}:8786"
        RAY_COMPUTED_ADDRESS="${L4LB_PREFIX}${RAY_REDIS_APP}.${L4LB_SUFFIX}:6379"
    fi
    
    DASK_SCHEDULER_ADDRESS=${DASK_SCHEDULER_ADDRESS:-$DASK_COMPUTED_ADDRESS}
    RAY_REDIS_ADDRESS=${RAY_REDIS_ADDRESS:-$RAY_COMPUTED_ADDRESS}
    export DASK_SCHEDULER_ADDRESS
    export RAY_REDIS_ADDRESS

    # Copy over profile files for convenience
    cp /etc/skel/.bash_profile "${MESOS_SANDBOX}/"
    cp /etc/skel/.bashrc "${MESOS_SANDBOX}/"
    cp /etc/skel/.dircolors "${MESOS_SANDBOX}/"
    cp /etc/skel/.profile "${MESOS_SANDBOX}/"

    # Copy over .hadooprc so that `hadoop fs s3a://<bucket>/` works OOTB, if providing Hadoop 3.x
    if [ ! -f "${MESOS_SANDBOX}/.hadooprc" ]; then
        cp "/etc/skel/.hadooprc" "${MESOS_SANDBOX}/.hadooprc"
    fi
else
    export MESOS_SANDBOX="${HOME}"
fi
echo "MESOS_SANDBOX: ${MESOS_SANDBOX}"

if [ ${START_DASK_WORKER+x} ]; then
    echo "Dask Scheduler Address: ${DASK_SCHEDULER_ADDRESS}"

    # Prefer using one worker process with as many threads as there are ceil(allocated CPUs)
    # TODO: Revisit if necessary to prefer a 1:1 mapping of workers to CPUs instead
    DASK_PROCS=${DASK_PROCS:-"1"}
    DASK_THREADS=$(python -c \
        "import os,math; print(int(math.ceil(float(
         os.getenv('MARATHON_APP_RESOURCE_CPUS', '1.0')))))"
    )
    echo "Dask Worker Threads: ${DASK_THREADS}"
    
    # Use upto 75% of allocated memory for Dask storage unless otherwise specified
    DASK_MEMORY_BYTES=$(python -c \
        "import os; print(str(int(float(
         os.getenv('MARATHON_APP_RESOURCE_MEM', '1024.0'))
                   * float(os.getenv('DASK_MEMORY_FRACTION', 0.75))
                   * 1024 * 1024)))"
    )
    echo "Dask Worker Memory Limit in Bytes: ${DASK_MEMORY_BYTES}"
    
    PORT_DASKWORKER=${PORT_DASKWORKER:-""}
    PORT_DASKNANNY=${PORT_DASKNANNY:-""}
    PORT_DASKBOKEH=${PORT_DASKBOKEH:-""}
    MESOS_TASK_ID=${MESOS_TASK_ID:-"dask-worker"}
    DASK_DEATH_TIMEOUT=${DASK_DEATH_TIMEOUT:-"180"}

    dask-worker \
        --host "${MESOS_CONTAINER_IP}" \
        --worker-port "${PORT_DASKWORKER}" \
        --nanny-port "${PORT_DASKNANNY}" \
        --bokeh-port "${PORT_DASKBOKEH}" \
        --nthreads "${DASK_THREADS}" \
        --nprocs "${DASK_PROCS}" \
        --name "${MESOS_TASK_ID}" \
        --memory-limit "${DASK_MEMORY_BYTES}" \
        --local-directory "${MESOS_SANDBOX}" \
        --death-timeout "${DASK_DEATH_TIMEOUT}" \
        "${DASK_SCHEDULER_ADDRESS}"
fi

if [ ${START_RAY_WORKER+x} ]; then
    echo "Ray Redis Address: ${RAY_REDIS_ADDRESS}"

    PORT_RAYOBJECTMANAGER=${PORT_RAYOBJECTMANAGER:-"8076"}
    RAY_CPUS=$(python -c \
        "import os; print(int(float(
         os.getenv('MARATHON_APP_RESOURCE_CPUS', '1.0'))))"
    )
    RAY_ARGS="${RAY_ARGS} --num-cpus=${RAY_CPUS}"
    RAY_GPUS=$(python -c \
        "import os; print(int(float(
         os.getenv('MARATHON_APP_RESOURCE_GPUS', '0.0'))))"
    )
    RAY_ARGS="${RAY_ARGS} --num-gpus=${RAY_GPUS}"
    PLASMA_MEMORY_BYTES=$(python -c \
         "import os; print(str(int(
          float(os.getenv('MARATHON_APP_RESOURCE_MEM', '1024.0'))
          * float(os.getenv('PLASMA_MEMORY_FRACTION', '0.75'))
          * 1024 * 1024)))"
    )
    RAY_ARGS="${RAY_ARGS} --object-store-memory=${PLASMA_MEMORY_BYTES}"
    echo "RAY_ARGS: ${RAY_ARGS}"
    ray start ${RAY_ARGS} \
        --node-ip-address="${MESOS_CONTAINER_IP}" \
        --redis-address="${RAY_REDIS_ADDRESS}" \
        --object-manager-port="${PORT_RAYOBJECTMANAGER}" \
        --block
fi
