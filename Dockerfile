FROM ubuntu:latest as build

ARG SHORT_VERSION="0.1"
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

COPY --from=build \
    /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstweb.so \
    /usr/include/gstweb.h \
    /usr/share/vala/vapi/gstweb-${SHORT_VERSION}.vapi \
    /usr/share/gir-1.0/gstweb-${SHORT_VERSION}.gir \
    /