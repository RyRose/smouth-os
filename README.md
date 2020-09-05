# smouth-os [![Build Status](https://travis-ci.org/RyRose/smouth-os.svg?branch=master)](https://travis-ci.org/RyRose/smouth-os)

## How to Run

To execute the kernel with QEMU, the following command will cross-compile the kernel for the i386 platform and run it 
using QEMU. Please note this will take upwards of an hour to run the first time since it must build the toolchain for
cross-compiling the kernel.

```sh
bazel run //tools/go/cmd/qemu:serial --config=i386
```

## Goal

To develop an operating system that emits the wondrous tunes of All Star by Smash Mouth.

## Why?

...
