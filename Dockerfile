# pictool build stage
FROM alpine:3.21 AS builder

RUN apk add --no-cache \
        git \
        ca-certificates \
        cmake \
        build-base \
        linux-headers \
        gcc-arm-none-eabi \
        g++-arm-none-eabi \
        newlib-arm-none-eabi \
        python3

# The Pico SDK is only used to build picotool.
# It is not copied forward.
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

# Main stage
FROM alpine:3.21

RUN apk add --no-cache \
        git \
        cmake \
        build-base \
        linux-headers \
        gcc-arm-none-eabi \
        g++-arm-none-eabi \
        newlib-arm-none-eabi \
        python3

# Only bring over the installed picotool.
COPY --from=builder /opt/picotool /usr/local

WORKDIR /project
