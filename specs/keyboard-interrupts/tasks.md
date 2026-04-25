# Keyboard Interrupts Task List

This checklist translates `spec.md` into implementation-ready work.

## Phase 0 - Design Lock

- [x] Confirm and document keyboard vector `0x21`.
- [x] Confirm and document v1 PIC mask policy for keyboard-enabled variant.
  - master mask = `0xFC`, slave mask = `0xFF`
- [x] Lock the first deterministic test key and expected make code.
  - key = `a`, make code = `0x1E`
- [x] Lock marker strings.
  - `KBD_INIT_OK`, `KBD_IRQ1_OK`, `KBD_SC_OK`

## Phase 1 - IRQ1 Bring-up (KBD-M1)

### IDT and stubs

- [ ] Add IRQ1 interrupt stub in assembly.
- [ ] Install vector `0x21` in the IDT.
- [ ] Keep IRQ0/timer vector `0x20` unchanged.

### PIC configuration

- [ ] Extend PIC mask setup to support a keyboard-enabled variant.
- [ ] Keep all non-IRQ0/non-IRQ1 lines masked in v1.

### Integration

- [ ] Add kernel state for last observed scancode.
- [ ] Add first-key bookkeeping as needed for deterministic markers.
- [ ] Emit `KBD_INIT_OK` after successful keyboard-path setup.

### Validation

- [ ] KBD-T1: init marker appears in QEMU debug log.

## Phase 2 - Scancode Runtime Path (KBD-M2)

### Handler path

- [ ] Read one byte from port `0x60` in keyboard IRQ handler.
- [ ] Record the raw scancode in kernel state.
- [ ] Emit `KBD_IRQ1_OK` on first observed keyboard IRQ.
- [ ] Compare against locked expected make code and emit `KBD_SC_OK`.
- [ ] Send EOI to master PIC for every IRQ1.
- [ ] Return with `iret` and keep system alive.

### Optional tiny decode

- [ ] Decide whether to echo locked subset keys to VGA.
- [ ] If implemented, support only documented subset and ignore unsupported codes.

### Validation

- [ ] KBD-T2: first keyboard IRQ detected (`KBD_IRQ1_OK`).
- [ ] KBD-T3: expected scancode captured (`KBD_SC_OK`).

## Phase 3 - Test Automation and Workflow

### Scripts

- [ ] Add `tests/keyboard-interrupts/scripts/check_qemu_kbd_t1.sh`.
- [ ] Add `tests/keyboard-interrupts/scripts/check_qemu_kbd_t2.sh`.
- [ ] Add `tests/keyboard-interrupts/scripts/check_qemu_kbd_t3.sh`.
- [ ] Add `tests/keyboard-interrupts/scripts/check_qemu_kbd_t4.sh`.

### Makefile

- [ ] Add `check-kbd-t1`, `check-kbd-t2`, `check-kbd-t3`, `check-kbd-t4`.
- [ ] Add aggregate `check-kbd-all`.
- [ ] Include keyboard suite in broader workflow when implementation lands.

### CI and docs

- [ ] Update CI workflow to run `check-kbd-all`.
- [ ] Upload keyboard debug artifacts on CI failure.
- [ ] Keep spec/plan/testing docs synchronized with implementation.

### Validation

- [ ] KBD-T4: keyboard IRQ coexists with timer IRQ0 and no unexpected exception markers.
- [ ] Existing suites remain green: boot, PM, IH, HI, VGA, C transition.

## Requirement Traceability Checklist

- [ ] KBD-FR-1 satisfied.
- [ ] KBD-FR-2 satisfied.
- [ ] KBD-FR-3 satisfied.
- [ ] KBD-FR-4 satisfied.
- [ ] KBD-FR-5 satisfied.
- [ ] KBD-FR-6 satisfied.
- [ ] KBD-FR-7 satisfied.

## Done Criteria

- [ ] KBD-T1..KBD-T4 pass locally.
- [ ] `make check-kbd-all` available and stable.
- [ ] CI includes keyboard-interrupt checks.
- [ ] Marker contract is deterministic and documented.
