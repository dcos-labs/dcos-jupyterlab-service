#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This file is sourced when running various Spark programs.
# Copy it as spark-env.sh and edit that to configure Spark for your site.

# Using Spark's "Hadoop Free" Build
# https://spark.apache.org/docs/latest/hadoop-provided.html
SPARK_DIST_CLASSPATH=$("${HADOOP_HDFS_HOME}/bin/hadoop" classpath):"${HADOOP_HDFS_HOME}/share/hadoop/tools/lib/*"
export SPARK_DIST_CLASSPATH

if [ -d "${MESOS_SANDBOX}" ] ; then
    cd "${MESOS_SANDBOX}" || exit
    MESOSPHERE_PREFIX=${MESOSPHERE_PREFIX:-"/opt/mesosphere"}
    export MESOSPHERE_PREFIX
    export BOOTSTRAP=${MESOSPHERE_PREFIX}/bin/bootstrap
    export HADOOP_CONF_DIR=${MESOS_SANDBOX}
    export HIVE_CONF_DIR=${MESOS_SANDBOX}
    export LIBPROCESS_SSL_CA_DIR=${MESOS_SANDBOX}/.ssl/
    export LIBPROCESS_SSL_CA_FILE=${MESOS_SANDBOX}/.ssl/ca.crt
    export LIBPROCESS_SSL_CERT_FILE=${MESOS_SANDBOX}/.ssl/scheduler.crt
    export LIBPROCESS_SSL_KEY_FILE=${MESOS_SANDBOX}/.ssl/scheduler.key
    export MESOS_AUTHENTICATEE="com_mesosphere_dcos_ClassicRPCAuthenticatee"
    export MESOS_HTTP_AUTHENTICATEE="com_mesosphere_dcos_http_Authenticatee"
    export MESOS_DIRECTORY=${MESOS_SANDBOX}
    export MESOS_MODULES="{\"libraries\": [{\"file\": \"libdcos_security.so\", \"modules\": [{\"name\": \"com_mesosphere_dcos_ClassicRPCAuthenticatee\"}]}]}"
    export MESOS_NATIVE_JAVA_LIBRARY=${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so
    export MESOS_NATIVE_LIBRARY=${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so

    # Unless explicitly directed, use bootstrap to lookup the IP of the driver agent
    # this should be LIBPROCESS_IP iff the driver is on the host network, $(hostname) when it's not (e.g. CNI).
    if [ -z "${SKIP_BOOTSTRAP_IP_DETECT}" ]; then
        if [ -f "${BOOTSTRAP}" ]; then
            echo "spark-env: Using bootstrap to set SPARK_LOCAL_IP" >&2
            SPARK_LOCAL_IP=$($BOOTSTRAP --get-task-ip)
            echo "spark-env: bootstrap set SPARK_LOCAL_IP=${SPARK_LOCAL_IP}" >&2
        else
            echo "spark-env: ERROR: Unable to find bootstrap at: ${BOOTSTRAP}, exiting." >&2
            exit 1
        fi
    else
        echo "Skipping bootstrap IP detection" >&2
    fi

    echo "spark-env: User: $(whoami)" >&2

    if ls ${MESOS_SANDBOX}/*.base64 1> /dev/null 2>&1; then
        echo "spark-env: Decoding files in ${MESOS_SANDBOX} that end in .base64" >&2
        for f in ${MESOS_SANDBOX}/*.base64 ; do
            secret=$(basename "${f}" .base64)
            echo "spark-env: Decoding base64-encoded ${f} to ${secret}" >&2
            base64 -d "${f}" > "${secret}"
        done
    fi

    if [ -n "${SPARK_SECURITY_KERBEROS_KDC_HOSTNAME}" ] && [ -n "${SPARK_SECURITY_KERBEROS_KDC_PORT}" ] && [ -n "${SPARK_SECURITY_KERBEROS_REALM}" ]; then
        echo "spark-env: Rendering krb5.conf from environment variables" >&2
        CONFIG_TEMPLATE_KRB5CONF=../../../etc/krb5.conf.mustache,/etc/krb5.conf $BOOTSTRAP -template -resolve=false --print-env=false -install-certs=false
        echo "spark-env: /etc/krb5.conf" >&2
        cat /etc/krb5.conf >&2
    fi

    if [[ -n "${SPARK_MESOS_KRB5_CONF_BASE64}" ]]; then
        echo "spark-env: Setting up to decode krb5.conf from SPARK_MESOS_KRB5_CONF_BASE64" >&2
        KRB5CONF=${SPARK_MESOS_KRB5_CONF_BASE64}
    fi

    if [[ -n "${KRB5_CONFIG_BASE64}" ]]; then
        echo "spark-env: Setting up to decode krb5.conf from KRB5_CONFIG_BASE64" >&2
        KRB5CONF=${KRB5_CONFIG_BASE64}
    fi

    if [[ -n "${KRB5CONF}" ]]; then
        if base64 --help | grep -q GNU; then
              BASE64_D="base64 -d" # GNU
          else
              BASE64_D="base64 -D" # BSD
        fi
        echo "spark-env: Decoding base64-encoded krb5.conf to /etc/krb5.conf" >&2
        echo "${KRB5CONF}" | ${BASE64_D} > /etc/krb5.conf
        echo "spark-env: /etc/krb5.conf" >&2
        cat /etc/krb5.conf >&2
    else
        echo "spark-env: No SPARK_MESOS_KRB5_CONF_BASE64 or KRB5_CONFIG_BASE64 env var present from which to decode krb5.conf" >&2
    fi

    if [ -f "${MESOS_SANDBOX}/krb5.conf" ]; then
        echo "spark-env: Found krb5.conf in ${MESOS_SANDBOX}. Copying to /etc" >&2
        cp "${MESOS_SANDBOX}/krb5.conf" /etc
        echo "spark-env: /etc/krb5.conf" >&2
        cat /etc/krb5.conf >&2
    fi

    if [ -f "${MESOS_SANDBOX}/krb5cc_$(id -u)" ]; then
        echo "spark-env: Found Kerberos Credentials Cache: krb5cc_$(id -u) in ${MESOS_SANDBOX}. Moving to /tmp" >&2
        mv "${MESOS_SANDBOX}/krb5cc_$(id -u)" /tmp
        echo "spark-env: Exporting KRB5CCNAME=/tmp/krb5cc_$(id -u) if not already set" >&2
        KRB5CCNAME=${KRB5CCNAME:-"/tmp/krb5cc_$(id -u)"}
        export KRB5CCNAME
    fi

fi

# Options read when launching programs locally with
# ./bin/run-example or ./bin/spark-submit
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public dns name of the driver program

# Options read by executors and drivers running inside the cluster
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public DNS name of the driver program
# - SPARK_LOCAL_DIRS, storage directories to use on this node for shuffle and RDD data
# - MESOS_NATIVE_JAVA_LIBRARY, to point to your libmesos.so if you use Mesos

# Options read in YARN client mode
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
# - SPARK_EXECUTOR_CORES, Number of cores for the executors (Default: 1).
# - SPARK_EXECUTOR_MEMORY, Memory per Executor (e.g. 1000M, 2G) (Default: 1G)
# - SPARK_DRIVER_MEMORY, Memory for Driver (e.g. 1000M, 2G) (Default: 1G)

# Options for the daemons used in the standalone deploy mode
# - SPARK_MASTER_HOST, to bind the master to a different IP address or hostname
# - SPARK_MASTER_PORT / SPARK_MASTER_WEBUI_PORT, to use non-default ports for the master
# - SPARK_MASTER_OPTS, to set config properties only for the master (e.g. "-Dx=y")
# - SPARK_WORKER_CORES, to set the number of cores to use on this machine
# - SPARK_WORKER_MEMORY, to set how much total memory workers have to give executors (e.g. 1000m, 2g)
# - SPARK_WORKER_PORT / SPARK_WORKER_WEBUI_PORT, to use non-default ports for the worker
# - SPARK_WORKER_DIR, to set the working directory of worker processes
# - SPARK_WORKER_OPTS, to set config properties only for the worker (e.g. "-Dx=y")
# - SPARK_DAEMON_MEMORY, to allocate to the master, worker and history server themselves (default: 1g).
# - SPARK_HISTORY_OPTS, to set config properties only for the history server (e.g. "-Dx=y")
# - SPARK_SHUFFLE_OPTS, to set config properties only for the external shuffle service (e.g. "-Dx=y")
# - SPARK_DAEMON_JAVA_OPTS, to set config properties for all daemons (e.g. "-Dx=y")
# - SPARK_DAEMON_CLASSPATH, to set the classpath for all daemons
# - SPARK_PUBLIC_DNS, to set the public dns name of the master or workers

# Generic options for the daemons used in the standalone deploy mode
# - SPARK_CONF_DIR      Alternate conf dir. (Default: ${SPARK_HOME}/conf)
# - SPARK_LOG_DIR       Where log files are stored.  (Default: ${SPARK_HOME}/logs)
# - SPARK_PID_DIR       Where the pid file is stored. (Default: /tmp)
# - SPARK_IDENT_STRING  A string representing this instance of spark. (Default: $USER)
# - SPARK_NICENESS      The scheduling priority for daemons. (Default: 0)
# - SPARK_NO_DAEMONIZE  Run the proposed command in the foreground. It will not output a PID file.
