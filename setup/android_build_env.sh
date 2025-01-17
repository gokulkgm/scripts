#!/usr/bin/env bash

# Copyright (C) 2018 Harsh 'MSF Jarvis' Shandilya
# Copyright (C) 2018 Akhil Narang
# SPDX-License-Identifier: GPL-3.0-only

# Script to setup an AOSP Build environment on Ubuntu and Linux Mint

LATEST_MAKE_VERSION="4.3"
LATEST_CCACHE_TAG="v4.8.2"
UBUNTU_16_PACKAGES="libesd0-dev"
UBUNTU_20_PACKAGES="libncurses5 curl python-is-python3 libhiredis-dev"
DEBIAN_10_PACKAGES="libncurses5"
DEBIAN_11_PACKAGES="libncurses5"
PACKAGES=""

# Get the output of uname -a and store it in a variable
uname_output=$(uname -a)

echo -e "Installing and updating APT packages...\n"

sudo apt update

# Install lsb-core packages
sudo DEBIAN_FRONTEND=noninteractive \
    apt install lsb-core -y

LSB_RELEASE="$(lsb_release -d | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')"

if [[ ${LSB_RELEASE} =~ "Mint 18" || ${LSB_RELEASE} =~ "Ubuntu 16" ]]; then
    PACKAGES="${UBUNTU_16_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Ubuntu 20" || ${LSB_RELEASE} =~ "Ubuntu 21" || ${LSB_RELEASE} =~ "Ubuntu 22" || ${LSB_RELEASE} =~ "Ubuntu 23" ]]; then
    PACKAGES="${UBUNTU_20_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Debian GNU/Linux 10" ]]; then
    PACKAGES="${DEBIAN_10_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Debian GNU/Linux 11" ]]; then
    PACKAGES="${DEBIAN_11_PACKAGES}"
fi

sudo DEBIAN_FRONTEND=noninteractive \
    apt install \
    adb autoconf automake axel bc bison build-essential \
    clang cmake expat fastboot flex g++ \
    g++-multilib gawk gcc gcc-multilib git gnupg gperf \
    htop imagemagick lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev \
    libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev \
    libsdl1.2-dev libssl-dev libtool libxml2 libxml2-utils '^lzma.*' lzop \
    maven ncftp ncurses-dev patch patchelf pkg-config pngcrush \
    pngquant python2.7 python-all-dev re2c schedtool squashfs-tools subversion \
    texinfo unzip w3m xsltproc zip zlib1g-dev lzip \
    libxml-simple-perl libswitch-perl apt-utils jq ripgrep \
    ${PACKAGES} -y

echo -e "\nDone."

# For all those distro hoppers, lets setup your git credentials
GIT_USERNAME="$(git config --get user.name)"
GIT_EMAIL="$(git config --get user.email)"
echo "Configuring git"
if [[ -z ${GIT_USERNAME} ]]; then
    echo -n "Enter your name: "
    read -r NAME
    git config --global user.name "${NAME}"
fi
if [[ -z ${GIT_EMAIL} ]]; then
    echo -n "Enter your email: "
    read -r EMAIL
    git config --global user.email "${EMAIL}"
fi
git config --global alias.cp 'cherry-pick'
git config --global alias.c 'commit'
git config --global alias.f 'fetch'
git config --global alias.m 'merge'
git config --global alias.rb 'rebase'
git config --global alias.rs 'reset'
git config --global alias.ck 'checkout'
git config --global credential.helper 'cache --timeout=99999999'
echo "git identity setup successfully!"

if [[ "$(command -v make)" ]]; then
    makeversion="$(make -v | head -1 | awk '{print $3}')"
    if [[ ${makeversion} != "${LATEST_MAKE_VERSION}" ]]; then
        echo "Installing make ${LATEST_MAKE_VERSION} instead of ${makeversion}"
        bash "$(dirname "$0")"/make.sh "${LATEST_MAKE_VERSION}"
    fi
fi

if [[ "$uname_output" != *"azure"* ]]; then
if [[ -z "$(command -v ccache)" ]]; then
        echo "Installing ccache ${LATEST_CCACHE_TAG}"
        bash "$(dirname "$0")"/ccache.sh "${LATEST_CCACHE_TAG}"
fi

# Increase maximum ccache size
echo -e "Setting ccache size to 100G"
ccache -M 100G
else
echo -e "Found Azure VM, skipping ccache"
fi

echo -e "\nSetting up shell environment..."
if [[ $SHELL = *zsh* ]]; then
sh_rc="${HOME}/.zshrc"
else
sh_rc="${HOME}/.bashrc"
fi

cat <<'EOF' >> $sh_rc

# Super-fast repo sync
repofastsync() { time schedtool -B -e ionice -n 0 `which repo` sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --retry-fetches=5 -j$(nproc --all) "$@"; }
EOF

if [[ "$uname_output" != *"azure"* ]]; then
cat <<'EOF' >> $sh_rc

export USE_CCACHE=1
export CCACHE_EXEC=/usr/local/bin/ccache
EOF
else
echo -e "Found Azure VM, skipping ccache env"
fi

echo "Installing repo"
sudo curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo
sudo chmod a+rx /usr/local/bin/repo

if [[ "$uname_output" != *"azure"* ]]; then
echo -e "Installing bottom"
curl -LO https://github.com/ClementTsang/bottom/releases/download/0.9.1/bottom_0.9.1_amd64.deb
sudo dpkg -i bottom_0.9.1_amd64.deb
rm bottom_0.9.1_amd64.deb

else
echo -e "Found Azure VM, skipping bottom setup"
fi

echo -e "\nDone!"