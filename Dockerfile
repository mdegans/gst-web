FROM ubuntu:latest as build

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -y && apt-get install -y --no-install-recommends \
        build-essential \ 
        gobject-introspection \
        gstreamer1.0-tools \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        meson \
        nginx \
        valac \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

COPY meson.build VERSION ./
COPY gst-web ./gst-web/

RUN mkdir build && cd build \
    && meson .. --prefix=/usr \
    && ninja install

# check gstweb plugin installed
RUN gst-inspect-1.0 gstweb
# check webserverbin installed
RUN gst-inspect-1.0 webserverbin

FROM ubuntu:latest

# TODO(mdegans): use build script to read from VERSION and fill this out
ARG SHORT_VERSION="0.1"
