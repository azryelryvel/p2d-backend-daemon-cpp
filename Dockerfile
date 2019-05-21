FROM debian:9-slim

ENV BOOST_VERSION 1.70.0
ENV LIBTORRENT_VERSION 1.2.1
ENV GRPC_VERSION 1.20.1
ENV PROTOBUF_VERSION 3.7.1

RUN apt update \
 && apt -y install g++ wget make zlib1g-dev libc-ares-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/ \
 && echo "using gcc ;" > /root/user.jam

RUN wget -q https://github.com/grpc/grpc/archive/v$GRPC_VERSION.tar.gz -O /opt/grpc.tgz \
 && cd /opt \
 && tar -xf grpc.tgz \
 && rm grpc.tgz \
 && mv grpc* grpc \
 && rmdir /opt/grpc/third_party/protobuf/ \
 && wget -q https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-cpp-$PROTOBUF_VERSION.tar.gz -O /opt/protobuf.tgz \
 && tar -xf protobuf.tgz \
 && rm protobuf.tgz \
 && mv protobuf* /opt/grpc/third_party/protobuf/ \
 && cd grpc \
 && make -j $(nproc) static \
 && make install


RUN export _BOOST_VERSION=$(echo $BOOST_VERSION|tr . _) \
 && wget -q https://dl.bintray.com/boostorg/release/$BOOST_VERSION/source/boost_${_BOOST_VERSION}.tar.gz -O /opt/boost.tgz \
 && cd /opt \
 && tar -xf boost.tgz \
 && rm boost.tgz \
 && mv boost* boost \
 && cd boost \
 && sh bootstrap.sh

ENV BOOST_ROOT /opt/boost

RUN export _LIBTORRENT_VERSION=$(echo $LIBTORRENT_VERSION|tr . _) \
 && wget -q https://github.com/arvidn/libtorrent/releases/download/libtorrent-${_LIBTORRENT_VERSION}/libtorrent-rasterbar-$LIBTORRENT_VERSION.tar.gz -O /opt/libtorrent.tgz \
 && cd /opt \
 && tar -xf libtorrent.tgz \
 && rm libtorrent.tgz \
 && mv libtorrent* libtorrent \
 && cd libtorrent \
 && /opt/boost/b2 runtime-link=static link=static boost-link=static -j $(nproc)


WORKDIR /usr/src/

COPY src/main/ Makefile /usr/src/

RUN cd /usr/src \
 && make

CMD /usr/src/p2pd magnet "magnet:?xt=urn:btih:b47882a62eedec7767aa86b7a866f1dd846c5357&dn=Harry+Potter+and+the+Sorcerers+Stone+%282001%29+1080p+BrRip+x264+-+1&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80&tr=udp%3A%2F%2Fopen.demonii.com%3A1337&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969&tr=udp%3A%2F%2Fexodus.desync.com%3A6969"


