# VSOS

[![Bootloader CI](https://github.com/ccarlsson/vsos/actions/workflows/bootloader-ci.yml/badge.svg)](https://github.com/ccarlsson/vsos/actions/workflows/bootloader-ci.yml)

Very Simple Operating System is a minimal educational OS project focused on x86 BIOS boot fundamentals.

## Goals

- Teach core OS boot concepts with small, readable code.
- Keep modules isolated and independently testable.
- Provide deterministic behavior in QEMU for local and CI validation.

## Current Status

Three major phases completed and validated:

**Phase 1: Bootloader (T-1 through T-5):**

- Stage-1 bootloader with disk read and error handling
- Kernel handoff with drive number propagation
- All 5 bootloader tests passing (size, signature, handoff, disk failure, config failure)

**Phase 2: Protected Mode (PM-T-1 through PM-T-3):**

- Protected mode transition from real mode
- A20 line enable with failure path validation
- GDT and mode switch completeness checks
- All 3 protected-mode tests passing (successful transition, A20 failure, setup failure)

**Phase 3: Interrupt Handling (IH-T-1 through IH-T-4):**

- IDT allocation and initialization
- Exception handlers for vectors 0, 6, 13 (divide-by-zero, invalid opcode, general protection)
- Software interrupt handler (timer on vector 32)
- Multi-interrupt reproducibility and CI integration
- All 4 interrupt handling tests passing (basic handler, divide-by-zero, invalid opcode, multiple interrupts)

## Repository Layout

- `src/bootloader/stage1/`: stage-1 bootloader source
- `src/kernel/stage0/`: kernel with protected-mode and interrupt handling
- `tests/bootloader/scripts/`: bootloader validation scripts (T-1..T-5)
- `tests/protected-mode/scripts/`: protected-mode validation scripts (PM-T-1..PM-T-3)
- `tests/interrupt-handling/scripts/`: interrupt handling validation scripts (IH-T-1..IH-T-4)
- `specs/bootloader/`: bootloader spec, plan, tasks, and testing documentation
- `specs/protected-mode/`: protected-mode spec, plan, tasks, and testing documentation
- `specs/interrupt-handling/`: interrupt handling spec, plan, tasks, and testing documentation
- `specs/kernel-loading/`: kernel loading specs
- `build/`: generated binaries, images, and debug logs (ignored)
- `.github/workflows/`: CI workflows

## Prerequisites

- `nasm`
- `qemu-system-i386`
- `make`
- `timeout` (from coreutils)

## Quick Start

Run all validation suites:

```sh
make check-all check-pm-all check-ih-all
```

Run bootloader tests:

```sh
make check-all
```

Run protected-mode tests:

```sh
make check-pm-all
```

Run interrupt handling tests:

```sh
make check-ih-all
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
```

Adjust QEMU timeout if needed:

```sh
QEMU_TIMEOUT_SECONDS=5 make check-all check-pm-all check-ih-all
```

## Build Notes

Main generated artifacts:

- `build/boot.bin`
- `build/kernel.bin`
- `build/disk.img`

Debug logs:

- Bootloader: `build/qemu-debug.log`, `build/qemu-m2-debug.log`, `build/qemu-t3-debug.log`, `build/qemu-t4-debug.log`, `build/qemu-t5-debug.log`
- Protected-mode: `build/qemu-pm-t1-debug.log`, `build/qemu-pm-t2-debug.log`, `build/qemu-pm-t3-debug.log`
- Interrupt handling: `build/qemu-ih-t1-debug.log`, `build/qemu-ih-t2-debug.log`, `build/qemu-ih-t3-debug.log`, `build/qemu-ih-t4-debug.log`

## CI

GitHub Actions workflow:

- `.github/workflows/bootloader-ci.yml`

It runs on push and pull request, installs required packages, executes `make check-all check-pm-all check-ih-all`, and uploads debug artifacts when a run fails.

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
