#!/bin/bash
apt update && apt install cmake make gcc g++ pkg-config build-essential libfftw3-dev libmbedtls-dev libyaml-cpp-dev libboost-program-options-dev libconfig++-dev libgtest-dev libsctp-dev libzmq3-dev git
git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build
cd build
cmake ../
make -j4
