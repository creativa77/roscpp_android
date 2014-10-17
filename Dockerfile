FROM ubuntu:14.04
MAINTAINER Julian Cerruti <jcerruti@creativa77.com.ar>

# Install ROS Indigo
RUN apt-get update && apt-get install -y wget git
RUN sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu trusty main" > /etc/apt/sources.list.d/ros-latest.list'
RUN wget https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | sudo apt-key add -
RUN sudo apt-get update
RUN sudo apt-get install -y ros-indigo-ros-base python-wstool

# Install Android NDK
RUN wget http://dl.google.com/android/ndk/android-ndk-r8e-linux-x86_64.tar.bz2
RUN tar -jxvf android-ndk-r8e-linux-x86_64.tar.bz2 -C /opt

# Set-up environment
ENV ANDROID_NDK /opt/android-ndk-r8e
