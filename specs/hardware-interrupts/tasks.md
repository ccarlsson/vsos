# Hardware Interrupts Task List

This checklist translates `spec.md` into implementation-ready work.

## Phase 0 - Design Lock

- [x] Confirm and document PIC vector offsets (0x20/0x28).
- [x] Confirm and document v1 IRQ mask policy (IRQ0 only).
  - master mask = 0xFE, slave mask = 0xFF
- [x] Confirm and document PIT target frequency/divisor.
  - PIT command = 0x34, divisor = 11931 (~100 Hz)
- [x] Lock marker strings and test thresholds.
  - `HI_INIT_OK`, `HI_IRQ0_OK`, `HI_TICKS_3`, `HI_INIT_FAIL`

## Phase 1 - PIC/PIT Bring-up (HI-M1)

### PIC

- [x] Add PIC command/data port constants.
- [x] Implement PIC remap routine (ICW1-ICW4 sequence).
- [x] Implement PIC mask routine for master/slave IMRs.
- [x] Mask all IRQ lines except IRQ0 in v1.

### PIT

- [x] Add PIT command/channel constants.
- [x] Program PIT channel 0 periodic mode.
- [x] Set fixed divisor for deterministic tick interval.

### Integration

- [x] Run PIC/PIT init before `sti`.
- [x] Emit `HI_INIT_OK` marker after successful setup.

### Validation

- [x] HI-T1: init marker appears in QEMU debug log.

## Phase 2 - IRQ0 Runtime Path (HI-M2)

### Handler path

- [x] Verify IDT vector 0x20 maps to IRQ0 stub.
- [x] Increment tick counter in IRQ0 C handler.
- [x] Emit `HI_IRQ0_OK` on first observed hardware tick.
- [x] Send EOI to master PIC for every IRQ0.
- [x] Return with `iret` and keep system alive.

### Deterministic threshold

- [x] Add bounded tick threshold marker (for example at 3 ticks).
- [x] Keep marker output concise and stable across runs.

### Validation

- [x] HI-T2: first hardware tick detected (`HI_IRQ0_OK`).
- [x] HI-T3: threshold tick marker observed.

## Phase 3 - Test Automation and Workflow

### Scripts

- [x] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t1.sh`.
- [x] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t2.sh`.
- [x] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t3.sh`.
- [x] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t4.sh`.

### Makefile

- [x] Add `check-hi-t1`, `check-hi-t2`, `check-hi-t3`, `check-hi-t4`.
- [x] Add aggregate `check-hi-all`.
- [x] Include hardware-interrupt suite in `check-all`.

### CI and docs

- [x] Update CI workflow to run `check-hi-all`.
- [x] Upload HI debug artifacts on CI failure.
- [x] Keep spec/plan/testing docs synchronized with implementation.

### Validation

- [x] HI-T4: no unexpected IRQ marker noise with non-IRQ0 lines masked.
- [x] Existing suites remain green: boot, PM, IH, VGA, C transition.

## Requirement Traceability Checklist

- [x] HI-FR-1 satisfied.
- [x] HI-FR-2 satisfied.
- [x] HI-FR-3 satisfied.
- [x] HI-FR-4 satisfied.
- [x] HI-FR-5 satisfied.
- [x] HI-FR-6 satisfied.

## Done Criteria

- [x] HI-T1..HI-T4 pass locally.
- [x] `make check-hi-all` available and stable.
- [x] CI includes hardware-interrupt checks.
- [x] Marker contract is deterministic and documented.
