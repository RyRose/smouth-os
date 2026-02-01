# stdk

In-tree forks of std library modules.

## Dwarf

This is a copy of std.debug.Dwarf in order to support freestanding environments.
It primarily just ensures that 0x0 is supported as a valid address.

<https://github.com/ziglang/zig/issues/1953>

## debug

This contain copies of debug facilities for logger error traces.
