#!/usr/bin/env bash

source "$HOME/.bash_profile"
source activate beakerx
jupyter lab --allow-root "$@"
