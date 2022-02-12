#!/bin/bash

set -e
export DEBIAN_FRONTEND="noninteractive"
export TZ=Etc/UTC
apt-get update 
apt-get install --no-install-recommends --no-install-suggests -y \
                software-properties-common \
                build-essential \
                zip \
                git \
                ca-certificates \
                curl \
                gnupg2 \
                ssh \
                vim \
                wget \
                python
