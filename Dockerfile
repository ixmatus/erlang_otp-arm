FROM plumlife/crosstool:gcc-4.9_glibc-2.20

MAINTAINER Parnell Springmeyer <parnell@plumlife.com>

# Update our sources
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    git \
    curl \
    libssl-dev \
    autoconf \
    libncurses5-dev \
    make

RUN mkdir -p /opt/arm
WORKDIR /opt/arm

# Download libraries
RUN curl http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz | tar zx && curl https://openssl.org/source/old/1.0.2/openssl-1.0.2d.tar.gz | tar zx && curl https://download.libsodium.org/libsodium/releases/libsodium-1.0.8.tar.gz | tar zx

# Build a newer version of git, for fuck's sake
RUN curl https://www.kernel.org/pub/software/scm/git/git-2.4.1.tar.gz | tar zx --no-same-owner && apt-get update && apt-get install --fix-missing -y libcurl4-openssl-dev gettext wpasupplicant && cd git-2.4.1 && ./configure --without-tcltk  && make && make install && cd ../ && rm -rf git-2.4.1

# Build libsodium for the host
RUN cd libsodium-1.0.8 && ./configure && make && make install

# Clone and checkout OTP
RUN git clone https://github.com/erlang/otp.git && cd otp && git checkout OTP-17.5.6.2

# Build the x86 version first
RUN cd otp && \
    ./otp_build autoconf && \
    ./otp_build configure --enable-dirty-schedulers && \
    MAKEFLAGS="-j8" ./otp_build boot && \
    make install clean

ADD ./erlang_otp-arm /erlang_otp-arm

RUN /erlang_otp-arm/scripts/build-utils && rm -rf ncurses-5.9 && rm -rf openssl-1.0.2d

ADD ./config /erlang_otp-arm/config

# Build the ARM version now
RUN cd otp && \
    ./otp_build configure --xcomp-conf=/erlang_otp-arm/config/erl-xcomp-arm-linux.conf && \
    export PATH=/root/x-tools/arm-plum-linux-gnueabi/bin:$PATH && \
    MAKEFLAGS="-j8" ./otp_build boot -a && \
    export PATH=/root/x-tools/arm-plum-linux-gnueabi/bin:$PATH && \
    ./otp_build release -a /opt/arm/lib/erlang && \
    /opt/arm/lib/erlang/Install -minimal /opt/arm/lib/erlang && \
    /erlang_otp-arm/scripts/build-plt
