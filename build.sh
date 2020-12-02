#!/bin/bash
meson setup --wipe builddir
# meson setup builddir
cd builddir
meson compile
gst-inspect-1.0 builddir/libgsttcp.so
