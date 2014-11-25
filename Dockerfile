FROM ubuntu:14.04

MAINTAINER Parnell Springmeyer <parnell@plumlife.com>

# Update our sources
RUN apt-get update && apt-get install -y \
    gcc-arm-linux-gnueabi \
    g++-arm-linux-gnueabi \
    gcc \
    g++ \
    git \
    curl \
    libssl-dev \
    autoconf \
    make

# Set locale encoding
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

RUN mkdir -p /opt/arm
WORKDIR /opt/arm

# Download libraries
RUN curl http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz | tar zx
RUN curl https://www.openssl.org/source/openssl-1.0.1j.tar.gz | tar zx

ADD ./erlang_otp-arm /erlang_otp-arm

RUN /erlang_otp-arm/scripts/build-utils

RUN rm -rf ncurses-5.9
RUN rm -rf openssl-1.0.1j

# Clone and checkout OTP
RUN git clone https://github.com/erlang/otp.git
RUN cd otp && git checkout OTP-17.3.4

RUN apt-get install -y libncurses5-dev

# Build the x86 version first
RUN cd otp && ./otp_build autoconf
RUN cd otp && ./otp_build configure
RUN cd otp && ./otp_build boot
RUN cd otp && make install clean

# Build the ARM version now
RUN cd otp && ./otp_build configure --xcomp-conf=/erlang_otp-arm/config/erl-xcomp-arm-linux.conf --without-odbc
RUN cd otp && ./otp_build boot -a
RUN cd otp && ./otp_build release -a /opt/arm/lib/erlang
