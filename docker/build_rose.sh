#!/bin/bash

# acquire source
mkdir -p $ROSE_HOME
git clone -b release https://github.com/rose-compiler/rose.git $ROSE_HOME/src
cd $ROSE_HOME/src
git checkout v0.9.11.95

# setup build folder and configure
./build
mkdir $ROSE_HOME/build
cd $ROSE_HOME/build
CFLAGS= CXXFLAGS='-std=c++11 -Wfatal-errors' $ROSE_HOME/src/configure \
    --prefix=$ROSE_HOME/install \
    --enable-languages=c,c++ \
    --with-boost=/usr --with-boost-libdir=/usr/lib/x86_64-linux-gnu \
    --enable-edg_version=5.0

# build Rose core and TypeForge
make install-core -j4
make install -C projects/typeforge -j4

# clean source and build folders to save space in the image
rm -rf $ROSE_HOME/src $ROSE_HOME/build

