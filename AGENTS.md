# AGENTS.md

Guidance for AI agents working in this repository.

## Project overview

`smouth-os` is a bare-metal hobby OS kernel written in Zig. It targets 32-bit
x86 and AArch64 QEMU `virt`, and runs under QEMU for development and testing.

## Repository layout

```
src/
  main.zig   – kernel entry point and test runner
  root.zig   – top-level `smouth` source module
  embed.zig  – compile-time embedded source files and binary assets
  assets/    – binary assets embedded into the kernel
  arch/      – architecture-specific code (one sub-directory per arch)
  kernel/    – architecture-independent kernel code
```

## Architecture vs kernel code

- **`src/arch/<arch>/`** — everything specific to one architecture: boot
  entry, CPU instructions, I/O port access, linker scripts, low-level hardware
  drivers that cannot be shared across architectures.
- **`src/kernel/`** — code that is (or could be) useful on more than one
  architecture: higher-level drivers, data structures, utilities, and init
  sequences that call into arch abstractions.

`src/` is one Zig module, named `smouth`. The directories remain separate to
make architecture-specific boundaries clear. When adding new code, prefer
`src/kernel/` unless it is inherently tied to a specific architecture.

## Module exports

Every new file must be exported as a `pub const` in its directory's `root.zig`
so it is reachable through the module hierarchy and picked up by
`std.testing.refAllDecls` automatically.

## Build and run

```sh
# Build the kernel image
zig build

# Run the kernel in QEMU
zig build run-x86
zig build run-aarch64
```

## Testing

| Command | What it runs |
|---|---|
| `zig build --test-timeout 5s test` | Hosted unit tests (no QEMU required), with a 5-second timeout per test |
| `timeout 5s zig build test-x86` | All source-module tests in QEMU on x86, with a 5-second timeout |
| `timeout 5s zig build test-aarch64` | Architecture-independent source-module tests in AArch64 QEMU |
| `zig build test-all` | All of the above |

CI applies a five-second per-test timeout to hosted tests and a five-second
process timeout to each QEMU test target. Run the commands above locally so a
stalled test fails promptly.

Tests that exercise hardware (I/O ports, TSC, etc.) must call
`try arch.freestanding()` as their first line; this skips them when running
under a hosted target. New code should have tests.

## Code conventions

- **File-level doc comments** use `//!`; inline comments use `//`; doc comments use `///`.
- Only comment code that genuinely needs clarification; do not add obvious
  comments.
- **Doc comments are required** on all functions, structs, struct member
  variables, and constants.
- **Naming**: follow Zig's standard naming rules:
  - `TitleCase` — types, and functions whose return type is `type`
  - `camelCase` — other callable things (functions, methods)
  - `snake_case` — everything else (variables, fields, constants, namespaces,
    file names, directory names)
  - Established external conventions (e.g. `ENOENT`, POSIX constants) take
    precedence over the above.
- **I/O ports** are always referenced through the `ioport.Port` enum rather
  than raw address literals.
- **Scoped logging**: every file that logs uses
  `const log = std.log.scoped(.module_name);`.
- **No dynamic allocation**: no heap allocator is available by default.
  Prefer fixed-size buffers and comptime structures.
- **No floating point**: do not use float types in kernel code. The x86 target
  disables SIMD and uses soft-float. AArch64 enables its FP/SIMD unit during
  boot solely because Zig emits vector register moves for aggregate copies.

## QEMU environment

The x86 QEMU machine is invoked with:

- `-nographic` — serial output only
- `isa-debug-exit` at port `0xF4` — non-zero write exits QEMU with error
- `pcspk-audiodev` — PC speaker audio
- `intel-hda` + `hda-duplex` — HD Audio device
- `virtio-sound-pci` — VirtIO sound device

The audio backend is `coreaudio` on macOS and `none` elsewhere.

The AArch64 QEMU `virt` machine is invoked with:

- `-nographic` and the PL011 UART at `0x09000000` for serial output
- `virtio-sound-device` on QEMU's VirtIO MMIO transport, with
  `virtio-mmio.force-legacy=false` for the modern version-2 register layout
- `-semihosting`; the AArch64 bootstrap uses `SYS_EXIT_EXTENDED` so test
  failures return a nonzero QEMU status
