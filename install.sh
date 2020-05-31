#!/bin/bash
# 2020 Michael de Gans

readonly DEBIAN_FRONTEND="noninteractive"

set -ex

function install_deps () {
  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    ffmpeg \
    git \
    gosu \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-tools \
    libgstreamer1.0-0 \
    libgstrtspserver-1.0-0 \
    libgstrtspserver-1.0-dev \
    libjansson4=2.11-1 \
    librdkafka1=0.11.3-1build1 \
    libssl-dev \
    ninja-build \
    m4 \
    python3 \
    python3-boto3 \
    python3-dev \
    python3-pip \
    python3-psutil \
    python3-pyinotify \
    python3-setuptools \
    python3-testresources \
    python3-wheel \
  && rm -rf /var/lib/apt/lists/*
}

function install_thing() {
  git clone --depth 1 --recursive https://github.com/awslabs/amazon-kinesis-video-streams-producer-sdk-cpp.git \
  cd amazon-kinesis-video-streams-producer-sdk-cpp \
  git fetch origin pull/429/head:build \
  git checkout build \
  mkdir build \
  cd build \
  cmake .. -GNinja -DBUILD_GSTREAMER_PLUGIN=ON -DCMAKE_INSTALL_PREFIX=/usr/ \
  ninja install \
  ldconfig
}

function purge_deps () {
  sudo apt-get purge -y --autoremove \
    ninja-build
    # more here if you want
    # use f1 and "sort lines"
    # in vscode to sort the lines
}
