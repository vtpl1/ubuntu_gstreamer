#!/bin/bash
# GST_DEBUG="vtpltcpclientsrc:6" gst-launch-1.0 --gst-plugin-path=$PWD/builddir -v vtpltcpclientsrc host=127.0.0.1 port=7001 ! decodebin ! autovideosink
sh ./build.sh
GST_DEBUG=2,vtplvmssrc:6 gst-launch-1.0 --gst-plugin-path=$PWD/builddir vtplvmssrc host=127.0.0.1 port=7001 ! decodebin ! autovideosink