# AGENTS.md

Guidance for AI agents working in this repository.

## Project overview

`smouth-os` is a bare-metal hobby OS kernel written in Zig. It currently
targets 32-bit x86 and runs under QEMU for both development and testing. The
project is designed to be extensible to additional architectures over time.

## Repository layout

```
assets/    – binary assets embedded into the kernel (WAV files, etc.)
src/
  main.zig   – kernel entry point and test runner
  arch/      – architecture-specific code (one sub-directory per arch)
  kernel/    – architecture-independent kernel code
embed.zig  – embeds src, std, and assets files as pub consts; importable as the "embed" module
```

## Architecture vs kernel code

- **`src/arch/<arch>/`** — everything specific to one architecture: boot
  entry, CPU instructions, I/O port access, linker scripts, low-level hardware
  drivers that cannot be shared across architectures.
- **`src/kernel/`** — code that is (or could be) useful on more than one
  architecture: higher-level drivers, data structures, utilities, and init
  sequences that call into arch abstractions.

When adding new code, prefer `src/kernel/` unless it is inherently tied to a
specific architecture.

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
```

## Testing

| Command | What it runs |
|---|---|
| `zig build test` | Hosted unit tests (no QEMU required) |
| `zig build test-x86` | Tests under `src/kernel/` only, in QEMU on x86 |
| `zig build test-arch-x86` | Tests under `src/arch/` only, in QEMU on x86 |
| `zig build test-all` | All of the above |

Run `zig build test-all` after completing all changes.

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
  disables SIMD and uses soft-float.

## QEMU environment

QEMU is invoked with:

- `-nographic` — serial output only
- `isa-debug-exit` at port `0xF4` — non-zero write exits QEMU with error
- `pcspk-audiodev` — PC speaker audio
- `intel-hda` + `hda-duplex` — HD Audio device
- `virtio-sound-pci` — VirtIO sound device

The audio backend is `coreaudio` on macOS and `none` elsewhere.
