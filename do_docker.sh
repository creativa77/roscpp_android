#!/bin/sh

# TODO: Verify docker is available in this platform

# Build docker image
sudo docker build -t rosndk .
# TODO: Verify successful docker image build

sudo docker run -t -v /home/julian/osrf/roscpp_android:/opt/roscpp_android -v /home/julian/osrf/roscpp_android/output:/opt/roscpp_output -i rosndk /opt/roscpp_android/do_everything.sh /opt/roscpp_output
