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

source "$HOME/.cargo/env"
cargo build --release
mv -v target/release/libjni_notifications.so ./libjni_notifications_rs.so

echo "------------------"
ldd libjni_notifications_rs.so
echo "------------------"
ls -al libjni_notifications_rs.so || exit 1
pwd
file libjni_notifications_rs.so

# copy the rust library over the normal linux library, so the test will use the rust library
cp -av libjni_notifications_rs.so libjni_notifications.so

java -cp . -Djava.library.path=$(pwd) com.zoffcc.applications.jninotifications.NTFYActivity

