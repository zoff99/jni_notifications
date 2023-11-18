#! /bin/bash

_HOME_="$(pwd)"
export _HOME_

_HOME2_=$(dirname $0)
export _HOME2_
_HOME3_=$(cd $_HOME2_;pwd)
export _HOME3_

id -a
pwd
ls -al

export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/


mkdir -p $_SRC_
mkdir -p $_INST_

export LD_LIBRARY_PATH=$_INST_/lib/
export PKG_CONFIG_PATH=$_INST_/lib/pkgconfig


# ----------- config ------------
ORIGPATH=$PATH
export ORIGPATH
NEWPATH=$PATH # /usr/x86_64-w64-mingw32/bin:$PATH
export NEWPATH
export PATH=$NEWPATH

# MAKEFLAGS=j$(nproc)
# export MAKEFLAGS

WGET_OPTIONS="--timeout=10"
export WGET_OPTIONS

# ----------- config ------------


## ---------------------------
pwd
ls -al
## ---------------------------

echo "JAVADIR1------------------"
find /usr -name 'jni.h'
echo "JAVADIR1------------------"

# /usr/local/Cellar/openjdk/15.0.2/include/jni.h
# /usr/local/Cellar/openjdk/15.0.2/include/jni_md.h

# /usr/local/Cellar/openjdk/15.0.2/libexec/openjdk.jdk/Contents/Home/include/jni.h
# /usr/local/Cellar/openjdk/15.0.2/libexec/openjdk.jdk/Contents/Home/include/darwin/jni_md.h

echo "JAVADIR2------------------"
find /usr -name 'jni_md.h'
echo "JAVADIR2------------------"

mkdir -p "$_INST_/jinclude/"
cp -av "$_HOME3_"/jni_md.h "$_INST_/jinclude/"
cp -av "$_HOME3_"/jni.h "$_INST_/jinclude/"

export CFLAGS=" -fPIC -g -O3 -std=gnu99 -I$_INST_/include/ -I$_INST_/jinclude/ -L$_INST_/lib -fstack-protector-all "

gcc $CFLAGS \
-Wall \
-Wno-unused-function \
-Wno-discarded-qualifiers \
-Wno-unused-const-variable \
-Wno-deprecated-declarations \
-framework Foundation \
-framework CoreFoundation \
-D_FILE_OFFSET_BITS=64 -D__USE_GNU=1 \
-I$JAVADIR1/ \
-I$JAVADIR2/ \
jni_notifications_macos.c \
-lpthread \
-lm \
-shared \
-o libjni_notifications_macos.jnilib || exit 1


ls -al libjni_notifications_macos.jnilib || exit 1

otool -L libjni_notifications_macos.jnilib
pwd
file libjni_notifications_macos.jnilib

pwd
find . -name libjni_notifications_macos.jnilib


