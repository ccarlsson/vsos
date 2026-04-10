# Bootloader Test Guide

This guide documents the reproducible local workflow for T-1 through T-5.

## Prerequisites

- nasm on PATH
- qemu-system-i386 on PATH
- timeout utility on PATH

## Fixed Runtime Parameters

All QEMU-based tests use:

- qemu-system-i386
- -drive file=IMAGE_PATH,format=raw,if=floppy
- -display none
- -monitor none
- -serial none
- -debugcon file:LOG_PATH
- -global isa-debugcon.iobase=0xe9
- -no-reboot
- -no-shutdown

Timeout behavior:

- Controlled by QEMU_TIMEOUT_SECONDS (default: 3)
- Example override: QEMU_TIMEOUT_SECONDS=5 make check-t2

## Single-Command Execution

Run full suite:

- make check-all
- or sh tests/bootloader/scripts/check_all.sh

## Individual Tests

- T-1: make check-t1
- T-2: make check-t2
- T-3: make check-t3
- T-4: make check-t4
- T-5: make check-t5

## CI

Workflow file:

- .github/workflows/bootloader-ci.yml

Behavior:

- Runs on push and pull_request.
- Installs nasm and qemu-system-x86.
- Executes make check-all.
- Uploads build logs and images as artifacts when a job fails.

## Expected Outputs

Success outputs:

- T-1: PASS: build/boot.bin is 512 bytes and has signature 0x55AA
- T-2: PASS: QEMU kernel handoff verified (KERNEL_OK)
- T-3: PASS: disk read failure path verified (E1)
- T-4: PASS: invalid configuration failure path verified (E2)
- T-5: PASS: boot drive propagation verified (bootloader=HEX kernel=HEX)

Failure markers:

- Disk read failure path marker: E1
- Invalid config path marker: E2
- Positive path marker: KERNEL_OK

## Artifacts

Primary artifacts:

- build/boot.bin
- build/kernel.bin
- build/disk.img

Debug logs:

- build/qemu-debug.log
- build/qemu-m2-debug.log
- build/qemu-t3-debug.log
- build/qemu-t4-debug.log
- build/qemu-t5-debug.log
