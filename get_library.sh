#!/bin/bash

# Abort script on any failures
set -e

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/config.sh
source $my_loc/utils.sh

if [ $# != 2 ] || [ $1 == '-h' ] || [ $1 == '--help' ]; then
    echo "Usage: $0 library_name library_prefix_path"
    echo "  example: $0 tinyxml /home/user/my_workspace/tinyxml"
    exit 1
fi

echo
echo -e '\e[34mGetting '$1'.\e[39m'
echo

prefix=$(cd $2 && pwd)

if [ $1 == 'assimp' ]; then
    URL=https://github.com/assimp/assimp/archive/v3.1.1.tar.gz
    COMP='gz'
elif [ $1 == 'bfl' ]; then
    URL=https://github.com/ros-gbp/bfl-release/archive/release/indigo/bfl/0.7.0-6.tar.gz
    COMP='gz'
elif [ $1 == 'boost' ]; then
    URL=https://github.com/ekumenlabs/Boost-for-Android.git
    COMP='git'
elif [ $1 == 'bzip2' ]; then
    URL=https://github.com/osrf/bzip2_cmake.git
    COMP='git'
elif [ $1 == 'catkin' ]; then
    URL='-b 0.6.5 https://github.com/ros/catkin.git'
    COMP='git'
elif [ $1 == 'collada_dom' ]; then
    URL=http://ufpr.dl.sourceforge.net/project/collada-dom/Collada%20DOM/Collada%20DOM%202.4/collada-dom-2.4.0.tgz
    COMP='gz'
elif [ $1 == 'console_bridge' ]; then
    URL=https://github.com/ros/console_bridge.git
    COMP='git'
    HASH='964a9a70e0fc607476e439b8947a36b07322c304'
elif [ $1 == 'curl' ]; then
    URL=http://curl.haxx.se/download/curl-7.39.0.tar.bz2
    COMP='bz2'
elif [ $1 == 'eigen' ]; then
    URL=https://github.com/tulku/eigen.git
    COMP='git'
elif [ $1 == 'fcl' ]; then
    URL=https://github.com/ros-gbp/fcl-release/archive/release/indigo/fcl/0.3.2-0.tar.gz
    COMP='gz'
elif [ $1 == 'flann' ]; then
    URL=https://github.com/chadrockey/flann_cmake.git
    COMP='git'
elif [ $1 == 'libccd' ]; then
    URL=https://github.com/danfis/libccd/archive/v2.0.tar.gz
    COMP='gz'
elif [ $1 == 'libiconv' ]; then
    URL=http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
    COMP='gz'
elif [ $1 == 'log4cxx' ]; then
    URL=https://archive.apache.org/dist/logging/log4cxx/0.10.0/apache-log4cxx-0.10.0.tar.gz
    COMP='gz'
elif [ $1 == 'libxml2' ]; then
    URL=ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
    COMP='gz'
elif [ $1 == 'lz4' ]; then
    URL=https://github.com/Cyan4973/lz4/archive/r124.tar.gz
    COMP='gz'
elif [ $1 == 'octomap' ]; then
    URL=https://github.com/OctoMap/octomap/archive/v1.6.8.tar.gz
    COMP='gz'
elif [ $1 == 'opencv' ]; then
    URL=https://github.com/Itseez/opencv/archive/2.4.9.tar.gz
    COMP='gz'
elif [ $1 == 'orocos_kdl' ]; then
    URL=https://github.com/smits/orocos-kdl-release/archive/release/indigo/orocos_kdl/1.3.0-0.tar.gz
    COMP='gz'
elif [ $1 == 'pcl' ]; then
    URL=https://github.com/chadrockey/pcl.git
    COMP='git'
elif [ $1 == 'pcrecpp' ]; then
    URL=https://github.com/brianb/pcre-7.8.git
    COMP='git'
elif [ $1 == 'poco' ]; then
    URL=http://pocoproject.org/releases/poco-1.6.1/poco-1.6.1.tar.gz
    COMP='gz'
elif [ $1 == 'qhull' ]; then
    URL=http://www.qhull.org/download/qhull-2012.1-src.tgz
    COMP='gz'
elif [ $1 == 'tinyxml' ]; then
    URL=https://github.com/chadrockey/tinyxml_cmake
    COMP='git'
elif [ $1 == 'urdfdom_headers' ]; then
    URL=https://github.com/ros/urdfdom_headers.git
    COMP='git'
    HASH='9aed7256e06d62935966de2a9bc9ddfac96e7a85'
elif [ $1 == 'urdfdom' ]; then
    URL=https://github.com/ros/urdfdom.git
    COMP='git'
    HASH='c4ac03caf55369c64c61605b78f1b6071bb4acce'
elif [ $1 == 'uuid' ]; then
    URL=https://github.com/chadrockey/uuid_cmake
    COMP='git'
elif [ $1 == 'yaml-cpp' ]; then
    URL=https://github.com/ekumenlabs/yaml-cpp.git
    COMP='git'
elif [ $1 == 'rospkg' ]; then
    URL=https://github.com/ros-infrastructure/rospkg.git
    COMP='git'
    HASH='93b1b72f256badf22ccc926b22646f2e83b720fd'
fi

if [ $COMP == 'gz' ]; then
    download_gz $URL $prefix
elif [ $COMP == 'bz2' ]; then
    download_bz2 $URL $prefix
elif [ $COMP == 'git' ];then
    git clone $URL $prefix/$1
fi

if [ $1 == 'boost' ]; then
    cd $prefix/boost
    ./build-android.sh $ANDROID_NDK --boost=1.53.0
elif [ -v HASH ]; then
    cd $prefix/$1
    git checkout $HASH
elif [ $1 == 'bfl' ]; then
    mv $prefix/bfl-release-release-indigo-bfl-0.7.0-6 $prefix/bfl-0.7.0
elif [ $1 == 'orocos_kdl' ]; then
    mv $prefix/orocos-kdl-release-release-indigo-orocos_kdl-1.3.0-0 $prefix/orocos_kdl-1.3.0
elif [ $1 == 'fcl' ]; then
    mv $prefix/fcl-release-release-indigo-fcl-0.3.2-0 $prefix/fcl-0.3.2
fi
