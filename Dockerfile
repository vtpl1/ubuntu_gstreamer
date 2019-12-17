FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -qq -y build-essential tar nano wget subversion git pkg-config curl openssl ninja-build unzip
RUN wget https://cmake.org/files/v3.15/cmake-3.15.6.tar.gz
RUN tar xzf cmake-3.15.6.tar.gz
RUN cd cmake-3.15.6 && ./bootstrap && make -j8 && make install
RUN rm -rf cmake-3.15.6
RUN rm -f cmake-3.15.6.tar.gz
RUN apt install -y libgtk2.0-dev ffmpeg libavcodec-dev libavformat-dev libswscale-dev libavresample-dev 
RUN apt install -y python-dev python-numpy python3-dev python3-numpy libtbb2 libtbb-dev
RUN apt install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio
RUN apt install -y gtk-doc-tools python3-pip libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
WORKDIR /WorkFiles
RUN git clone https://github.com/GStreamer/gst-plugins-bad.git
RUN git checkout 1.14.5
