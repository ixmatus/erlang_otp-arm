FROM plumlife/crosstool-ng:gcc-4.9_eglibc-2.15

MAINTAINER Parnell Springmeyer <parnell@plumlife.com>

# Update our sources
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    git \
    curl \
    libssl-dev \
    autoconf \
    make

RUN mkdir -p /opt/arm
WORKDIR /opt/arm

# Download libraries
RUN curl http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz | tar zx
RUN curl https://www.openssl.org/source/openssl-1.0.1j.tar.gz | tar zx
RUN curl https://download.libsodium.org/libsodium/releases/libsodium-1.0.3.tar.gz | tar zx

ADD ./erlang_otp-arm /erlang_otp-arm

RUN /erlang_otp-arm/scripts/build-utils

RUN rm -rf ncurses-5.9
RUN rm -rf openssl-1.0.1j

# Clone and checkout OTP
RUN git clone https://github.com/erlang/otp.git
RUN cd otp && git checkout OTP-17.5.6.2

RUN apt-get install -y libncurses5-dev

# Build the x86 version first
RUN cd otp && ./otp_build autoconf
RUN cd otp && ./otp_build configure
RUN cd otp && ./otp_build boot
RUN cd otp && make install clean

ADD ./config /erlang_otp-arm/config

# Build the ARM version now
RUN cd otp && ./otp_build configure --xcomp-conf=/erlang_otp-arm/config/erl-xcomp-arm-linux.conf
RUN export PATH=/root/x-tools/arm-plum-linux-gnueabi/bin:$PATH && cd otp && ./otp_build boot -a
RUN export PATH=/root/x-tools/arm-plum-linux-gnueabi/bin:$PATH && cd otp && ./otp_build release -a /opt/arm/lib/erlang
RUN /opt/arm/lib/erlang/Install -minimal /opt/arm/lib/erlang

# Dialyze OTP
RUN /erlang_otp-arm/scripts/build-plt
