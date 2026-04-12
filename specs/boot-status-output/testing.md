# Boot Status Output Testing Guide

This document defines how to validate human-readable boot progress output while
preserving the existing automated marker-based workflow.

## Prerequisites

- `nasm`, `qemu-system-i386`, `make`, `coreutils`
- Run commands from repository root.

## Manual Validation

Boot with a visible QEMU window:

```sh
make clean && make disk-image && qemu-system-i386 -drive file=build/disk.img,format=raw,if=floppy
```

Confirm the screen shows readable staged output from:

- bootloader start
- kernel loading / handoff
- protected-mode / kernel entry
- VGA / early kernel progress

## Regression Validation

Run existing automated suites after visible output changes:

```sh
make check-all
make check-pm-all
make check-ih-all
make check-hi-all
make check-vga-all
```

## Expected Result

- Human-readable messages are visible in QEMU.
- Existing debug-port markers remain unchanged.
- Automated suites continue to pass.
