#!/bin/bash

set -e
apt-get update 
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC
apt-get install --no-install-recommends --no-install-suggests -y \
                ca-certificates \
                gnupg \
                software-properties-common \
                wget

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
apt-add-repository -y "deb http://apt.llvm.org/hirsute/ llvm-toolchain-hirsute main"

apt-get update
apt-get install --no-install-recommends --no-install-suggests -y \
                clang-15 libc++-15-dev libc++abi-15-dev

cat << EOF > $HOME/.bazelrc
build --action_env CC=/usr/bin/clang-15
build --action_env CXX=/usr/bin/clang++-15
EOF
