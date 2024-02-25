#! /bin/bash

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

echo $_HOME_
cd $_HOME_

if [ "$1""x" == "buildx" ]; then
    docker build -f Dockerfile_rsub20 -t jni_notifications_ready_rsub20_001 .
    exit 0
fi

build_for='
rust:20.04
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

    rsync -av ../jni_notifications.rs ../Cargo.toml ../src --exclude=.localrun $_HOME_/"$system_to_build_for"/workspace/build/
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

source "$HOME/.cargo/env"
CARGO_TARGET_DIR=./outlib cargo build --release

find . -name "*so"

ldd ./outlib/release/libjni_notifications.so
ls -hal ./outlib/release/libjni_notifications.so

cp -av ./outlib/release/libjni_notifications.so libjni_notifications.so

pwd
ls -al libjni_notifications.so || exit 1
file libjni_notifications.so
ls -hal libjni_notifications.so

cp -v libjni_notifications.so /artefacts/ || exit 1

chmod a+rw /artefacts/*

' > $_HOME_/"$system_to_build_for"/script/run.sh

    mkdir -p $_HOME_/"$system_to_build_for"/workspace/build/c-toxcore/

    docker run -ti --rm \
      -v $_HOME_/"$system_to_build_for"/artefacts:/artefacts \
      -v $_HOME_/"$system_to_build_for"/script:/script \
      -v $_HOME_/"$system_to_build_for"/workspace:/workspace \
      --net=host \
     "jni_notifications_ready_rsub20_001" \
     /bin/sh -c "apk add bash >/dev/null 2>/dev/null; /bin/bash /script/run.sh"
     if [ $? -ne 0 ]; then
        echo "** ERROR **:$system_to_build_for_orig"
        exit 1
     else
        echo "--SUCCESS--:$system_to_build_for_orig"
     fi

done


