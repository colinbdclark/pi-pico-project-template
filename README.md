# Raspberry Pi Pico Project Template

This repository documents my current preferred way of developing firmware with the Pico SDK.

This setup vendors the Pico SDK in the repository using submodules to avoid versioning issues with old firmware. However, it could be easily modified to support a global Pico SDK.

## To Dos
- [ ] Add support for building in VS Code with the CMake extension
- [ ] Add the ability to build Release and Debug versions (by specifying an argument to the shell script and by setting up VS Code tasks for each)
- [ ] Document how to install the Pico SDK toolchain (both the default installation and the versioned, isolated way used by Pico VS Code plugin)
- [ ] Separate the Docker and local CMake build directories

## Getting Started
### Prerequisites
1. Git
2. CMake
3. Docker and/or the Pi Pico SDK toolchain

### Install OpenOCD, Picotool, and the Compiler Toolchain
TODO: Add instructions.

### Update Submodules
Init and recursively update all submodules:
```git submodule update --init --recursive```

### Set Environment Variables
The following environment variables need to be set:
1. ```PICO_OPENOCD_PATH``` should point to a directory containing an RP2350-compatible version of OpenOCD (which should contain both the openocd binary and its scripts directory).
2.  ```PICO_TOOLCHAIN_PATH``` should point to a directory containing the arm-eabi-none GCC cross-compiler.

#### Example Environment Variables
```sh
PICO_TOOLS_PATH=~/.pico-sdk
export PICO_TOOLCHAIN_PATH=$PICO_TOOLS_PATH/toolchain/13_3_Rel1
export PICO_OPENOCD_PATH=$PICO_TOOLS_PATH/openocd/0.12.0+dev
```

## Configuring
The project name, hardware platform, and device are specified in CMakeLists.txt, and are set appropriately for a Pico 2 W. They should be customized to your project:

```CMake
set(NAME blinky)
set(PICO_PLATFORM rp2350)
set(PICO_BOARD pico2_w)
```

## Compilation
The firmware can be compiled either in a Docker container or using a locally-installed version of the Pi Pico development toolchain. Flashing the firmware is be done locally using the Pico fork of OpenOCD.

Support for building and remote debugging the firmware in VS Code is also included.

### Compile Locally in the Shell
Assuming the necessary toolchain is installed, a couple of scripts are provided for compiling locally:

#### Compile the Firmware
```sh
./compile.sh
```

#### Clean Up the Build Artifacts
```sh
./clean.sh
```

### Building and Debugging with VS Code
You'll need a Pi Pico Probe connected to your computer, and your Pico board should also be connected via USB. The project is set up with OpenOCD acting as a debug server for arm-eabi-none-gdb running on your computer.

### Compile with Docker
The Docker image contains the Pi Pico cross-compilation toolchain pre-installed, so you don't need to have it installed locally (unless you want use a debugger). It assumes you will bind mount the project directory as a volume in the Docker container.

#### Build the Docker Image
```sh
docker build . -t blinky
```

#### Compile the Firwmware
```sh
docker run -v `pwd`:/project --rm blinky ./docker-compile.sh
```

#### Run an interactive shell in the container
```sh
docker run -v `pwd`:/project -it --rm blinky
```

### Caveats
The Docker and local builds share the same CMake build directory, but aren't compatible. Make sure to clean before switching between them.

## Credits
This template was created by Colin Clark of [Lichen Community Systems Worker Cooperative Canada](https://lichen.coop). It contains the blink example source code from Raspberry Pi's [pico-examples repository](https://github.com/raspberrypi/pico-examples/blob/master/blink/blink.c).

## License
This repository is released under the BSD-3 license.
