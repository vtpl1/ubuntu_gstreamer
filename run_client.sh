#!/bin/bash
# GST_DEBUG="vtpltcpclientsrc:6" gst-launch-1.0 --gst-plugin-path=$PWD/builddir -v vtpltcpclientsrc host=127.0.0.1 port=7001 ! decodebin ! autovideosink
sh ./build.sh
GST_DEBUG=2,tcpclientsrc:6 gst-launch-1.0 --gst-plugin-path=$PWD/builddir vtpltcpclientsrc host=127.0.0.1 port=7001 ! decodebin ! autovideosink