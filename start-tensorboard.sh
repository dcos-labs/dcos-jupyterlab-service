#!/usr/bin/env bash

set -o errexit -o pipefail

TENSORBOARD_LOGDIR=${TENSORBOARD_LOGDIR:-"${MESOS_SANDBOX}"}

if [ ${PORT_TFDBG+x} ]; then
    TENSORBOARD_ARGS="${TENSORBOARD_ARGS} --debugger_port ${PORT_TFDBG}"
fi

tensorboard \
    --host localhost \
    --port 6006 \
    --logdir "${TENSORBOARD_LOGDIR}" \
    "${TENSORBOARD_ARGS}" >> "${MESOS_SANDBOX}/tensorboard.log" 2>&1 &
