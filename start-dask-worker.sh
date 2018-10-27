#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

START_DASK_WORKER="True" exec /usr/local/bin/start-worker.sh
