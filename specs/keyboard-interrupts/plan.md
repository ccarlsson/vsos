# Keyboard Interrupts Implementation Plan

## 1. Objective

Implement the first PS/2 keyboard IRQ path in VSOS while preserving the
existing timer IRQ, exception handling, and marker-based test workflow.

Success criteria:

- KBD-FR-1..KBD-FR-7 implemented.
- KBD-T1..KBD-T4 passing with stable markers.
- Existing suites (`check-hi-all`, `check-ih-all`, `check-all`) still green.

## 2. Work Breakdown

### Phase 0 - Design Lock

Goal: lock vector, mask policy, scancode contract, and test input.

Tasks:

- Confirm keyboard vector `0x21` after PIC remap.
- Confirm v1 PIC mask policy for keyboard-enabled variant.
- Lock the first test key and expected make code.
- Finalize markers: `KBD_INIT_OK`, `KBD_IRQ1_OK`, `KBD_SC_OK`.

Deliverables:

- Locked decisions written in spec.

Exit criteria:

- No unresolved design questions before coding.

Status: Complete.

Phase 0 locked values:

- Keyboard IRQ line: IRQ1 -> vector `0x21`.
- PIC mask policy in keyboard-enabled variant: master `0xFC`, slave `0xFF`.
- Test key: `a`.
- Expected make code: `0x1E`.
- Marker contract: `KBD_INIT_OK`, `KBD_IRQ1_OK`, `KBD_SC_OK`.

### Phase 1 - IRQ1 Bring-up (KBD-M1)

Goal: install a keyboard interrupt path without regressing timer IRQ0.

Tasks:

- Add IRQ1 IDT gate and assembly stub.
- Extend PIC mask helper or variant configuration to unmask IRQ1.
- Add kernel state for last keyboard scancode and first-key bookkeeping.
- Emit `KBD_INIT_OK` after successful setup.

Deliverables:

- Keyboard-enabled runtime path reachable from QEMU-injected input.

Exit criteria:

- KBD-T1 passes.

### Phase 2 - Scancode Runtime Path (KBD-M2)

Goal: process one deterministic keyboard event through IRQ1.

Tasks:

- Read port `0x60` in the keyboard handler.
- Record last observed scancode in kernel state.
- Emit `KBD_IRQ1_OK` on first observed keyboard interrupt.
- Validate locked scancode and emit `KBD_SC_OK`.
- Send EOI on every keyboard IRQ1.

Deliverables:

- Working raw keyboard interrupt path with deterministic observability.

Exit criteria:

- KBD-T2 and KBD-T3 pass.

### Phase 3 - Automation and Regression

Goal: add repeatable local and CI checks.

Tasks:

- Add keyboard interrupt test scripts under `tests/keyboard-interrupts/scripts/`.
- Add Make targets `check-kbd-t1`..`check-kbd-t4` and `check-kbd-all`.
- Include keyboard suite in aggregate workflow.
- Document QEMU input injection and expected markers.

Deliverables:

- Stable local command flow + CI coverage.

Exit criteria:

- KBD-T4 passes and regressions stay green.

## 3. Requirement Traceability

- KBD-FR-1 -> IRQ1 IDT gate/stub tasks.
- KBD-FR-2 -> PIC mask configuration tasks.
- KBD-FR-3 -> raw scancode read tasks.
- KBD-FR-4 -> marker emission and capture tasks.
- KBD-FR-5 -> tiny decode/echo tasks.
- KBD-FR-6 -> EOI tasks.
- KBD-FR-7 -> halt-safe default behavior + regression tasks.

## 4. Risks and Mitigations

Risk: QEMU key injection may be less deterministic than timer-only tests.
Mitigation: lock one injected key and assert raw scancode, not rich text input behavior.

Risk: Adding IRQ1 may accidentally regress timer IRQ0 handling.
Mitigation: keep IRQ0 active in coexistence test and assert timer liveness marker.

Risk: Break-code or modifier bytes may complicate the first implementation.
Mitigation: keep v1 scoped to a single known make code and ignore unsupported bytes.

Risk: Missing EOI can stall later keyboard interrupts.
Mitigation: enforce EOI in IRQ1 path and keep repeated manual test flow available.

## 5. Definition of Done

- KBD-FR-1..KBD-FR-7 implemented.
- KBD-T1..KBD-T4 pass locally.
- Existing boot, PM, IH, HI, VGA, and C-transition checks still pass.
- CI includes keyboard-interrupt checks and publishes logs on failure.
