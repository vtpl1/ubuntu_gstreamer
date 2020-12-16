#!/bin/bash
# GST_DEBUG="vtpltcpclientsrc:6" gst-launch-1.0 --gst-plugin-path=$PWD/builddir -v vtpltcpclientsrc host=127.0.0.1 port=7001 ! decodebin ! autovideosink
# sh ./build.sh
# GST_DEBUG=2,vtplvmssrc:6 gst-launch-1.0 --gst-plugin-path=$PWD/builddir tcpclientsrc host=127.0.0.1 port=7001 ! decodebin ! autovideosink
GST_DEBUG=2,vtplvmssrc:6 gst-launch-1.0 --gst-plugin-path=$PWD/builddir tcpclientsrc host=192.168.1.103 port=11000 ! decodebin ! fakesink