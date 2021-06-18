# smouth-os  [![Build Status](https://github.com/RyRose/smouth-os/actions/workflows/continuous_test.yml/badge.svg)](https://github.com/RyRose/smouth-os/actions/workflows/continuous_test.yml)

## How to Run

To execute the kernel with QEMU, the following command will cross-compile the
kernel for the i386 platform and run it using QEMU. Please note this will take
upwards of an hour to run the first time since it must build the toolchain for
cross-compiling the kernel.

```shell script
bazel run //tools/go/cmd/qemu:serial --config=i386
```

## Testing

### Unit Tests

To run all of the unit tests, execute the command below:

```shell script
bazel test //...
```

These compile and run natively on your machine to verify logic that makes no
assumptions whether it's hosted or running on a specific architecture.

### Integration Tests (ktests)

To run all of the integration tests, execute the command below:

```shell script
bazel test --config i386 //...
```

These run a miniature version of the kernel in QEMU for the i386 architecture
and verifies logic that cannot run in a hosted environment. This will take
upwards of an hour to run the first time since it must create the
cross-compilation toolchain. You might try running one of the following commands
if you want to avoid this latency but there's no guarantee that it will work
outside of the continuous integration test environment in
[Travis CI](https://travis-ci.org/RyRose/smouth-os):

```shell script
# Linux
bazel test --config i386 --config i386-linux-premade //...

# OSX
bazel test --config i386 --config i386-darwin-premade //...
```

#### Debugging

To debug any integration test, consider running one the following commands.
Please note they are examples and the ktest's build target should be replaced
with the ktest you are debugging:

```shell script
# Run the ktest with qemu-system-i386 and displays output on QEMU monitor.
bazel run --config i386 //kernel/core:init_ktest-qemu

# Run the ktest with qemu-system-i386 and prints serial port output to standard out.
bazel run --config i386 //kernel/core:init_ktest-serial

# Load the ktest with qemu-system-i386 and remotely debug with GDB.
bazel run --config i386 --config dbg //kernel/core:init_ktest-gdb
```

## Goal

To develop an operating system that emits the wondrous tunes of All Star by
Smash Mouth.

## Why?

...
