#!/bin/bash
apt update
apt install build-essential git debhelper devscripts dh-python sphinx-common quilt libzstd-dev pkg-config equivs asciidoc-base automake bc bison cpio file flex gcc kmod libdw-dev libelf-dev libiberty-dev libnuma-dev libpve-common-perl libslang2-dev libssl-dev libtool lintian lz4 perl-modules xmlto zlib1g-dev -y
git clone --recurse-submodules git://git.proxmox.com/git/pve-kernel.git
cd pve-kernel
git reset --hard 16e43ddaf64d84fccc72d3011a61887b2f82d5de
git submodule update --init --recursive

# Linux TKG Patches
cp ../Linux-TKG.patch patches/kernel/
mv patches/kernel/0004-pci-Enable-overrides-for-missing-ACS-capabilities-4..patch patches/kernel/0004-pci-Enable-overrides-for-missing-ACS-capabilities-4..patch.bak
cp ../rules.patch debian/
cd debian
patch -p1 <  rules.patch && rm rules.patch
cd ..

# KVM Hypervisor-Interception/Trap Patch (Only For Intel)
cp ../Trap.patch patches/kernel/

# RDTSC Patch
# cp ../RDTSC.patch patches/kernel/

make
