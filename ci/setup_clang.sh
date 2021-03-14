#!/bin/bash

set -e

cat << EOF > $HOME/.bazelrc
build --action_env CC=/usr/local/bin/clang
build --action_env CXX=/usr/local/bin/clang++
EOF
