# Keyboard Interrupts Testing Guide

This document defines the local validation flow for the keyboard-interrupts
slice and its expected marker contract.

## Prerequisites

- `nasm`, `qemu-system-i386`, `make`, `coreutils`
- Run commands from repository root.

## Canonical Commands

- KBD-T1: `make check-kbd-t1`
- KBD-T2: `make check-kbd-t2`
- KBD-T3: `make check-kbd-t3`
- KBD-T4: `make check-kbd-t4`
- Full keyboard interrupt suite: `make check-kbd-all`

Note: these targets are introduced by this slice and may not exist until
implementation tasks are completed.

## Expected Markers

All markers are emitted through debug port `0xE9` and captured in QEMU log
files by test scripts.

- KBD-T1 expects: `KBD_INIT_OK`
- KBD-T2 expects: `KBD_IRQ1_OK`
- KBD-T3 expects: `KBD_SC_OK`
- KBD-T4 expects: `KBD_IRQ1_OK` and existing timer liveness marker such as `HI_TICKS_3`, with no unexpected exception markers

## Suggested Build/Test Variants

- Default keyboard-enabled variant: IRQ0 and IRQ1 both unmasked
- Locked first-key input: `a`

## Phase 0 Locked Runtime Values

- Keyboard IRQ line: IRQ1
- Keyboard vector: `0x21`
- PIC masks in keyboard-enabled variant: master `0xFC`, slave `0xFF`
- Data port read: `0x60`
- Locked test make code: `0x1E`

## Suggested QEMU Input Strategy

Tests should inject a single deterministic key event after boot using QEMU's
input/monitor facilities.

Recommended contract:

- Inject key: `a`
- Wait until keyboard init and timer-liveness markers are present before sending the key
- Assert raw make code behavior, not rich terminal semantics
- Keep the test harness headless and bounded by timeout

Exact injection mechanism may vary by script strategy, but the injected event
must be deterministic and documented in the script.

## Regression Recommendations

Run these after keyboard interrupt changes:

- `make check-hi-all`
- `make check-ih-all`
- `make check-vga-all`
- `make check-all`

## CI Coverage

CI should execute:

- `make check-all check-pm-all check-ih-all check-hi-all check-kbd-all`

and upload debug artifacts on failure.
