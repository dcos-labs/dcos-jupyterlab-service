#!/usr/bin/env bash

set -o errexit -o pipefail

SPARK_HISTORY_FS_LOGDIRECTORY=${SPARK_HISTORY_FS_LOGDIRECTORY:-"${MESOS_SANDBOX}"} \
SPARK_LOG_DIR=${SPARK_LOG_DIR:-"${MESOS_SANDBOX}"} \
PORT_SPARKHISTORY=${PORT_SPARKHISTORY:-"18080"} \
SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=${SPARK_HISTORY_FS_LOGDIRECTORY} \
    -Dspark.history.ui.port=${PORT_SPARKHISTORY} \
    -Dspark.ui.proxyBase=${MARATHON_APP_LABEL_HAPROXY_0_PATH}/sparkhistory \
    ${SPARK_HISTORY_OPTS}" \
/opt/spark/sbin/start-history-server.sh >> "${MESOS_SANDBOX}/spark-history.log" 2>&1
