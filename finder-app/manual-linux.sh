#!/bin/bash
# Script outline to install and build kernel and rootfs.

set -e
set -u

# Ensure cross‐compiler and build tools are present
echo "Checking for aarch64-linux-gnu-gcc…"
if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
  echo "Installing cross-compiler and build dependencies…"
  apt-get update
  apt-get install -y \
    gcc-aarch64-linux-gnu \
    make \
    bc \
    bison \
    flex \
    libssl-dev \
    libncurses5-dev \
    libelf-dev \
    wget \
    cpio
fi

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1.33.1
FINDER_APP_DIR=$(realpath $(dirname "$0"))
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

# Parse optional outdir argument
if [ $# -lt 1 ]; then
  echo "Using default directory ${OUTDIR} for output"
else
  OUTDIR=$1
  echo "Using passed directory ${OUTDIR} for output"
fi

# Create output dir
mkdir -p "${OUTDIR}"

# 1. Kernel build
cd "${OUTDIR}"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
  echo "Cloning Linux source ${KERNEL_VERSION}..."
  git clone "${KERNEL_REPO}" --depth 1 --branch "${KERNEL_VERSION}" linux-stable
fi

if [ ! -e "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ]; then
  cd linux-stable
  echo "Building Linux kernel ${KERNEL_VERSION}..."
  make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
  make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
  make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
  cp arch/${ARCH}/boot/Image "${OUTDIR}/"
  cd "${OUTDIR}"
fi

echo "Kernel Image ready at ${OUTDIR}/Image"

# 2. Rootfs staging
echo "Creating rootfs staging dir..."
if [ -d "${OUTDIR}/rootfs" ]; then
  echo "Cleaning existing rootfs..."
  sudo rm -rf "${OUTDIR}/rootfs"
fi
mkdir -p "${OUTDIR}/rootfs"/{bin,dev,etc,home,lib,proc,sbin,sys,tmp,usr,var}
mkdir -p "${OUTDIR}/rootfs/usr"/{bin,sbin}
mkdir -p "${OUTDIR}/rootfs/var"/{log,run}

# 3. BusyBox build
cd "${OUTDIR}"
if [ ! -d "${OUTDIR}/busybox" ]; then
  echo "Downloading and extracting BusyBox ${BUSYBOX_VERSION}..."
  wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
  tar xjf busybox-${BUSYBOX_VERSION}.tar.bz2
  mv busybox-${BUSYBOX_VERSION} busybox
fi
cd busybox
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
cd "${OUTDIR}"

echo "BusyBox installed to rootfs/bin"

# 4. Library dependencies
echo "Library dependencies"

# locate each file exactly via gcc
LD_SO=$(aarch64-linux-gnu-gcc -print-file-name=ld-linux-aarch64.so.1)
LIBC=$(  aarch64-linux-gnu-gcc -print-file-name=libc.so.6)
LIBM=$(  aarch64-linux-gnu-gcc -print-file-name=libm.so.6)
LIBRES=$(aarch64-linux-gnu-gcc -print-file-name=libresolv.so.2)

# ensure only /lib is used
mkdir -p "${OUTDIR}/rootfs/lib"

# copy interpreter & shared libs all into /lib
cp -a "$LD_SO"    "${OUTDIR}/rootfs/lib/"
cp -a "$LIBC"     "${OUTDIR}/rootfs/lib/"
cp -a "$LIBM"     "${OUTDIR}/rootfs/lib/"
cp -a "$LIBRES"   "${OUTDIR}/rootfs/lib/"

# 5. Device nodes Device nodes
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null" c 1 3
sudo mknod -m 600 "${OUTDIR}/rootfs/dev/console" c 5 1

# 6. Cross-compile writer and copy
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
cp writer "${OUTDIR}/rootfs/home/"
cd "${OUTDIR}"

# 7. Copy finder app and configs
# Copy finder-related scripts and configs into the initramfs /home
cp "${FINDER_APP_DIR}/finder.sh"            "${OUTDIR}/rootfs/home/"
cp "${FINDER_APP_DIR}/finder-test.sh"       "${OUTDIR}/rootfs/home/"
cp "${FINDER_APP_DIR}/autorun-qemu.sh"      "${OUTDIR}/rootfs/home/"
mkdir -p "${OUTDIR}/rootfs/home/conf"
cp "${FINDER_APP_DIR}/conf/username.txt"  "${OUTDIR}/rootfs/home/conf/"
cp "${FINDER_APP_DIR}/conf/assignment.txt" "${OUTDIR}/rootfs/home/conf/"

# Ensure they’re executable and owned by root
chmod +x "${OUTDIR}/rootfs/home/"*.sh
#chown root:root "${OUTDIR}/rootfs/home/"*.sh "${OUTDIR}/rootfs/home/conf"/*

# 8. Permissions
sudo chown -R root:root "${OUTDIR}/rootfs"

# 9. Create initramfs
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root | gzip > "${OUTDIR}/initramfs.cpio.gz"
cd "${OUTDIR}"
echo "initramfs created at ${OUTDIR}/initramfs.cpio.gz"

