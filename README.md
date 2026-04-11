# VSOS

[![Bootloader CI](https://github.com/ccarlsson/vsos/actions/workflows/bootloader-ci.yml/badge.svg)](https://github.com/ccarlsson/vsos/actions/workflows/bootloader-ci.yml)

Very Simple Operating System is a minimal educational OS project focused on x86 BIOS boot fundamentals.

## Goals

- Teach core OS boot concepts with small, readable code.
- Keep modules isolated and independently testable.
- Provide deterministic behavior in QEMU for local and CI validation.

## Current Status

The repo now boots a mixed assembly + freestanding C kernel while preserving the raw boot artifact contract.

Implemented and validated:

- Bootloader tests T-1 through T-5
- Protected-mode tests PM-T-1 through PM-T-3
- Interrupt-handling tests IH-T-1 through IH-T-4
- VGA console tests VGA-T-1 through VGA-T-6
- C kernel transition phases 1 through 3

Current kernel structure:

- Assembly keeps the real-mode bootstrap, mode switch, and raw ISR entry stubs.
- C owns the first protected-mode kernel body, VGA console logic, IDT setup helpers, and interrupt bookkeeping helpers.
- The final boot artifact is still `build/kernel.bin` loaded by the existing bootloader from LBA 1.

## Repository Layout

- `src/bootloader/stage1/`: stage-1 bootloader source
- `src/kernel/stage0/`: bootstrap assembly, protected-mode entry, and ISR stubs
- `src/kernel/stage1/`: freestanding C kernel code (`kmain`, VGA console, IDT helpers, interrupt helpers)
- `include/kernel/`: freestanding kernel headers shared by C sources
- `tests/bootloader/scripts/`: bootloader validation scripts (T-1..T-5)
- `tests/protected-mode/scripts/`: protected-mode validation scripts (PM-T-1..PM-T-3)
- `tests/interrupt-handling/scripts/`: interrupt handling validation scripts (IH-T-1..IH-T-4)
- `tests/vga-console/scripts/`: VGA console validation scripts (VGA-T-1..VGA-T-6)
- `tests/c-kernel-transition/scripts/`: mixed-language kernel transition checks
- `specs/bootloader/`: bootloader spec, plan, tasks, and testing documentation
- `specs/c-kernel-transition/`: mixed asm + C kernel transition spec, plan, tasks, and testing documentation
- `specs/protected-mode/`: protected-mode spec, plan, tasks, and testing documentation
- `specs/interrupt-handling/`: interrupt handling spec, plan, tasks, and testing documentation
- `specs/vga-console/`: VGA console spec, plan, tasks, and testing documentation
- `specs/kernel-loading/`: kernel loading specs
- `build/`: generated binaries, images, and debug logs (ignored)
- `.github/workflows/`: CI workflows

## Prerequisites

- `nasm`
- `qemu-system-i386`
- `make`
- `timeout` (from coreutils)
- `gcc` with 32-bit freestanding support (`gcc-multilib` on Debian/Ubuntu)
- `ld` and `objcopy` from GNU binutils

## Quick Start

Verify toolchain support for the mixed kernel build:

```sh
make check-c-toolchain
```

Run the full regression suite:

```sh
make check-all
```

Build the bootable artifacts only:

```sh
make all
```

Run focused subsystem suites:

```sh
make check-pm-all
make check-ih-all
make check-vga-all
make check-c-t1
```

Run individual tests:

```sh
make check-boot
make check-qemu-m1
make check-qemu-m2
make check-qemu-t3
make check-qemu-t4
make check-qemu-t5
make check-pm-t1
make check-pm-t2
make check-pm-t3
make check-ih-t1
make check-ih-t2
make check-ih-t3
make check-ih-t4
make check-vga-t1
make check-vga-t2
make check-vga-t3
make check-vga-t4
make check-vga-t5
make check-vga-t6
make check-c-t1
```

Adjust QEMU timeout if needed:

```sh
QEMU_TIMEOUT_SECONDS=5 make check-all
```

## Build Notes

Main generated artifacts:

- `build/boot.bin`
- `build/kernel.elf`
- `build/kernel.bin`
- `build/disk.img`

Debug logs:

- Bootloader: `build/qemu-debug.log`, `build/qemu-m2-debug.log`, `build/qemu-t3-debug.log`, `build/qemu-t4-debug.log`, `build/qemu-t5-debug.log`
- Protected-mode: `build/qemu-pm-t1-debug.log`, `build/qemu-pm-t2-debug.log`, `build/qemu-pm-t3-debug.log`
- Interrupt handling: `build/qemu-ih-t1-debug.log`, `build/qemu-ih-t2-debug.log`, `build/qemu-ih-t3-debug.log`, `build/qemu-ih-t4-debug.log`
- VGA console: `build/qemu-vga-t1-debug.log`, `build/qemu-vga-t2-debug.log`, `build/qemu-vga-t3-debug.log`, `build/qemu-vga-t4-debug.log`, `build/qemu-vga-t5-debug.log`, `build/qemu-vga-t6-debug.log`
- C transition: `build/qemu-c-t1-debug.log`

## Mixed Kernel Layout

The kernel is intentionally split across small layers:

- `src/kernel/stage0/kernel.asm`
  real-mode entry, A20 enable/verify, GDT setup, protected-mode transition,
  protected-mode register/stack setup, raw ISR/exception stubs, and the debug
  output shim used by C

- `src/kernel/stage1/kmain.c`
  first C entry after protected-mode setup, subsystem bring-up sequencing, and
  test marker emission for migrated C paths

- `src/kernel/stage1/vga.c`
  VGA console init/output/wrap/scroll logic

- `src/kernel/stage1/idt.c`
  IDT gate population and IDTR load

- `src/kernel/stage1/interrupts.c`
  higher-level interrupt/exception bookkeeping and marker emission

This keeps exact hardware-entry semantics in assembly while moving extendable runtime logic into C.

## CI

GitHub Actions workflow:

- `.github/workflows/bootloader-ci.yml`

It runs on push and pull request, installs NASM, QEMU, GNU make/coreutils, GCC multilib, and binutils, executes `make check-c-toolchain` and then `make check-all`, and uploads debug artifacts when a run fails.

## Specs and Planning

Complete documentation organized by phase:

**Bootloader:**

- `specs/bootloader/spec.md`
- `specs/bootloader/plan.md`
- `specs/bootloader/tasks.md`
- `specs/bootloader/testing.md`

**Protected Mode:**

- `specs/protected-mode/spec.md`
- `specs/protected-mode/plan.md`
- `specs/protected-mode/tasks.md`
- `specs/protected-mode/testing.md`

**Interrupt Handling:**

- `specs/interrupt-handling/spec.md`
- `specs/interrupt-handling/plan.md`
- `specs/interrupt-handling/tasks.md`
- `specs/interrupt-handling/testing.md`

**Kernel Loading:**

- `specs/kernel-loading/spec.md`
- `specs/kernel-loading/plan.md`
- `specs/kernel-loading/tasks.md`

**C Kernel Transition:**

- `specs/c-kernel-transition/spec.md`
- `specs/c-kernel-transition/plan.md`
- `specs/c-kernel-transition/tasks.md`
- `specs/c-kernel-transition/testing.md`
