# picotool build stage
FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        cmake \
        build-essential \
        automake \
        libtool \
        pkg-config \
        libhidapi-dev \
        libusb-1.0-0-dev && \
    rm -rf /var/lib/apt/lists/*

# The Pico SDK is temporarily used to build picotool.
WORKDIR /
RUN git clone https://github.com/raspberrypi/pico-sdk.git --branch 2.2.0
WORKDIR /pico-sdk
RUN git submodule update --init
ENV PICO_SDK_PATH=/pico-sdk

WORKDIR /
RUN git clone https://github.com/raspberrypi/picotool.git --branch 2.2.0-a4
WORKDIR /picotool
RUN git submodule update --init
RUN cmake -B build && \
    cmake --build build -j"$(nproc)" && \
    cmake --install build --prefix /opt/picotool

# Build a copy of OpenOCD that's compatible with the RP2350 and the Pico Debug Probe.

# JimTCL dependency required to build OpenOCD
WORKDIR /
RUN git clone --recurse-submodules https://github.com/msteveb/jimtcl.git --branch 0.79
WORKDIR /jimtcl
RUN ./configure && make && make install

WORKDIR /
RUN git clone --recurse-submodules https://github.com/openocd-org/openocd.git
WORKDIR /openocd
RUN ./bootstrap && ./configure --prefix=/opt/openocd --enable-cmsis-dap=yes && make && make install

# Main stage
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        cmake \
        build-essential \
        python3 \
        wget \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Install a pinned version of the ARM toolchain.
ARG TARGETARCH
ARG ARM_TOOLCHAIN_VERSION=14.2.rel1
RUN set -eux; \
    case "$TARGETARCH" in \
        amd64) ARM_HOST=x86_64; ARM_SHA256=62a63b981fe391a9cbad7ef51b17e49aeaa3e7b0d029b36ca1e9c3b2a9b78823 ;; \
        arm64) ARM_HOST=aarch64; ARM_SHA256=87330bab085dd8749d4ed0ad633674b9dc48b237b61069e3b481abd364d0a684 ;; \
        *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    TARBALL="arm-gnu-toolchain-${ARM_TOOLCHAIN_VERSION}-${ARM_HOST}-arm-none-eabi.tar.xz"; \
    wget -q -O /tmp/toolchain.tar.xz \
        "https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_TOOLCHAIN_VERSION}/binrel/${TARBALL}"; \
    echo "${ARM_SHA256}  /tmp/toolchain.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/arm-toolchain; \
    tar -xJf /tmp/toolchain.tar.xz -C /opt/arm-toolchain --strip-components=1; \
    rm /tmp/toolchain.tar.xz
ENV PATH="/opt/arm-toolchain/bin:${PATH}"

# Only bring over the installed picotool, not the whole Pico SDK.
COPY --from=builder /opt/picotool /usr/local

# Bring over OpenOCD.
COPY --from=builder /opt/openocd /usr/local

WORKDIR /project
