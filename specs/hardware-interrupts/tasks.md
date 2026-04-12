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

- [ ] Verify IDT vector 0x20 maps to IRQ0 stub.
- [ ] Increment tick counter in IRQ0 C handler.
- [ ] Emit `HI_IRQ0_OK` on first observed hardware tick.
- [ ] Send EOI to master PIC for every IRQ0.
- [ ] Return with `iret` and keep system alive.

### Deterministic threshold

- [ ] Add bounded tick threshold marker (for example at 3 ticks).
- [ ] Keep marker output concise and stable across runs.

### Validation

- [ ] HI-T2: first hardware tick detected (`HI_IRQ0_OK`).
- [ ] HI-T3: threshold tick marker observed.

## Phase 3 - Test Automation and Workflow

### Scripts

- [x] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t1.sh`.
- [ ] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t2.sh`.
- [ ] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t3.sh`.
- [ ] Add `tests/hardware-interrupts/scripts/check_qemu_hi_t4.sh`.

### Makefile

- [ ] Add `check-hi-t1`, `check-hi-t2`, `check-hi-t3`, `check-hi-t4`.
- [x] Add aggregate `check-hi-all`.
- [ ] Include hardware-interrupt suite in `check-all`.

### CI and docs

- [ ] Update CI workflow to run `check-hi-all`.
- [ ] Upload HI debug artifacts on CI failure.
- [ ] Keep spec/plan/testing docs synchronized with implementation.

### Validation

- [ ] HI-T4: no unexpected IRQ marker noise with non-IRQ0 lines masked.
- [ ] Existing suites remain green: boot, PM, IH, VGA, C transition.

## Requirement Traceability Checklist

- [ ] HI-FR-1 satisfied.
- [ ] HI-FR-2 satisfied.
- [ ] HI-FR-3 satisfied.
- [ ] HI-FR-4 satisfied.
- [ ] HI-FR-5 satisfied.
- [ ] HI-FR-6 satisfied.

## Done Criteria

- [ ] HI-T1..HI-T4 pass locally.
- [ ] `make check-hi-all` available and stable.
- [ ] CI includes hardware-interrupt checks.
- [ ] Marker contract is deterministic and documented.
