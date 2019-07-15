#!/usr/bin/env bash

rm -rf .floatsmith
../../floatsmith -B --run "./sum2pi_x" --ignore "answer diff error" --adapt

