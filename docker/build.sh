#!/usr/bin/env bash

BOOST_VERSION=1.70.0
_BOOST_VERSION=$(echo ${BOOST_VERSION}|tr . _)
LIBTORRENT_VERSION=1.1.13
_LIBTORRENT_VERSION=$(echo ${LIBTORRENT_VERSION}|tr . _)
LIBDIR=/home/daryl/.local
export BOOST_ROOT=${LIBDIR}/boost

sudo pacman -S --needed linux-headers
mkdir -p ${LIBDIR}
echo "using gcc ;" > /${HOME}/user.jam

if [[ ! -d "${LIBDIR}/boost" ]]; then
    wget -q https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${_BOOST_VERSION}.tar.gz -O ${LIBDIR}/boost.tgz
    tar -C ${LIBDIR} -xf ${LIBDIR}/boost.tgz
    rm ${LIBDIR}/boost.tgz
    mv ${LIBDIR}/boost* ${LIBDIR}/boost
    cd ${LIBDIR}/boost
    sh bootstrap.sh
fi

if [[ ! -d "${LIBDIR}/libtorrent" ]]; then
    wget -q https://github.com/arvidn/libtorrent/releases/download/libtorrent-${_LIBTORRENT_VERSION}/libtorrent-rasterbar-${LIBTORRENT_VERSION}.tar.gz -O ${LIBDIR}/libtorrent.tgz
    tar -C ${LIBDIR} -xf ${LIBDIR}/libtorrent.tgz
    rm ${LIBDIR}/libtorrent.tgz
    mv ${LIBDIR}/libtorrent* ${LIBDIR}/libtorrent
    cd ${LIBDIR}/libtorrent
    ${LIBDIR}/boost/b2 -j8 -d0 runtime-link=static link=static boost-link=static
fi
#/opt/boost/b2 install --prefix=/root/local