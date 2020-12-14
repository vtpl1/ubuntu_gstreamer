#!/bin/bash
#gst-launch-1.0 -v videotestsrc is-live=true ! video/x-raw,width=640,width=480,framerate=30/1 ! queue ! videoconvert ! x264enc tune=zerolatency ! h264parse ! queue ! mpegtsmux ! queue leaky=2 ! tcpserversink port=7001 host=0.0.0.0 recover-policy=keyframe sync-method=latest-keyframe
gst-launch-1.0 -v filesrc location=/workspaces/ubuntu_gstreamer/videos/b.264 ! h264parse ! 'video/x-h264, stream-format=(string)byte-stream' ! decodebin ! autovideosink

