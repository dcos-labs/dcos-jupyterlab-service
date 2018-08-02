#!/usr/bin/env bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

# Exec the specified command or fall back on bash
if [ $# -eq 0 ]; then
    cmd=bash
else
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

    if [ -z ${MESOS_SANDBOX+x} ]; then
        export MESOS_SANDBOX="${HOME}"
    else
        # Copy over profile files for convenience
        cp /home/beakerx/.bash_profile "${MESOS_SANDBOX}/"
        cp /home/beakerx/.bashrc "${MESOS_SANDBOX}/"
        cp /home/beakerx/.profile "${MESOS_SANDBOX}/"
    fi
    echo "MESOS_SANDBOX: ${MESOS_SANDBOX}"

    # Kerberos Credentials Cache
    KRB5CCNAME=${KRB5CCNAME:-"/tmp/krb5cc_$(id -u)"}
    export KRB5CCNAME

    # Add Hadoop Jars to CLASSPATH
    CLASSPATH=$("${HADOOP_HDFS_HOME}/bin/hadoop" classpath --glob):"${CLASSPATH}"
    export CLASSPATH

    # Set environment variables for Spark Monitor
    # https://krishnan-r.github.io/sparkmonitor/install.html
    export SPARKMONITOR_UI_HOST="${MESOS_CONTAINER_IP}"
    export SPARKMONITOR_UI_PORT=${PORT_SPARKUI:-"4040"}

    # ${HOME} is set to ${MESOS_SANDBOX} on DC/OS and won't have a default IPython profile
    # We have to manually check since `ipython profile locate default` *creates* the config
    if [ ! -f "${MESOS_SANDBOX}/.ipython/profile_default/ipython_kernel_config.py" ]; then
        ipython profile create default
        # Enable the SparkMonitor Jupyter Kernel Extension
        echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" \
            >> "$(ipython profile locate default)/ipython_kernel_config.py"
    fi

    # Copy over beakerx.json so that we have a sane set of defaults for Mesosphere DC/OS
    if [ ! -f "${MESOS_SANDBOX}/.jupyter/beakerx.json" ]; then
        mkdir -p "${MESOS_SANDBOX}/.jupyter"
        cp "/home/beakerx/.jupyter/beakerx.json" "${MESOS_SANDBOX}/.jupyter/"
    fi

    # Copy over .hadooprc so that `hadoop fs s3a://<bucket>/` works OOTB, if providing Hadoop 3.x
    if [ ! -f "${MESOS_SANDBOX}/.hadooprc" ]; then
        cp "/home/beakerx/.hadooprc" "${MESOS_SANDBOX}/.hadooprc"
    fi

    # Start Spark History Server?
    if [ ${START_SPARK_HISTORY+x} ]; then
        SPARK_HISTORY_FS_LOGDIRECTORY=${SPARK_HISTORY_FS_LOGDIRECTORY:-"${MESOS_SANDBOX}"} \
        SPARK_LOG_DIR=${SPARK_LOG_DIR:-"${MESOS_SANDBOX}"} \
        PORT_SPARKHISTORY=${PORT_SPARKHISTORY:-"18080"} \
        SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=${SPARK_HISTORY_FS_LOGDIRECTORY} \
            -Dspark.history.ui.port=${PORT_SPARKHISTORY} \
            -Dspark.ui.proxyBase=${MARATHON_APP_LABEL_HAPROXY_0_PATH}/sparkhistory \
            ${SPARK_HISTORY_OPTS}" \
        /opt/spark/sbin/start-history-server.sh
    fi

    # Start Tensorboard?
    if [ ${START_TENSORBOARD+x} ]; then
        TENSORBOARD_LOGDIR=${TENSORBOARD_LOGDIR:-"${MESOS_SANDBOX}"}
        if [ ${PORT_TFDBG+x} ]; then
            TENSORBOARD_ARGS="${TENSORBOARD_ARGS} --debugger_port ${PORT_TFDBG}"
        fi
        tensorboard \
            --host localhost \
            --port 6006 \
            --logdir "${TENSORBOARD_LOGDIR}" \
            "${TENSORBOARD_ARGS}" 2>&1 &
    fi

    # Start Dask Distributed Scheduler?
    if [ ${START_DASK_DISTRIBUTED+x} ]; then
        PORT_DASKSCHEDULER=${PORT_DASKSCHEDULER:-"8786"}
        PORT_DASKBOARD=${PORT_DASKBOARD:-"8787"}
        dask-scheduler \
            --port "${PORT_DASKSCHEDULER}" \
            --bokeh-port "${PORT_DASKBOARD}" \
            --bokeh-prefix "${MARATHON_APP_LABEL_HAPROXY_0_PATH}/daskboard" 2>&1 &
    fi

    # Start Ray Head Node?
    if [ ${START_RAY_HEAD_NODE+x} ]; then
        PORT_RAYREDIS=${PORT_RAYREDIS:-"6379"}
        PORT_RAYOBJECTMANAGER=${PORT_RAYOBJECTMANAGER:-"8076"}
        if [ ${MARATHON_APP_RESOURCE_CPUS+x} ]; then
            RAY_CPUS=$(python -c \
                "import os; print(int(
                 float(os.getenv('MARATHON_APP_RESOURCE_CPUS'))))"
            )
            RAY_ARGS="${RAY_ARGS} --num-cpus=${RAY_CPUS}"
        fi
        if [ ${MARATHON_APP_RESOURCE_GPUS+x} ]; then
            RAY_GPUS=$(python -c \
                "import os; print(int(
                 float(os.getenv('MARATHON_APP_RESOURCE_GPUS'))))"
            )
            RAY_ARGS="${RAY_ARGS} --num-gpus=${RAY_GPUS}"
        fi
        if [ ${MARATHON_APP_RESOURCE_MEM+x} ]; then
            PLASMA_MEMORY_BYTES=$(python -c \
                 "import os; print(str(int(
                  float(os.getenv('MARATHON_APP_RESOURCE_MEM'))
                  * float(os.getenv('PLASMA_MEMORY_FRACTION', '0.4'))
                  * 1024 * 1024)))"
            )
            RAY_ARGS="${RAY_ARGS} --object-store-memory=${PLASMA_MEMORY_BYTES}"
        fi
        echo "RAY_ARGS: ${RAY_ARGS}"
        ray start ${RAY_ARGS} \
            --node-ip-address="${MESOS_CONTAINER_IP}" \
            --redis-port="${PORT_RAYREDIS}" \
            --object-manager-port="${PORT_RAYOBJECTMANAGER}" \
            --head \
            --no-ui
    fi

    # bootstrap needs ${MESOS_SANDBOX} set to obtain the relative path to the mustache template(s)
    MESOS_SANDBOX="/" \
        CONFIG_TEMPLATE_NGINX_CONF="/opt/mesosphere/nginx.conf.mustache,/usr/local/openresty/nginx/conf/nginx.conf" \
        bootstrap -template -resolve=false --print-env=false -install-certs=false

    MESOS_SANDBOX="/" \
        CONFIG_TEMPLATE_NGINX_PROXY_CONF="/opt/mesosphere/proxy.conf.mustache,/usr/local/openresty/nginx/conf/sites/proxy.conf" \
        bootstrap -template -resolve=false --print-env=false -install-certs=false

    # Start Openresty for (Optional) OpenID Connect Authentication: https://github.com/zmartzone/lua-resty-openidc
    openresty

    cmd=$*
fi

# Run additional scripts in /usr/local/bin/start-notebook.d/
for f in /usr/local/bin/start-notebook.d/*; do
    case "$f" in
        *.sh)
            echo "$0: running $f"; . "$f"
            ;;
        *)
            if [ -x $f ]; then
                echo "$0: running $f"
                $f
            else
                echo "$0: ignoring $f"
            fi
            ;;
    esac
    echo
done

# Handle special flags if we're root
if [ "$(id -u)" == '0' ] ; then

    # Only attempt to change the beakerx username if it exists
    if id beakerx &> /dev/null ; then
        echo "Set username to: ${NB_USER}"
        usermod -d "/home/${NB_USER}" -l "${NB_USER}" beakerx
    fi

    # Handle case where provisioned storage does not have the correct permissions by default
    # Ex: default NFS/EFS (no auto-uid/gid)
    if [[ "${CHOWN_HOME}" == "1" || "${CHOWN_HOME}" == 'yes' ]]; then
        echo "Changing ownership of /home/${NB_USER} to ${NB_UID}:${NB_GID}"
        chown "${CHOWN_HOME_OPTS}" "${NB_UID}:${NB_GID}" "/home/${NB_USER}"
    fi

    if [ ! -z "${CHOWN_EXTRA}" ]; then
        for extra_dir in $(echo "${CHOWN_EXTRA}" | tr ',' ' '); do
            chown "${CHOWN_EXTRA_OPTS}" "${NB_UID}:${NB_GID}" "${extra_dir}"
        done
    fi

    if [ -d "${MESOS_SANDBOX}" ];then
        # Change ownership of $MESOS_SANDBOX so that $NB_USER can write to it
        chown -R "${NB_UID}:${NB_GID}" "${MESOS_SANDBOX}"
    fi

    # handle home and working directory if the username changed
    if [[ "${NB_USER}" != "beakerx" ]]; then
        # changing username, make sure homedir exists
        # (it could be mounted, and we shouldn't create it if it already exists)
        if [[ ! -e "/home/${NB_USER}" ]]; then
            echo "Relocating home dir to /home/${NB_USER}"
            mv /home/beakerx "/home/${NB_USER}"
        fi
        # if workdir is in /home/beakerx, cd to /home/$NB_USER
        if [[ "${PWD}/" == "/home/beakerx/"* ]]; then
            newcwd="/home/${NB_USER}/${PWD:13}"
            echo "Setting CWD to ${newcwd}"
            cd "${newcwd}"
        fi
    fi

    # Change UID of NB_USER to NB_UID if it does not match
    if [ "${NB_UID}" != "$(id -u ${NB_USER})" ] ; then
        echo "Set ${NB_USER} UID to: ${NB_UID}"
        usermod -u "${NB_UID}" "${NB_USER}"
    fi

    # Add NB_USER to NB_GID if it's not the default group
    if [ "${NB_GID}" != "$(id -g ${NB_USER})" ] ; then
        echo "Add $NB_USER to group: $NB_GID"
        groupadd -g $NB_GID -o $NB_USER
        usermod -a -G $NB_GID $NB_USER
    fi

    # Enable sudo if requested
    #if [[ "$GRANT_SUDO" == "1" || "$GRANT_SUDO" == 'yes' ]]; then
    #    echo "Granting $NB_USER sudo access and appending $CONDA_DIR/bin to sudo PATH"
    #    echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook
    #fi

    # Add $CONDA_DIR/bin to sudo secure_path
    #sed -r "s#Defaults\s+secure_path=\"([^\"]+)\"#Defaults secure_path=\"\1:$CONDA_DIR/bin\"#" /etc/sudoers | grep secure_path > /etc/sudoers.d/path

    # Exec the command as NB_USER with the PATH and the rest of
    # the environment preserved
    echo "Executing the command: ${cmd}"
    exec sudo -E -H -u "${NB_USER}" PATH="${PATH}" PYTHONPATH="${PYTHONPATH}" ${cmd}
else
    if [[ "${NB_UID}" == "$(id -u beakerx)" && "${NB_GID}" == "$(id -g beakerx)" ]]; then
        # User is not attempting to override user/group via environment
        # variables, but they could still have overridden the uid/gid that
        # container runs as. Check that the user has an entry in the passwd
        # file and if not add an entry.
	whoami &> /dev/null || STATUS=$? && true
	if [[ "${STATUS}" != "0" ]]; then
            if [[ -w /etc/passwd ]]; then
                echo "Adding passwd file entry for $(id -u)"
                sed -e "s/^beakerx:/xrekaeb:/" /etc/passwd > /tmp/passwd
                echo "beakerx:x:$(id -u):$(id -g):,,,:/home/beakerx:/bin/bash" >> /tmp/passwd
                cat /tmp/passwd > /etc/passwd
                rm /tmp/passwd
            else
                echo 'Container must be run with group root to update passwd file'
            fi
        fi

        # Warn if the user isn't going to be able to write files to $HOME.
        if [[ ! -w /home/beakerx ]]; then
            echo 'Container must be run with group users to update files'
        fi
    else
        # Warn if looks like user want to override uid/gid but hasn't
        # run the container as root.
        if [[ ! -z "${NB_UID}" && "${NB_UID}" != "$(id -u)" ]]; then
            echo 'Container must be run as root to set ${NB_UID}'
        fi
        if [[ ! -z "${NB_GID}" && "${NB_GID}" != "$(id -g)" ]]; then
            echo 'Container must be run as root to set $NB_GID'
        fi
    fi

    # Warn if looks like user want to run in sudo mode but hasn't run
    # the container as root.
    #if [[ "${GRANT_SUDO}" == "1" || "${GRANT_SUDO}" == 'yes' ]]; then
    #    echo 'Container must be run as root to grant sudo permissions'
    #fi

    # Execute the command
    echo "Executing the command: ${cmd}"
    exec ${cmd}
fi
