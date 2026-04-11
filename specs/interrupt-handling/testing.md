# Interrupt Handling Testing Guide

This document defines local validation commands and expected markers for interrupt handling.

## Prerequisites

- `nasm`, `qemu-system-i386`, `make`, `coreutils`
- Run commands from repository root.

## Canonical Commands

- IH-T1: `make check-ih-t1`
- IH-T2: `make check-ih-t2`
- IH-T3: `make check-ih-t3`
- IH-T4: `make check-ih-t4`
- Full interrupt suite: `make check-ih-all`

## Expected Markers

All markers are emitted to QEMU debug port `0xE9` and captured by test scripts.

- IH-T1 (`check_qemu_ih_t1.sh`): expects `IH_OK`
- IH-T2 (`check_qemu_ih_t2.sh`): expects `IX_00`
- IH-T3 (`check_qemu_ih_t3.sh`): expects `IX_06`
- IH-T4 (`check_qemu_ih_t4.sh`): expects at least 3 occurrences of `IH_OK`

## Build Variants Used by Tests

- IH-T1: default kernel binary
- IH-T2: `-DEXCEPTION_TEST=1` (divide-by-zero)
- IH-T3: `-DEXCEPTION_TEST=2` (`ud2` invalid opcode)
- IH-T4: `-DINTERRUPT_TEST_MODE=1` (three software `int 0x20` dispatches)

## Regression Recommendations

Run these after interrupt changes:

- `make check-pm-all`
- `make check-all`

## CI Coverage

CI executes:

- `make check-all check-pm-all check-ih-all`

and uploads `build/*.log`, `build/*.bin`, `build/*.img` on failure.
