# VSOS

[![Bootloader CI](https://github.com/YOUR_ORG/YOUR_REPO/actions/workflows/bootloader-ci.yml/badge.svg)](https://github.com/YOUR_ORG/YOUR_REPO/actions/workflows/bootloader-ci.yml)

Replace `YOUR_ORG/YOUR_REPO` with your GitHub repository path after push.

Very Simple Operating System is a minimal educational OS project focused on x86 BIOS boot fundamentals.

## Goals

- Teach core OS boot concepts with small, readable code.
- Keep modules isolated and independently testable.
- Provide deterministic behavior in QEMU for local and CI validation.

## Current Status

Bootloader stage-1 and a minimal kernel handoff path are implemented and validated.

Implemented test coverage:

- T-1: boot sector size/signature validation
- T-2: successful kernel handoff path
- T-3: disk read failure path (`E1`)
- T-4: invalid configuration path (`E2`)
- T-5: boot drive propagation (`DL`) across handoff

## Repository Layout

- `src/bootloader/stage1/`: stage-1 bootloader source
- `src/kernel/stage0/`: minimal kernel payload used for bring-up and tests
- `tests/bootloader/scripts/`: bootloader validation scripts (T-1..T-5)
- `specs/bootloader/`: spec, plan, tasks, and testing documentation
- `build/`: generated binaries, images, and debug logs (ignored)
- `.github/workflows/`: CI workflows

## Prerequisites

- `nasm`
- `qemu-system-i386`
- `make`
- `timeout` (from coreutils)

## Quick Start

Run the full validation suite:

```sh
make check-all
```

Run individual tests:

```sh
make check-t1
make check-t2
make check-t3
make check-t4
make check-t5
```

Adjust QEMU timeout if needed:

```sh
QEMU_TIMEOUT_SECONDS=5 make check-all
```

## Build Notes

Main generated artifacts:

- `build/boot.bin`
- `build/kernel.bin`
- `build/disk.img`

Debug logs:

- `build/qemu-debug.log`
- `build/qemu-m2-debug.log`
- `build/qemu-t3-debug.log`
- `build/qemu-t4-debug.log`
- `build/qemu-t5-debug.log`

## CI

GitHub Actions workflow:

- `.github/workflows/bootloader-ci.yml`

It runs on push and pull request, installs required packages, executes `make check-all`, and uploads debug artifacts when a run fails.

## Specs and Planning

Bootloader documentation:

- `specs/bootloader/spec.md`
- `specs/bootloader/plan.md`
- `specs/bootloader/tasks.md`
- `specs/bootloader/testing.md`
