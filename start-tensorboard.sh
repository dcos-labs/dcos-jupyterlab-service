#!/usr/bin/env bash

set -o errexit -o pipefail

# Block until jupyter configuration is complete, as otherwise dependencies such as HDFS might not be downloaded yet.
while [ ! -f "${MESOS_SANDBOX}"/JUPYTER_NOTEBOOK_CONFIG_COMPLETE ]
do
  sleep 2
  echo "TensorBoard: Waiting for Jupyter Notebook configuration to complete..."
done

TENSORBOARD_LOGDIR=${TENSORBOARD_LOGDIR:-"${MESOS_SANDBOX}"}

if [ ${PORT_TFDBG+x} ]; then
    tensorboard \
        --host 127.0.0.1 \
        --port 6006 \
        --logdir "${TENSORBOARD_LOGDIR}" \
        --path_prefix "${MARATHON_APP_LABEL_HAPROXY_0_PATH}/tensorboard" \
        --debugger_port "${PORT_TFDBG}" \
        >> "${MESOS_SANDBOX}/tensorboard.log" 2>&1 &
else
    tensorboard \
        --host 127.0.0.1 \
        --port 6006 \
        --logdir "${TENSORBOARD_LOGDIR}" \
        --path_prefix "${MARATHON_APP_LABEL_HAPROXY_0_PATH}/tensorboard" \
        >> "${MESOS_SANDBOX}/tensorboard.log" 2>&1 &
fi
