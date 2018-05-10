system=$(uname -s | tr 'DL' 'dl')-$(uname -m)
gcc_version=4.6
toolchain=arm-linux-androideabi-$gcc_version
platform=android-16
PYTHONPATH=/opt/ros/indigo/lib/python2.7/dist-packages:$PYTHONPATH
# Enable this value for debug build
CMAKE_BUILD_TYPE=Debug
# Enable this if you need to use pluginlib in Android.
# The plugins will be statically linked
use_pluginlib=1
