#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

local_scheduler=$(pgrep local_scheduler)
if [[ "${local_scheduler}" == "" ]]; then
    echo "ray local_scheduler exit"
    exit 1
fi
