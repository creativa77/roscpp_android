#!/bin/bash

# Define the number of simultaneous jobs to trigger for the different
# tasks that allow it. Use the number of available processors in the
# system.
export PARALLEL_JOBS=$(nproc)

if [[ -f /opt/ros/indigo/setup.bash ]] ; then
    source /opt/ros/indigo/setup.bash
else
    echo "ROS environment not found, please install it"
    exit 1
fi

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/config.sh
source $my_loc/utils.sh
debugging=0
skip=0
portable=0
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

    if [[ ${var} == "--portable" ]] ; then
        portable=1
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

echo
echo -e '\e[34mGetting library dependencies.\e[39m'
echo

mkdir -p $prefix/libs

# Start with catkin since we use it to build almost everything else
[ -d $prefix/target ] || mkdir -p $prefix/target
export CMAKE_PREFIX_PATH=$prefix/target

[ -e $prefix/android.toolchain.cmake ] || ( cd $prefix && download 'https://raw.github.com/taka-no-me/android-cmake/master/android.toolchain.cmake' && cat $my_loc/files/android.toolchain.cmake.addendum >> $prefix/android.toolchain.cmake)
export RBA_TOOLCHAIN=$prefix/android.toolchain.cmake

# Now get boost with a specialized build
[ -d $prefix/libs/boost ] || run_cmd get_library boost $prefix/libs
[ -d $prefix/libs/bzip2 ] || run_cmd get_library bzip2 $prefix/libs
[ -d $prefix/libs/uuid ] || run_cmd get_library uuid $prefix/libs
[ -d $prefix/libs/poco-1.4.6p2 ] || run_cmd get_library poco $prefix/libs
[ -d $prefix/libs/tinyxml ] || run_cmd get_library tinyxml $prefix/libs
[ -d $prefix/libs/catkin ] || run_cmd get_library catkin $prefix/libs
[ -d $prefix/libs/console_bridge ] || run_cmd get_library console_bridge $prefix/libs
[ -d $prefix/libs/lz4-r124 ] || run_cmd get_library lz4 $prefix/libs
[ -d $prefix/libs/curl-7.39.0 ] || run_cmd get_library curl $prefix/libs
[ -d $prefix/libs/urdfdom/ ] || run_cmd get_library urdfdom $prefix/libs
[ -d $prefix/libs/urdfdom_headers ] || run_cmd get_library urdfdom_headers $prefix/libs
[ -d $prefix/libs/libiconv-1.14 ] || run_cmd get_library libiconv $prefix/libs
[ -d $prefix/libs/libxml2-2.9.1 ] || run_cmd get_library libxml2 $prefix/libs
[ -d $prefix/libs/collada-dom-2.4.0 ] || run_cmd get_library collada_dom $prefix/libs
[ -d $prefix/libs/eigen ] || run_cmd get_library eigen $prefix/libs
[ -d $prefix/libs/assimp-3.1.1 ] || run_cmd get_library assimp $prefix/libs
[ -d $prefix/libs/qhull-2012.1 ] || run_cmd get_library qhull $prefix/libs
[ -d $prefix/libs/octomap-1.6.8 ] || run_cmd get_library octomap $prefix/libs
[ -d $prefix/libs/yaml-cpp ] || run_cmd get_library yaml-cpp $prefix/libs
[ -d $prefix/libs/opencv-2.4.9 ] || run_cmd get_library opencv $prefix/libs
[ -d $prefix/libs/flann ] || run_cmd get_library flann $prefix/libs
[ -d $prefix/libs/pcl ] || run_cmd get_library pcl $prefix/libs
[ -d $prefix/libs/bfl-0.7.0 ] || run_cmd get_library bfl $prefix/libs
[ -d $prefix/libs/orocos_kdl-1.3.0 ] || run_cmd get_library orocos_kdl $prefix/libs
[ -d $prefix/libs/apache-log4cxx-0.10.0 ] || run_cmd get_library log4cxx $prefix/libs
[ -d $prefix/libs/libccd-2.0 ] || run_cmd get_library libccd $prefix/libs
[ -d $prefix/libs/fcl-0.3.2 ] || run_cmd get_library fcl $prefix/libs
[ -d $prefix/libs/pcrecpp ] || run_cmd get_library pcrecpp $prefix/libs

[ -f $prefix/target/bin/catkin_make ] || run_cmd build_library catkin $prefix/libs/catkin
. $prefix/target/setup.bash

echo
echo -e '\e[34mGetting ROS packages\e[39m'
echo

if [[ $skip -ne 1 ]] ; then
    run_cmd get_ros_stuff $prefix

    echo
    echo -e '\e[34mApplying patches.\e[39m'
    echo

    # patch CMakeLists.txt for lz4 library - Build as a library
    patch -p0 -N -d $prefix < $my_loc/patches/lz4.patch

    # Patch collada - Build as static lib
    patch -p0 -N -d $prefix < $my_loc/patches/collada_dom.patch

    #  Patch assimp - Build as static lib
    patch -p0 -N -d $prefix < $my_loc/patches/assimp.patch

    # Patch urdfdom - Build as static lib
    patch -p0 -N -d $prefix < $my_loc/patches/urdfdom.patch

    # Patch libiconv - Remove 'gets' error
    patch -p0 -N -d $prefix < $my_loc/patches/libiconv.patch

    # Patch opencv - Fix installation path
    patch -p0 -N -d $prefix < $my_loc/patches/opencv.patch

    # Patch qhull - Don't install shared libraries
    # TODO: Remove shared libraries to avoid hack in parse_libs.py
    #patch -p0 -N -d $prefix < $my_loc/patches/qhull.patch

    # Patch eigen - Rename param as some constant already has the same name
    # TODO: Fork and push changes to creativa's repo
    patch -p0 -N -d $prefix < $my_loc/patches/eigen.patch

    # Patch bfl - Build as static lib
    patch -p0 -N -d $prefix < $my_loc/patches/bfl.patch

    # Patch orocos_kdl - Build as static lib and change constant name
    patch -p0 -N -d $prefix < $my_loc/patches/orocos_kdl.patch

    # Patch log4cxx - Add missing headers
    patch -p0 -N -d $prefix < $my_loc/patches/log4cxx.patch

    # Patch fcl - Add ccd library cmake variables
    # TODO: The correct way to handle this would be to create .cmake files for ccd and do a findpackage(ccd)
    # Also, this can go inside the catkin_ws but the headers don't get installed on the catkin_make and are
    # needed by moveit_core during compilation
    patch -p0 -N -d $prefix < $my_loc/patches/fcl.patch

    # Patch pcrecpp - Add findpackage configs
    patch -p0 -N -d $prefix < $my_loc/patches/pcrecpp.patch


    ## ROS patches

    # Patch roslib - weird issue with rospack.
    # TODO: Need to look further (only on catkin_make_isolated)
    # patch -p0 -N -d $prefix < $my_loc/patches/roslib.patch

    # Patch collada_parser - cmake detects mkstemps even though Android does not support it
    # TODO: investigate how to prevent cmake to detect system mkstemps
    patch -p0 -N -d $prefix < $my_loc/patches/collada_parser.patch

    # Patch laser_assembler - Remove testing for Android
    # TODO: It seems like there may be a better way to handle the test issues
    # http://stackoverflow.com/questions/22055741/googletest-for-android-ndk
    patch -p0 -N -d $prefix < $my_loc/patches/laser_assembler.patch

    # Patch laser_filters - Remove testing for Android
    # TODO: It seems like there may be a better way to handle the test issues
    # http://stackoverflow.com/questions/22055741/googletest-for-android-ndk
    # https://source.android.com/reference/com/android/tradefed/testtype/GTest.html
    patch -p0 -N -d $prefix < $my_loc/patches/laser_filters.patch

    # Patch camera_info_manager - remove testing for Android
    # TODO: It seems like there may be a better way to handle the test issues
    # http://stackoverflow.com/questions/22055741/googletest-for-android-ndk
    # https://source.android.com/reference/com/android/tradefed/testtype/GTest.html
    patch -p0 -N -d $prefix < $my_loc/patches/camera_info_manager.patch

    # Patch cv_bridge - remove Python dependencies
    # TODO: https://github.com/ros-perception/vision_opencv/pull/55 merged, need to wait until new version (current 1.11.7)
    patch -p0 -N -d $prefix < $my_loc/patches/cv_bridge.patch

    # Patch robot_pose_ekf - Add bfl library cmake variables, also, remove tests
    # TODO: The correct way to handle this would be to create .cmake files for bfl and do a findpackage(orocos-bfl)
    patch -p0 -N -d $prefix < $my_loc/patches/robot_pose_ekf.patch

    # Patch robot_state_publisher - Add log4cxx library cmake variables, also, add ARCHIVE DESTINATION
    # TODO: The correct way to handle this would be to create .cmake files for log4cxx and do a findpackage(log4cxx)
    # TODO: Create PR to add ARCHIVE DESTINATION
    patch -p0 -N -d $prefix < $my_loc/patches/robot_state_publisher.patch

    # Patch moveit_core - Add fcl library cmake variables
    # TODO: The correct way to handle this would be to create .cmake files for fcl and do a findpackage(fcl)
    patch -p0 -N -d $prefix < $my_loc/patches/moveit_core.patch

    # Patch moveit_core plugins - Add ARCHIVE DESTINATION
    # TODO: PR merged: https://github.com/ros-planning/moveit_core/pull/251
    # Wait for next release to remove (current 0.6.15)
    patch -p0 -N -d $prefix < $my_loc/patches/moveit_core_plugins.patch

    # Patch camera_calibration_parsers - Fix yaml-cpp dependency
    # TODO: PR created: https://github.com/ros-perception/image_common/pull/36
    patch -p0 -N -d $prefix < $my_loc/patches/camera_calibration_parsers.patch

    # Patch image_view - Remove GTK definition
    # TODO: Fixed in https://github.com/ros-perception/image_pipeline/commit/829b7a1ab0fa1927ef3f17f66f9f77ac47dbaacc
    # Wait dor next release to remove (current 1.12.13)
    patch -p0 -N -d $prefix < $my_loc/patches/image_view.patch

    # Patch urdf - Don't use pkconfig for android
    # TODO: PR created: https://github.com/ros/robot_model/pull/111
    patch -p0 -N -d $prefix < $my_loc/patches/urdf.patch

    # Patch global_planner - Add angles dependency
    # TODO: PR merged: https://github.com/ros-planning/navigation/pull/359
    # Wait for next release to remove (current 1.12.4)
    patch -p0 -N -d $prefix < $my_loc/patches/global_planner.patch


    ## Demo Application specific patches

    # Patch move_base - Remove pluginlib
    patch -p0 -N -d $prefix < $my_loc/patches/move_base.patch

    # Patch costmap_2d - Remove pluginlib
    patch -p0 -N -d $prefix < $my_loc/patches/costmap_2d.patch

fi

echo
echo -e '\e[34mBuilding library dependencies.\e[39m'
echo

[ -f $prefix/target/lib/libbz2.a ] || run_cmd build_library bzip2 $prefix/libs/bzip2
[ -f $prefix/target/lib/libuuid.a ] || run_cmd build_library uuid $prefix/libs/uuid
[ -f $prefix/target/lib/libboost_system.a ] || run_cmd copy_boost $prefix/libs/boost
[ -f $prefix/target/lib/libPocoFoundation.a ] || run_cmd build_library_with_toolchain poco $prefix/libs/poco-1.4.6p2
[ -f $prefix/target/lib/libtinyxml.a ] || run_cmd build_library tinyxml $prefix/libs/tinyxml
[ -f $prefix/target/lib/libconsole_bridge.a ] || run_cmd build_library console_bridge $prefix/libs/console_bridge
[ -f $prefix/target/lib/liblz4.a ] || run_cmd build_library lz4 $prefix/libs/lz4-r124/cmake_unofficial
[ -f $prefix/target/lib/libcurl.a ] || run_cmd build_library_with_toolchain curl $prefix/libs/curl-7.39.0
[ -f $prefix/target/include/urdf_model/model.h ] || run_cmd build_library urdfdom_headers $prefix/libs/urdfdom_headers
[ -f $prefix/target/lib/liburdfdom_model.a ] || run_cmd build_library urdfdom $prefix/libs/urdfdom
[ -f $prefix/target/lib/libiconv.a ] || run_cmd build_library_with_toolchain libiconv $prefix/libs/libiconv-1.14
[ -f $prefix/target/lib/libxml2.a ] || run_cmd build_library_with_toolchain libxml2 $prefix/libs/libxml2-2.9.1
[ -f $prefix/target/lib/libcollada-dom2.4-dp.a ] || run_cmd build_library collada_dom $prefix/libs/collada-dom-2.4.0
[ -f $prefix/target/lib/libassimp.a ] || run_cmd build_library assimp $prefix/libs/assimp-3.1.1
[ -f $prefix/target/lib/libeigen.a ] || run_cmd build_eigen $prefix/libs/eigen
[ -f $prefix/target/lib/libqhullstatic.a ] || run_cmd build_library qhull $prefix/libs/qhull-2012.1
[ -f $prefix/target/lib/liboctomap.a ] || run_cmd build_library octomap $prefix/libs/octomap-1.6.8
[ -f $prefix/target/lib/libyaml-cpp.a ] || run_cmd build_library yaml-cpp $prefix/libs/yaml-cpp
[ -f $prefix/target/lib/libopencv_core.a ] || run_cmd build_library opencv $prefix/libs/opencv-2.4.9
[ -f $prefix/target/lib/libflann_cpp_s.a ] || run_cmd build_library flann $prefix/libs/flann
[ -f $prefix/target/lib/libpcl_common.a ] || run_cmd build_library pcl $prefix/libs/pcl
[ -f $prefix/target/lib/liborocos-bfl.a ] || run_cmd build_library bfl $prefix/libs/bfl-0.7.0
[ -f $prefix/target/lib/liborocos-kdl.a ] || run_cmd build_library orocos_kdl $prefix/libs/orocos_kdl-1.3.0
[ -f $prefix/target/lib/liblog4cxx.a ] || run_cmd build_library_with_toolchain log4cxx $prefix/libs/apache-log4cxx-0.10.0
[ -f $prefix/target/lib/libccd.a ] || run_cmd build_library libccd $prefix/libs/libccd-2.0
[ -f $prefix/target/lib/libfcl.a ] || run_cmd build_library fcl $prefix/libs/fcl-0.3.2
[ -f $prefix/target/lib/libpcrecpp.a ] || run_cmd build_library pcrecpp $prefix/libs/pcrecpp


echo
echo -e '\e[34mCross-compiling ROS.\e[39m'
echo

if [[ $debugging -eq 1 ]];then
    run_cmd build_cpp $prefix --debug-symbols
else
    run_cmd build_cpp $prefix
fi

echo
echo -e '\e[34mSetting up ndk project.\e[39m'
echo

run_cmd setup_ndk_project $prefix/roscpp_android_ndk $portable

echo
echo -e '\e[34mCreating Android.mk.\e[39m'
echo

# Library path is incorrect for urdf.
# TODO: Need to investigate the source of the issue
sed -i 's/set(libraries "urdf;/set(libraries "/g' $CMAKE_PREFIX_PATH/share/urdf/cmake/urdfConfig.cmake

run_cmd create_android_mk $prefix/catkin_ws/src $prefix/roscpp_android_ndk

if [[ $debugging -eq 1 ]];then
    sed -i "s/#LOCAL_EXPORT_CFLAGS/LOCAL_EXPORT_CFLAGS/g" $prefix/roscpp_android_ndk/Android.mk
fi

echo
echo -e '\e[34mCreating sample app.\e[39m'
echo

( cd $prefix && run_cmd sample_app sample_app $prefix/roscpp_android_ndk )

echo
echo -e '\e[34mBuilding apk.\e[39m'
echo

(cd $prefix/sample_app && ant debug)

echo
echo -e '\e[34mCreating move_base sample app.\e[39m'
echo

cp $my_loc/files/Android.mk.move_base $prefix/roscpp_android_ndk/Android.mk
( cd $prefix && run_cmd sample_app move_base_app $prefix/roscpp_android_ndk )

echo
echo -e '\e[34mBuilding move_base apk.\e[39m'
echo

(cd $prefix/move_base_app && ant debug)

echo
echo 'done.'
echo 'summary of what just happened:'
echo '  target/      was used to build static libraries for ros software'
echo '    include/   contains headers'
echo '    lib/       contains static libraries'
echo '  roscpp_android_ndk/     is a NDK sub-project that can be imported into an NDK app'
echo '  sample_app/  is an example of such an app, a native activity'
echo '  sample_app/bin/sample_app-debug.apk  is the built apk, it implements a subscriber and a publisher'
echo '  move_base_sample_app/  is an example app that implements the move_base node'
echo '  move_base_app/bin/move_base_app-debug.apk  is the built apk for the move_base example'
