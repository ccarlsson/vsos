# Hardware Interrupts Testing Guide

This document defines the local validation flow for the hardware-interrupts
slice and its expected marker contract.

## Prerequisites

- `nasm`, `qemu-system-i386`, `make`, `coreutils`
- Run commands from repository root.

## Canonical Commands (Planned)

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
- HI-T3 expects: deterministic threshold marker (for example `HI_TICKS_3`)
- HI-T4 expects: no unexpected IRQ marker noise while IRQ0 remains functional

## Suggested Build/Test Variants

- Default variant: real PIT IRQ0 path with IRQ0 unmasked
- Negative variant (optional): intentionally broken PIC/PIT init to verify
  failure marker + halt behavior

## Regression Recommendations

Run these after hardware interrupt changes:

- `make check-ih-all`
- `make check-pm-all`
- `make check-vga-all`
- `make check-all`

## CI Coverage (Target State)

CI should execute:

- `make check-all check-pm-all check-ih-all check-hi-all`

and upload debug artifacts on failure.
