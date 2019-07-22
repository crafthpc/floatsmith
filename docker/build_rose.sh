#!/bin/bash

ROSE_HOME=/opt/rose

# acquire source
mkdir -p $ROSE_HOME
git clone -b release https://github.com/rose-compiler/rose.git $ROSE_HOME/src
cd $ROSE_HOME/src
git checkout develop        # TODO: switch to particular release

# setup build folder and configure
./build
mkdir $ROSE_HOME/build
cd $ROSE_HOME/build
CFLAGS= CXXFLAGS='-std=c++11 -Wfatal-errors' $ROSE_HOME/src/configure \
    --prefix=$ROSE_HOME/install \
    --enable-languages=c,c++,binaries \
    --with-boost=/usr --with-boost-libdir=/usr/lib/x86_64-linux-gnu \
    --enable-languages=c,c++,cuda \
    --enable-edg_version=5.0

# build Rose core and TypeForge
make install-core -j4
make install -C projects/typeforge -j4

