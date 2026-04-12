# Hardware Interrupts Testing Guide

This document defines the local validation flow for the hardware-interrupts
slice and its expected marker contract.

## Prerequisites

- `nasm`, `qemu-system-i386`, `make`, `coreutils`
- Run commands from repository root.

## Canonical Commands

- HI-T1: `make check-hi-t1`
- HI-T2: `make check-hi-t2`
- HI-T3: `make check-hi-t3`
- HI-T4: `make check-hi-t4`
- Full hardware interrupt suite: `make check-hi-all`

Note: these targets are introduced by this slice and may not exist until
implementation tasks are completed.

## Expected Markers

All markers are emitted through debug port `0xE9` and captured in QEMU log
files by test scripts.

- HI-T1 expects: `HI_INIT_OK`
- HI-T2 expects: `HI_IRQ0_OK`
- HI-T3 expects: deterministic threshold marker `HI_TICKS_3`
- HI-T4 expects: `HI_IRQ0_OK` and `HI_TICKS_3`, with no unexpected exception markers

## Suggested Build/Test Variants

- Default variant: real PIT IRQ0 path with IRQ0 unmasked

## Phase 0 Locked Runtime Values

- PIC remap offsets: master 0x20, slave 0x28
- IRQ masks after init: master 0xFE, slave 0xFF
- PIT setup: command 0x34, divisor 11931 (~100 Hz)

## Regression Recommendations

Run these after hardware interrupt changes:

- `make check-ih-all`
- `make check-pm-all`
- `make check-vga-all`
- `make check-all`

## CI Coverage

CI should execute:

- `make check-all check-pm-all check-ih-all check-hi-all`

and upload debug artifacts on failure.
