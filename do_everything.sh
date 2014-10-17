#!/bin/bash

# TODO: Check that environment actually exists
source /opt/ros/indigo/setup.bash

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/config.sh
source $my_loc/utils.sh
debugging=0
skip=0
help=0

if [[ $# -lt 1 ]] ; then
    help=1
fi

for var in "$@"
do
    if [[ ${var} == "--help" ]] ||  [[ ${var} == "-h" ]] ; then
        help=1
    fi
    if [[ ${var} == "--skip" ]] ; then
        skip=1
    fi

    if [[ ${var} == "--debug-symbols" ]] ; then
        debugging=1
    fi
done

if [[ $help -eq 1 ]] ; then
    echo "Usage: $0 prefix_path [-h | --help] [--skip] [--debug-symbols]"
    echo "  example: $0 /home/user/my_workspace"
    exit 1
fi

if [[ $skip -eq 1 ]]; then
   echo "-- Skiping projects update"
else
   echo "-- Will update projects"
fi

if [[ $debugging -eq 1 ]]; then
   echo "-- Building workspace WITH debugging symbols"
else
   echo "-- Building workspace without debugging symbols"
fi

if [ ! -d $1 ]; then
    mkdir -p $1
fi

prefix=$(cd $1 && pwd)

run_cmd() {
    cmd=$1.sh
    shift
    $my_loc/$cmd $@ || die "$cmd $@ died with error code $?"
}

if [ -z $ANDROID_NDK ] ; then
    die "ANDROID_NDK ENVIRONMENT NOT FOUND!"
fi

if [ -z $ROS_DISTRO ] ; then
    die "HOST ROS ENVIRONMENT NOT FOUND! Did you source /opt/ros/indigo/setup.bash"
fi

[ -d $standalone_toolchain_path ] || run_cmd setup_standalone_toolchain

mkdir -p $prefix/libs

# Start with catkin since we use it to build almost everything else
[ -d $prefix/target ] || mkdir -p $prefix/target
export CMAKE_PREFIX_PATH=$prefix/target

[ -e $prefix/android.toolchain.cmake ] || ( cd $prefix && download 'https://raw.github.com/taka-no-me/android-cmake/master/android.toolchain.cmake' && cat $my_loc/files/android.toolchain.cmake.addendum >> $prefix/android.toolchain.cmake)
export RBA_TOOLCHAIN=$prefix/android.toolchain.cmake

# Now get boost with a specialized build
[ -d $prefix/libs/boost ] || run_cmd get_boost $prefix/libs
[ -d $prefix/libs/poco-1.4.6p2 ] || run_cmd get_poco $prefix/libs
[ -d $prefix/libs/tinyxml ] || run_cmd get_tinyxml $prefix/libs
[ -d $prefix/libs/eigen ] || run_cmd get_eigen $prefix/libs
[ -d $prefix/libs/catkin ] || run_cmd get_catkin $prefix/libs
[ -d $prefix/libs/console_bridge ] || run_cmd get_console_bridge $prefix/libs
[ -d $prefix/libs/yaml-cpp ] || run_cmd get_yaml_cpp $prefix/libs


run_cmd build_catkin $prefix/libs/catkin
. $prefix/target/setup.bash


# Remove catkin package information from target since we will be cross-compiling it,
# otherwise catkin will detect it as duplicate
rm -rf $prefix/target/share/*

if [[ $skip -ne 1 ]] ; then
    run_cmd get_ros_stuff $prefix/libs

    # Patch image_transport
    patch -p0 -N -d $prefix < patches/image_transport.patch
    # Patch camera_calibration_parsers
    patch -p0 -N -d $prefix < patches/camera_calibration_parsers.patch
    # Patch camera_info_manager
    patch -p0 -N -d $prefix < patches/camera_info_manager.patch
    # Patch class_loader
    patch -p0 -N -d $prefix < patches/class_loader.patch
    # Patch ros_comm (Accepted on upstream, need to update rosinstall when new release comes out)
    patch -p0 -N -d $prefix < patches/ros_comm.patch
    # Patch roslib (Accepted on upstream, need to update rosinstall when new release comes out)
    patch -p0 -N -d $prefix < patches/roslib.patch
    # Patch dynamic_reconfigure
    patch -p0 -N -d $prefix < patches/dynamic_reconfigure.patch
fi


run_cmd build_tinyxml $prefix/libs/tinyxml
run_cmd copy_boost $prefix/libs/boost
run_cmd build_poco $prefix/libs/poco-1.4.6p2
run_cmd build_console_bridge $prefix/libs/console_bridge
run_cmd build_eigen $prefix/libs/eigen
run_cmd build_yaml_cpp $prefix/libs/yaml-cpp


if [[ $debugging -eq 1 ]];then
    run_cmd build_cpp --debug-symbols
else
    run_cmd build_cpp
fi

run_cmd setup_ndk_project $prefix/roscpp_android_ndk
# JAC: Disabled temporarily and replaced by application-specific Android.mk since
# the library order resulting from create_android_mk doesn't work

cp $my_loc/files/Android.mk.algron $prefix/roscpp_android_ndk/Android.mk

if [[ $debugging -eq 1 ]];then
    sed -i "s/#LOCAL_EXPORT_CFLAGS/LOCAL_EXPORT_CFLAGS/g" $prefix/roscpp_android_ndk/Android.mk
fi

# run_cmd create_android_mk $prefix/target/catkin_ws/src $prefix/roscpp_android_ndk

#( cd $prefix && run_cmd sample_app sample_app $prefix/roscpp_android_ndk )

echo
echo 'done.'
echo 'summary of what just happened:'
echo '  target/      was used to build static libraries for ros software'
echo '    include/   contains headers'
echo '    lib/       contains static libraries'
echo '  roscpp_android_ndk/     is a NDK sub-project that can be imported into an NDK app'
echo
echo 'you might now cd into sample_app/, run "ant debug install", and if an'
echo 'android emulator is running, the app will be flashed onto it.'
