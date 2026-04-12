# Hardware Interrupts Implementation Plan

## 1. Objective

Implement a deterministic hardware timer interrupt path in VSOS using PIC remap
and PIT periodic ticks, while preserving existing interrupt and exception tests.

Success criteria:

- HI-FR-1..HI-FR-6 implemented.
- HI-T1..HI-T4 passing with stable markers.
- Existing suites (`check-all`, `check-pm-all`, `check-ih-all`) still green.

## 2. Work Breakdown

### Phase 0 - Design Lock

Goal: lock vector map, masks, marker contract, and test thresholds.

Tasks:

- Confirm PIC offsets: master 0x20, slave 0x28.
- Confirm v1 mask policy: unmask IRQ0 only.
- Confirm PIT test frequency (for example 100 Hz).
- Finalize markers: `HI_INIT_OK`, `HI_IRQ0_OK`, optional tick threshold marker.

Deliverables:

- Locked decisions written in spec.

Exit criteria:

- No unresolved design questions before coding.

### Phase 1 - PIC/PIT Bring-up (HI-M1)

Goal: initialize controller and timer safely.

Tasks:

- Add PIC remap helper (ICW1-4 sequence).
- Add PIC mask helper (master/slave IMR writes).
- Add PIT init helper (channel 0 mode/ divisor setup).
- Emit `HI_INIT_OK` after successful setup.

Deliverables:

- Bring-up helpers integrated in kernel init sequence with interrupts disabled.

Exit criteria:

- HI-T1 passes.

### Phase 2 - IRQ0 Runtime Path (HI-M2)

Goal: process real hardware timer IRQs through vector 0x20.

Tasks:

- Ensure vector 0x20 points to timer IRQ stub/handler.
- Increment tick counter in C handler.
- Send EOI to master PIC on every IRQ0.
- Emit `HI_IRQ0_OK` on first tick and deterministic marker at threshold.

Deliverables:

- Working runtime IRQ0 path with deterministic observability.

Exit criteria:

- HI-T2 and HI-T3 pass.

### Phase 3 - Automation and Regression

Goal: add repeatable local and CI checks.

Tasks:

- Add hardware interrupt test scripts under `tests/hardware-interrupts/scripts/`.
- Add Make targets `check-hi-t1`..`check-hi-t4` and `check-hi-all`.
- Include hardware-interrupt suite in aggregate workflow.
- Document expected markers and timeout tuning.

Deliverables:

- Stable local command flow + CI coverage.

Exit criteria:

- HI-T4 passes and regressions stay green.

## 3. Requirement Traceability

- HI-FR-1 -> PIC remap helper tasks.
- HI-FR-2 -> IRQ mask configuration tasks.
- HI-FR-3 -> PIT periodic configuration tasks.
- HI-FR-4 -> IRQ0 handler + EOI tasks.
- HI-FR-5 -> marker emission + capture tasks.
- HI-FR-6 -> failure variant and halt behavior tasks.

## 4. Risks and Mitigations

Risk: PIC initialization order mistakes can silently break IRQ delivery.
Mitigation: keep ICW sequence explicit and add init marker immediately after setup.

Risk: Missing EOI causes only first interrupt to fire.
Mitigation: enforce EOI write in IRQ0 path and test multi-tick threshold.

Risk: PIT frequency too high/low for test timeout.
Mitigation: choose documented fixed divisor and tune QEMU timeout deterministically.

Risk: New IRQ path regresses existing software interrupt tests.
Mitigation: keep legacy IH tests and run full regression after every change.

## 5. Definition of Done

- HI-FR-1..HI-FR-6 implemented.
- HI-T1..HI-T4 pass locally.
- Existing boot, PM, IH, VGA, and C-transition checks still pass.
- CI includes hardware-interrupt checks and publishes logs on failure.
