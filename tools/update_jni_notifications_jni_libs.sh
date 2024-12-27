#! /bin/bash
base_url='https://github.com/zoff99/jni_notifications/releases/download/nightly/'

file_mac='libjni_notifications.jnilib'
file_arm_mac='libjni_notifications_arm64.jnilib'
file_lix='libjni_notifications.so'
file_asan_lix='libjni_notifications.so__ASAN'
file_lix_rust='libjni_notifications_rs.so'
file_rpi='libjni_notifications_raspi.so'

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

basedir="$_HOME_""/../"

cd "$basedir"
wget "$base_url""$file_mac" -O "$file_mac"
wget "$base_url""$file_arm_mac" -O "$file_arm_mac"
wget "$base_url""$file_lix" -O "$file_lix"
wget "$base_url""$file_asan_lix" -O "$file_asan_lix"
wget "$base_url""$file_lix_rust" -O "$file_lix_rust"
wget "$base_url""$file_rpi" -O "$file_rpi"
