#!/bin/bash
gst-launch-1.0 -v tcpclientsrc host=127.0.0.1 port=7001 ! decodebin ! autovideosink