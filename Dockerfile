FROM debian:9-slim

ARG BOOST_VERSION=1.70.0
ARG LIBTORRENT_VERSION=1.2.1
ARG GRPC_VERSION=1.20.1
ARG PROTOBUF_VERSION=3.7.1

RUN apt update \
 && mkdir -p /usr/share/man/man1 \
 && apt -y install g++ wget make zlib1g-dev libc-ares-dev libssl-dev openjdk-8-jre-headless \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/ \
 && export _BOOST_VERSION=$(echo $BOOST_VERSION|tr . _) \
 && export _LIBTORRENT_VERSION=$(echo $LIBTORRENT_VERSION|tr . _) \
 && wget -q https://github.com/grpc/grpc/archive/v$GRPC_VERSION.tar.gz -O /opt/grpc.tgz \
 && wget -q https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-cpp-$PROTOBUF_VERSION.tar.gz -O /opt/protobuf.tgz \
 && wget -q https://dl.bintray.com/boostorg/release/$BOOST_VERSION/source/boost_${_BOOST_VERSION}.tar.gz -O /opt/boost.tgz \
 && wget -q https://github.com/arvidn/libtorrent/releases/download/libtorrent-${_LIBTORRENT_VERSION}/libtorrent-rasterbar-$LIBTORRENT_VERSION.tar.gz -O /opt/libtorrent.tgz \
 && cd /opt \
 && tar -xf grpc.tgz \
 && tar -xf protobuf.tgz \
 && tar -xf boost.tgz \
 && tar -xf libtorrent.tgz \
 && rm grpc.tgz \
 && mv grpc* grpc \
 && rm protobuf.tgz \
 && rmdir /opt/grpc/third_party/protobuf/ \
 && mv protobuf* /opt/grpc/third_party/protobuf/ \
 && rm boost.tgz \
 && mv boost* boost \
 && rm libtorrent.tgz \
 && mv libtorrent* libtorrent \
 && cd grpc \
 && make -j$(nproc) static \
 && mv /opt/grpc/bins/opt/grpc_cpp_plugin /usr/local/bin/protoc-gen-grpc \
 && mv /opt/grpc/bins/opt/protobuf/protoc /usr/local/bin/protoc \
 && cd /opt/boost \
 && sh bootstrap.sh \
 && cd /opt/libtorrent \
 && export BOOST_ROOT=/opt/boost \
 && /opt/boost/b2 runtime-link=static link=static boost-link=static -j $(nproc)

WORKDIR /usr/src/

CMD ./gradlew generateProtocGrpc generateProtocCpp build

# /usr/src/build/exe/main/debug/p2p-daemon
