#!/usr/bin/env bash

set -o errexit -o pipefail

# Block until jupyter configuration is complete, as otherwise dependencies such as HDFS might not be downloaded yet.
while [ ! -f "${MESOS_SANDBOX}"/JUPYTER_NOTEBOOK_CONFIG_COMPLETE ]
do
  sleep 2
done

TENSORBOARD_LOGDIR=${TENSORBOARD_LOGDIR:-"${MESOS_SANDBOX}"}

if [ ${PORT_TFDBG+x} ]; then
    TENSORBOARD_ARGS="${TENSORBOARD_ARGS} --debugger_port ${PORT_TFDBG}"
fi

tensorboard \
    --host localhost \
    --port 6006 \
    --logdir "${TENSORBOARD_LOGDIR}" \
    "${TENSORBOARD_ARGS}" >> "${MESOS_SANDBOX}/tensorboard.log" 2>&1 &
