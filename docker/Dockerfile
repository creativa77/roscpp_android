FROM ubuntu:14.04
MAINTAINER Julian Cerruti <jcerruti@creativa77.com.ar>
MAINTAINER Gary Servin <gary@creativa77.com.ar>

# Install ROS Indigo
RUN apt-get update && apt-get install -y wget git unzip
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu trusty main" > /etc/apt/sources.list.d/ros-latest.list'
RUN wget https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | sudo apt-key add -
RUN apt-get update && apt-get install --no-install-recommends -y ros-indigo-ros-base python-wstool

# Install Android NDK
RUN wget http://dl.google.com/android/ndk/android-ndk-r8e-linux-x86_64.tar.bz2
RUN tar -jxvf android-ndk-r8e-linux-x86_64.tar.bz2 -C /opt

# Set-up environment
ENV ANDROID_NDK /opt/android-ndk-r8e

# Install g++ to avoid "CMAKE_CXX_COMPILER-NOTFOUND was not found." error
RUN apt-get update && apt-get install -y g++ cmake make

# Install Android SDK
RUN apt-get update && apt-get install -y openjdk-6-jdk lib32z1 lib32ncurses5 lib32bz2-1.0 lib32stdc++6 ant
RUN wget http://dl.google.com/android/android-sdk_r23.0.2-linux.tgz
RUN tar -xvf android-sdk_r23.0.2-linux.tgz -C /opt
ENV PATH /opt/android-sdk-linux/tools:/opt/android-sdk-linux/platform-tools:$PATH
ENV ANDROID_HOME /opt/android-sdk-linux
RUN (while true; do echo 'y'; sleep 2; done) | android update sdk -u -t 2,3,7,8,9,11,13,16,56,57 --proxy-host mirrors.neusoft.edu.cn --proxy-port 80

# Install Python libraries
RUN apt-get install python-lxml -y

ENV JAVA_HOME /usr/lib/jvm/java-6-openjdk-amd64/

# Use ccache
RUN apt-get update && apt-get install -y ccache
ENV USE_CCACHE 1
ENV NDK_CCACHE /usr/bin/ccache
ENV CCACHE_DIR /opt/roscpp_output/ccache
ENV PATH /usr/lib/ccache:$PATH
