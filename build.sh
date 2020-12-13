#!/bin/bash
meson setup --wipe builddir
#meson setup builddir
cd builddir
meson compile
rm /home/vscode/.cache/gstreamer-1.0/registry.x86_64.bin
ldd libvtpl.so
gst-inspect-1.0 libvtpl.so --gst-plugin-path=$PWD
gst-launch-1.0 --gst-plugin-path=$PWD --gst-debug-help | grep vtpl

