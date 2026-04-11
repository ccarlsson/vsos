# Protected Mode Test Guide

This guide documents the reproducible local workflow for PM-T1, PM-T2, and PM-T3.

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
- Example override: QEMU_TIMEOUT_SECONDS=5 make check-pm-all

## Single-Command Execution

Run full PM suite:

- make check-pm-all

## Individual Tests

- PM-T1 (positive transition): make check-pm-t1
- PM-T2 (A20 failure): make check-pm-t2
- PM-T3 (selector/GDT failure): make check-pm-t3

## Expected Outputs

Success outputs:

- PM-T1: PASS: protected-mode transition verified (PM_OK)
- PM-T2: PASS: protected-mode A20 failure path verified (P1)
- PM-T3: PASS: protected-mode transition setup failure path verified (P2)

Positive-path marker:

- Protected-mode success: PM_OK

Failure-path markers:

- A20 verification failure: P1
- Selector/GDT config validation failure: P2

## Test Variants

PM-T1 uses normal kernel build (`build/kernel.bin`) with standard configuration.

PM-T2 uses kernel built with FORCE_A20_FAILURE=1 to short-circuit A20 verification.

PM-T3 uses kernel built with CODE_SEL=0x18 (invalid selector) to trigger config validation failure.

## Artifacts

Primary artifacts:

- build/kernel.bin
- build/kernel.pm.a20fail.bin
- build/kernel.pm.badsel.bin
- build/disk.img
- build/disk-pm-t2.img
- build/disk-pm-t3.img

Debug logs:

- build/qemu-pm-t1-debug.log
- build/qemu-pm-t2-debug.log
- build/qemu-pm-t3-debug.log

## CI

Workflow file:

- .github/workflows/bootloader-ci.yml

Behavior:

- Runs on push and pull_request.
- Installs nasm and qemu-system-x86.
- Executes make check-all and make check-pm-all.
- Uploads build logs and images as artifacts on both bootloader and protected-mode failures.

## Design Notes

Protected mode transition occurs in kernel early code after real-mode handoff. Transition location is configurable via NASM defines:

- CODE_SEL: 32-bit code segment selector (default: 0x08)
- DATA_SEL: 32-bit data segment selector (default: 0x10)
- PM_STACK_TOP: 32-bit stack top ESP (default: 0x0009FC00)
- FORCE_A20_FAILURE: 1 to force A20 verify to fail (default: 0)

GDT is minimal (null, code, data) with flat descriptors and 4 GiB limits. A20 verification uses physical address wrapping test at 0x0500 / 0xFFFF:0x0510. All markers are emitted to QEMU debug port 0xE9 for deterministic capture.
