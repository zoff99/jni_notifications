#! /bin/bash

_HOME_="$(pwd)"
export _HOME_

id -a
pwd
ls -al

export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/


mkdir -p $_SRC_
mkdir -p $_INST_

export LD_LIBRARY_PATH=$_INST_/lib/
export PKG_CONFIG_PATH=$_INST_/lib/pkgconfig

# -- more Deterministic builds --
echo "---"
hostnamectl||echo "ignore error"
echo "---"
hostname||echo "ignore error"
echo "---"
domainname||echo "ignore error"
echo "---"
date
export TZ=UTC
date
locale
export LC_ALL=C
export LANG=C
export LANGUAGE=C
locale
export ZERO_AR_DATE=1
export SOURCE_DATE_EPOCH=1696924800
# -- more Deterministic builds --

# ----------- config ------------
ORIGPATH=$PATH
export ORIGPATH
NEWPATH=$PATH # /usr/x86_64-w64-mingw32/bin:$PATH
export NEWPATH
export PATH=$NEWPATH

MAKEFLAGS=j$(nproc)
export MAKEFLAGS

WGET_OPTIONS="--timeout=10"
export WGET_OPTIONS

# ----------- config ------------


## ---------------------------
pwd
ls -al
rm -fv libjni_notifications*
ls -al
## ---------------------------

echo "JAVADIR1------------------"
find /usr -name 'jni.h'
echo "JAVADIR1------------------"

echo "JAVADIR2------------------"
find /usr -name 'jni_md.h'
echo "JAVADIR2------------------"

dirname $(find /usr -name 'jni.h' 2>/dev/null|grep -v 'libavcodec'|grep -v 'android' 2>/dev/null|head -1) > /tmp/xx1
dirname $(find /usr -name 'jni_md.h' 2>/dev/null|grep -v 'android' 2>/dev/null|head -1) > /tmp/xx2
export JAVADIR1=$(cat /tmp/xx1)
export JAVADIR2=$(cat /tmp/xx2)
echo "JAVADIR1:""$JAVADIR1"
echo "JAVADIR2:""$JAVADIR2"

CFLAGS_ADDON='-O2 -g -fPIC'
CFLAGS_MORE="-fdebug-prefix-map=/home/runner/work/jni_notifications/jni_notifications=/ --param=ssp-buffer-size=1 -fstack-protector-all -D_FORTIFY_SOURCE=2 -std=gnu99"

if [ "$2""x" == "asanx" ]; then
    ASAN_FLAGS="-fsanitize=address -fno-omit-frame-pointer -fsanitize-recover=address -static-libasan"
else
    ASAN_FLAGS=""
fi

gcc \
$CFLAGS_ADDON $CFLAGS_MORE \
$ASAN_FLAGS \
-Wall \
-Wno-unused-function \
-Wno-discarded-qualifiers \
-Wno-unused-const-variable \
-Wno-deprecated-declarations \
-D_FILE_OFFSET_BITS=64 -D__USE_GNU=1 \
-I$JAVADIR1/ \
-I$JAVADIR2/ \
jni_notifications.c \
$(pkg-config --libs --cflags libnotify) \
-shared \
-Wl,-soname,libjni_notifications.so -o libjni_notifications.so || exit 1

echo "------------------"
ldd libjni_notifications.so
echo "------------------"
ls -al libjni_notifications.so || exit 1
pwd

if [ "$2""x" == "asanx" ]; then
    # check if we actually have ASAN symbols in the library file
    nm libjni_notifications.so | grep -i asan || exit 1
fi

file libjni_notifications.so


if [ "$2""x" == "asanx" ]; then
    ls -al /usr/lib/x86_64-linux-gnu/libasan*
    export ASAN_OPTIONS="detect_leaks=0,halt_on_error=true"
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libasan.so.6.0.0 java -cp . -Djava.library.path=$(pwd) com.zoffcc.applications.jninotifications.NTFYActivity
else
    java -cp . -Djava.library.path=$(pwd) com.zoffcc.applications.jninotifications.NTFYActivity
fi

