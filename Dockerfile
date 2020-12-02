FROM ubuntu:18.04 AS base
WORKDIR /home
# COMMON BUILD TOOLS
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -q --no-install-recommends \
        cmake \
        build-essential \
        automake \
        autoconf \
        libtool \
        make \
        git \
        wget \
        pciutils \
        cpio \
        libtool \
        lsb-release \
        ca-certificates \
        pkg-config \
        bison \
        flex \
        libcurl4-gnutls-dev \
        zlib1g-dev \
        nasm \
        yasm \
        libx11-dev \
        xorg-dev \
        libgl1-mesa-dev \
        openbox \
        python3 \
        python3-pip \
        python3-setuptools && \
    rm -rf /var/lib/apt/lists/*

# Build x264
ARG X264_VER=stable
ARG X264_REPO=https://github.com/mirror/x264
RUN  git clone ${X264_REPO} && \
     cd x264 && \
     git checkout ${X264_VER} && \
     ./configure --prefix="/usr" --libdir=/usr/lib/x86_64-linux-gnu --enable-shared && \
     make -j $(nproc) && \
     make install DESTDIR="/home/build" && \
     make install

# Build Intel(R) Media SDK
ARG MSDK_REPO=https://github.com/Intel-Media-SDK/MediaSDK/releases/download/intel-mediasdk-19.3.1/MediaStack.tar.gz
RUN wget -O - ${MSDK_REPO} | tar xz && \
    cd MediaStack && \
    \
    cp -r opt/ /home/build && \
    cp -r etc/ /home/build && \
    \
    cp -a opt/. /opt/ && \
    cp -a etc/. /opt/ && \
    ldconfig

ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:/opt/intel/mediasdk/lib64/pkgconfig
ENV LIBRARY_PATH=/opt/intel/mediasdk/lib64:/usr/lib:${LIBRARY_PATH}
ENV LIBVA_DRIVERS_PATH=/opt/intel/mediasdk/lib64
ENV LIBVA_DRIVER_NAME=iHD
ENV GST_VAAPI_ALL_DRIVERS=1

# clinfo needs to be installed after build directory is copied over
RUN mkdir neo && cd neo && \
    wget https://github.com/intel/compute-runtime/releases/download/20.47.18513/intel-gmmlib_20.3.2_amd64.deb && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.5585/intel-igc-core_1.0.5585_amd64.deb && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.5585/intel-igc-opencl_1.0.5585_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/20.47.18513/intel-opencl_20.47.18513_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/20.47.18513/intel-ocloc_20.47.18513_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/20.47.18513/intel-level-zero-gpu_1.0.18513_amd64.deb && \
    dpkg -i *.deb && \
    dpkg-deb -x intel-gmmlib_20.3.2_amd64.deb /home/build/ && \
    dpkg-deb -x intel-igc-core_1.0.5585_amd64.deb /home/build/ && \
    dpkg-deb -x intel-igc-opencl_1.0.5585_amd64.deb /home/build/ && \
    dpkg-deb -x intel-opencl_20.47.18513_amd64.deb /home/build/ && \
    dpkg-deb -x intel-ocloc_20.47.18513_amd64.deb /home/build/ && \
    dpkg-deb -x intel-level-zero-gpu_1.0.18513_amd64.deb /home/build/ && \
    cp -a /home/build/. /

FROM base AS gst-internal
WORKDIR /home

# GStreamer core
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install --no-install-recommends -q -y \
        libglib2.0-dev \
        libgmp-dev \
        libgsl-dev \
        gobject-introspection \
        libcap-dev \
        libcap2-bin \
        gettext \
        libgirepository1.0-dev && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install --no-cache-dir -U pip && \
    pip3 install --no-cache-dir meson ninja

ARG PACKAGE_ORIGIN="https://gstreamer.freedesktop.org"

ARG PREFIX=/usr
ARG LIBDIR=/usr/lib/x86_64-linux-gnu
ARG LIBEXECDIR=/usr/lib/x86_64-linux-gnu

ARG GST_VERSION=1.16.2
ARG BUILD_TYPE=release

ENV GSTREAMER_LIB_DIR=${LIBDIR}
ENV LIBRARY_PATH=${GSTREAMER_LIB_DIR}:${GSTREAMER_LIB_DIR}/gstreamer-1.0:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${LIBRARY_PATH}
ENV PKG_CONFIG_PATH=${GSTREAMER_LIB_DIR}/pkgconfig

RUN mkdir -p build/src

ARG GST_REPO=https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-${GST_VERSION}.tar.xz
RUN wget ${GST_REPO} -O build/src/gstreamer-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gstreamer-${GST_VERSION}.tar.xz && \
    cd gstreamer-${GST_VERSION} && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dbenchmarks=disabled \
        -Dgtk_doc=disabled \
        -Dpackage-origin="${PACKAGE_ORIGIN}" \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/

# ORC Acceleration
ARG GST_ORC_VERSION=0.4.31
ARG GST_ORC_REPO=https://gstreamer.freedesktop.org/src/orc/orc-${GST_ORC_VERSION}.tar.xz
RUN wget ${GST_ORC_REPO} -O build/src/orc-${GST_ORC_VERSION}.tar.xz
RUN tar xvf build/src/orc-${GST_ORC_VERSION}.tar.xz && \
    cd orc-${GST_ORC_VERSION} && \
    meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dbenchmarks=disabled \
        -Dgtk_doc=disabled \
        -Dorc-test=disabled \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/


# GStreamer Base plugins
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -q --no-install-recommends \
        libx11-dev \
        iso-codes \
        libegl1-mesa-dev \
        libgles2-mesa-dev \
        libgl-dev \
        gudev-1.0 \
        libtheora-dev \
        libcdparanoia-dev \
        libpango1.0-dev \
        libgbm-dev \
        libasound2-dev \
        libjpeg-dev \
        libvisual-0.4-dev \
        libxv-dev \
        libopus-dev \
        libgraphene-1.0-dev \
        libvorbis-dev && \
    rm -rf /var/lib/apt/lists/*


# Build the gstreamer plugin base
ARG GST_PLUGIN_BASE_REPO=https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-${GST_VERSION}.tar.xz
RUN wget ${GST_PLUGIN_BASE_REPO} -O build/src/gst-plugins-base-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gst-plugins-base-${GST_VERSION}.tar.xz && \
    cd gst-plugins-base-${GST_VERSION} && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig:${PKG_CONFIG_PATH} meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dgtk_doc=disabled \
        -Dnls=disabled \
        -Dgl=disabled \
        -Dpackage-origin="${PACKAGE_ORIGIN}" \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/


# GStreamer Good plugins
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -q --no-install-recommends \
        libbz2-dev \
        libv4l-dev \
        libaa1-dev \
        libflac-dev \
        libgdk-pixbuf2.0-dev \
        libmp3lame-dev \
        libcaca-dev \
        libdv4-dev \
        libmpg123-dev \
        libraw1394-dev \
        libavc1394-dev \
        libiec61883-dev \
        libpulse-dev \
        libsoup2.4-dev \
        libspeex-dev \
        libtag-extras-dev \
        libtwolame-dev \
        libwavpack-dev && \
    rm -rf /var/lib/apt/lists/*

ARG GST_PLUGIN_GOOD_REPO=https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-${GST_VERSION}.tar.xz

# Lines below extract patch needed for Smart City Sample (OVS use case). Patch is applied before building gst-plugins-good
RUN  mkdir gst-plugins-good-${GST_VERSION} && \
    git clone https://github.com/GStreamer/gst-plugins-good.git && \
    cd gst-plugins-good && \
    git diff 080eba64de68161026f2b451033d6b455cb92a05 37d22186ffb29a830e8aad2e4d6456484e716fe7 > ../gst-plugins-good-${GST_VERSION}/rtpjitterbuffer-fix.patch

RUN wget ${GST_PLUGIN_GOOD_REPO} -O build/src/gst-plugins-good-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gst-plugins-good-${GST_VERSION}.tar.xz && \
    cd gst-plugins-good-${GST_VERSION}  && \
    patch -p1 < rtpjitterbuffer-fix.patch && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig:${PKG_CONFIG_PATH} meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dgtk_doc=disabled \
        -Dnls=disabled \
        -Dpackage-origin="${PACKAGE_ORIGIN}" \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/


# GStreamer Bad plugins
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -q --no-install-recommends \
        libbluetooth-dev \
        libusb-1.0.0-dev \
        libass-dev \
        libbs2b-dev \
        libchromaprint-dev \
        liblcms2-dev \
        libssh2-1-dev \
        libdc1394-22-dev \
        libdirectfb-dev \
        libssh-dev \
        libdca-dev \
        libfaac-dev \
        libfdk-aac-dev \
        flite1-dev \
        libfluidsynth-dev \
        libgme-dev \
        libgsm1-dev \
        nettle-dev \
        libkate-dev \
        liblrdf0-dev \
        libde265-dev \
        libmjpegtools-dev \
        libmms-dev \
        libmodplug-dev \
        libmpcdec-dev \
        libneon27-dev \
        libopenal-dev \
        libopenexr-dev \
        libopenjp2-7-dev \
        libopenmpt-dev \
        libopenni2-dev \
        libdvdnav-dev \
        librtmp-dev \
        librsvg2-dev \
        libsbc-dev \
        libsndfile1-dev \
        libsoundtouch-dev \
        libspandsp-dev \
        libsrtp2-dev \
        libzvbi-dev \
        libvo-aacenc-dev \
        libvo-amrwbenc-dev \
        libwebrtc-audio-processing-dev \
        libwebp-dev \
        libwildmidi-dev \
        libzbar-dev \
        libnice-dev \
        libxkbcommon-dev && \
    rm -rf /var/lib/apt/lists/*

# Uninstalled dependencies: opencv, opencv4, libmfx(waiting intelMSDK), wayland(low version), vdpau

ARG GST_PLUGIN_BAD_REPO=https://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-${GST_VERSION}.tar.xz
RUN wget ${GST_PLUGIN_BAD_REPO} -O build/src/gst-plugins-bad-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gst-plugins-bad-${GST_VERSION}.tar.xz && \
    cd gst-plugins-bad-${GST_VERSION} && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig:${PKG_CONFIG_PATH} meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Ddoc=disabled \
        -Dnls=disabled \
        -Dx265=disabled \
        -Dyadif=disabled \
        -Dresindvd=disabled \
        -Dmplex=disabled \
        -Ddts=disabled \
        -Dofa=disabled \
        -Dfaad=disabled \
        -Dmpeg2enc=disabled \
        -Dpackage-origin="${PACKAGE_ORIGIN}" \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/

# Build the gstreamer plugin ugly set
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -q --no-install-recommends \
        libmpeg2-4-dev \
        libopencore-amrnb-dev \
        libopencore-amrwb-dev \
        liba52-0.7.4-dev \
    && rm -rf /var/lib/apt/lists/*

ARG GST_PLUGIN_UGLY_REPO=https://gstreamer.freedesktop.org/src/gst-plugins-ugly/gst-plugins-ugly-${GST_VERSION}.tar.xz

RUN wget ${GST_PLUGIN_UGLY_REPO} -O build/src/gst-plugins-ugly-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gst-plugins-ugly-${GST_VERSION}.tar.xz && \
    cd gst-plugins-ugly-${GST_VERSION}  && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig:${PKG_CONFIG_PATH} meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dgtk_doc=disabled \
        -Dnls=disabled \
        -Dcdio=disabled \
        -Dsid=disabled \
        -Dmpeg2dec=disabled \
        -Ddvdread=disabled \
        -Da52dec=disabled \
        -Dx264=enabled \
        -Dpackage-origin="${PACKAGE_ORIGIN}" \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/


# FFmpeg
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -q --no-install-recommends \
        bzip2 \
        autoconf

RUN mkdir ffmpeg_sources && cd ffmpeg_sources && \
    wget -O - https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 | tar xj && \
    cd nasm-2.14.02 && \
    ./autogen.sh && \
    ./configure --prefix=${PREFIX} --bindir="${PREFIX}/bin" && \
    make && make install

RUN wget https://ffmpeg.org/releases/ffmpeg-4.2.2.tar.gz -O build/src/ffmpeg-4.2.2.tar.gz
RUN cd ffmpeg_sources && \
    tar xvf /home/build/src/ffmpeg-4.2.2.tar.gz && \
    cd ffmpeg-4.2.2 && \
    PATH="${PREFIX}/bin:$PATH" PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    ./configure \
        --disable-gpl \
        --enable-pic \
        --disable-shared \
        --enable-static \
        --prefix=${PREFIX} \
        --extra-cflags="-I${PREFIX}/include" \
        --extra-ldflags="-L${PREFIX}/lib" \
        --extra-libs=-lpthread \
        --extra-libs=-lm \
        --bindir="${PREFIX}/bin" \
        --disable-vaapi && \
    make -j $(nproc) && \
    make install

# Build gst-libav
ARG GST_PLUGIN_LIBAV_REPO=https://gstreamer.freedesktop.org/src/gst-libav/gst-libav-${GST_VERSION}.tar.xz
RUN wget ${GST_PLUGIN_LIBAV_REPO} -O build/src/gst-libav-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gst-libav-${GST_VERSION}.tar.xz && \
    cd gst-libav-${GST_VERSION} && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig:${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH} meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dgtk_doc=disabled \
        -Dnls=disabled \
        -Dpackage-origin="${PACKAGE_ORIGIN}" \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/

ENV PKG_CONFIG_PATH=/opt/intel/mediasdk/lib64/pkgconfig:${PKG_CONFIG_PATH}
ENV LIBRARY_PATH=/opt/intel/mediasdk/lib64:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH=/opt/intel/mediasdk/lib64:${LD_LIBRARY_PATH}
ENV LIBVA_DRIVERS_PATH=/opt/intel/mediasdk/lib64
ENV LIBVA_DRIVER_NAME=iHD

# Build gstreamer plugin vaapi
ARG GST_PLUGIN_VAAPI_REPO=https://gstreamer.freedesktop.org/src/gstreamer-vaapi/gstreamer-vaapi-${GST_VERSION}.tar.xz

ENV GST_VAAPI_ALL_DRIVERS=1

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -q --no-install-recommends \
        libva-dev \
        libxrandr-dev \
        libudev-dev && \
    rm -rf /var/lib/apt/lists/*

ARG GSTREAMER_VAAPI_PATCH_URL=https://raw.githubusercontent.com/opencv/gst-video-analytics/master/patches/gstreamer-vaapi/vasurface_qdata.patch
RUN wget ${GST_PLUGIN_VAAPI_REPO} -O build/src/gstreamer-vaapi-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gstreamer-vaapi-${GST_VERSION}.tar.xz && \
    cd gstreamer-vaapi-${GST_VERSION} && \
    wget -O - ${GSTREAMER_VAAPI_PATCH_URL} | git apply && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig:${PKG_CONFIG_PATH} meson \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dgtk_doc=disabled \
        -Dnls=disabled \
        -Dpackage-origin="${PACKAGE_ORIGIN}" \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/

# gst-python
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install --no-install-recommends -y \
        python-gi-dev \
        python3-dev && \
    rm -rf /var/lib/apt/lists/*

ARG GST_PYTHON_REPO=https://gstreamer.freedesktop.org/src/gst-python/gst-python-${GST_VERSION}.tar.xz
RUN wget ${GST_PYTHON_REPO} -O build/src/gst-python-${GST_VERSION}.tar.xz
RUN tar xvf build/src/gst-python-${GST_VERSION}.tar.xz && \
    cd gst-python-${GST_VERSION} && \
    PKG_CONFIG_PATH=$PWD/build/pkgconfig:${PKG_CONFIG_PATH} meson \
        -Dpython=python3 \
        --buildtype=${BUILD_TYPE} \
        --prefix=${PREFIX} \
        --libdir=${LIBDIR} \
        --libexecdir=${LIBEXECDIR} \
    build/ && \
    ninja -C build && \
    DESTDIR=/home/build meson install -C build/ && \
    meson install -C build/

ENV GI_TYPELIB_PATH=${LIBDIR}/girepository-1.0

ENV PYTHONPATH=${PREFIX}/lib/python3.6/site-packages:${PYTHONPATH}

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

RUN groupmod --gid $USER_GID $USERNAME \
    && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
    && chown -R $USER_UID:$USER_GID /home/$USERNAME