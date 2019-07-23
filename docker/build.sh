#!/usr/bin/env bash

docker image build -t floatsmith \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) \
    .
