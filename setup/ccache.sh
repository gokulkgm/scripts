#!/usr/bin/env bash

cd /tmp || exit 1
echo "Cloning ccache tag ${1:?}"
git clone -b "${1:?}" https://github.com/ccache/ccache.git
cd ccache || exit 1
mkdir build || exit 1
cd build || exit 1
cmake -DZSTD_FROM_INTERNET=ON -DCMAKE_BUILD_TYPE=Release ..
make -j"$(nproc)"
sudo make install
cd - || exit 1
echo -e "Removing ccache tmp directory"
rm -rf /tmp/ccache
