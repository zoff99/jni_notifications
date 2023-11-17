#! /bin/bash

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

echo $_HOME_
cd $_HOME_

if [ "$1""x" == "buildx" ]; then
    docker build -f Dockerfile_ub20 -t jni_notifications_ready_ub20_001 .
    exit 0
fi

build_for='
ubuntu:20.04
'

for system_to_build_for in $build_for ; do

    system_to_build_for_orig="$system_to_build_for"
    system_to_build_for=$(echo "$system_to_build_for_orig" 2>/dev/null|tr ':' '_' 2>/dev/null)

    cd $_HOME_/
    mkdir -p $_HOME_/"$system_to_build_for"/

    mkdir -p $_HOME_/"$system_to_build_for"/artefacts
    mkdir -p $_HOME_/"$system_to_build_for"/script
    mkdir -p $_HOME_/"$system_to_build_for"/workspace/build/

    ls -al $_HOME_/"$system_to_build_for"/

    rsync -a ../jni_notifications.c --exclude=.localrun $_HOME_/"$system_to_build_for"/workspace/build/
    chmod a+rwx -R $_HOME_/"$system_to_build_for"/workspace/build >/dev/null 2>/dev/null

    echo '#! /bin/bash

cd /workspace/build/

_HOME_="$(pwd)"
export _HOME_

cd "$_HOME_"

export _SRC_=$_HOME_/src/
export _INST_=$_HOME_/inst/

mkdir -p $_SRC_
mkdir -p $_INST_

echo "*** compile ***"

cd /workspace/build/
gcc --version

ls -al

echo "JAVADIR1------------------"
find /usr -name "jni.h"
echo "JAVADIR1------------------"

echo "JAVADIR2------------------"
find /usr -name "jni_md.h"
echo "JAVADIR2------------------"


dirname $(find /usr -name "jni.h" 2>/dev/null|grep -v "libavcodec"|head -1) > /tmp/xx1
dirname $(find /usr -name "jni_md.h" 2>/dev/null|head -1) > /tmp/xx2
export JAVADIR1=$(cat /tmp/xx1)
export JAVADIR2=$(cat /tmp/xx2)
echo "JAVADIR1:""$JAVADIR1"
echo "JAVADIR2:""$JAVADIR2"

export CFLAGS=" -fPIC -O3 -g -std=gnu99 -fstack-protector-all -D_FORTIFY_SOURCE=2 "


faketime "2023-10-10 08:00:00" gcc $CFLAGS \
-Wall \
-Wno-unused-function \
-Wno-discarded-qualifiers \
-Wno-unused-const-variable \
-Wno-deprecated-declarations \
-DJAVA_LINUX \
-D_FILE_OFFSET_BITS=64 -D__USE_GNU=1 \
-I$JAVADIR1/ \
-I$JAVADIR2/ \
jni_notifications.c \
$(pkg-config --libs --cflags libnotify) \
-shared \
-Wl,-soname,libjni_notifications.so -o libjni_notifications.so || exit 1

ls -al libjni_notifications.so || exit 1
pwd
file libjni_notifications.so
cp -v libjni_notifications.so /artefacts/ || exit 1

chmod a+rw /artefacts/*

' > $_HOME_/"$system_to_build_for"/script/run.sh

    mkdir -p $_HOME_/"$system_to_build_for"/workspace/build/c-toxcore/

    docker run -ti --rm \
      -v $_HOME_/"$system_to_build_for"/artefacts:/artefacts \
      -v $_HOME_/"$system_to_build_for"/script:/script \
      -v $_HOME_/"$system_to_build_for"/workspace:/workspace \
      --net=host \
     "jni_notifications_ready_ub20_001" \
     /bin/sh -c "apk add bash >/dev/null 2>/dev/null; /bin/bash /script/run.sh"
     if [ $? -ne 0 ]; then
        echo "** ERROR **:$system_to_build_for_orig"
        exit 1
     else
        echo "--SUCCESS--:$system_to_build_for_orig"
     fi

done


