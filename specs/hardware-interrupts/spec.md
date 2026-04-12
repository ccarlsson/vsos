# Hardware Interrupts Specification

## 1. Purpose

This module defines the first real hardware interrupt path in VSOS using the
legacy 8259 PIC and PIT timer in 32-bit protected mode.

The intent is to keep the first hardware IRQ milestone minimal, deterministic,
and educational:

- remap PIC vectors,
- unmask only IRQ0,
- configure PIT periodic ticks,
- handle timer IRQ through IDT vector 0x20,
- emit deterministic markers for test automation.

## 2. Context

Current VSOS status:

- Bootloader, kernel loading, and protected-mode transition are implemented.
- IDT setup and software interrupt validation (`int 0x20`) are implemented.
- Basic exception handlers (0, 6, 13) are implemented.

This slice adds real external interrupt delivery from hardware timer IRQ0.

## 3. Scope

In scope:

- PIC remap to vectors 0x20-0x2F
- IRQ mask setup (only IRQ0 unmasked for v1)
- PIT channel 0 programming for periodic mode
- Timer IRQ0 handler entry and return path (`iret`)
- End-of-interrupt (EOI) signaling to PIC
- Deterministic debug markers for pass/fail assertions

Out of scope (this version):

- Keyboard IRQ handling
- RTC, disk, or other device IRQ handlers
- APIC/IOAPIC
- Interrupt prioritization policy beyond PIC defaults
- User mode and privilege transitions

## 4. Constraints

- Architecture: x86
- Tooling: NASM + GCC
- Runtime: QEMU
- Keep implementation small and understandable
- Keep this feature independently testable

## 5. Preconditions

Before hardware IRQ enable:

- CPU is in 32-bit protected mode.
- A valid IDT is loaded.
- Interrupt stubs for vector 0x20 exist.
- Interrupts are disabled (`cli`) during PIC/PIT setup.

## 6. Functional Requirements

### HI-FR-1 PIC Remap

Kernel must initialize master/slave PIC so IRQ vectors are remapped from
legacy 0x08/0x70 ranges to 0x20-0x2F.

### HI-FR-2 IRQ Masking

Kernel must program PIC masks so only IRQ0 (timer) is unmasked in v1.
All other IRQ lines remain masked to keep behavior deterministic.

### HI-FR-3 PIT Periodic Timer

Kernel must program PIT channel 0 in periodic mode at a fixed documented
frequency for tests (for example 100 Hz).

### HI-FR-4 IRQ0 Handler

When timer IRQ0 fires, handler must:

- preserve required CPU state,
- increment a monotonic tick counter,
- emit or gate success marker output,
- send EOI to master PIC,
- return with `iret`.

### HI-FR-5 Deterministic Marker Contract

Hardware interrupt behavior must be observable through debug port `0xE9`
markers:

- `HI_INIT_OK`: PIC + PIT init completed.
- `HI_IRQ0_OK`: timer IRQ handler executed at least once.
- `HI_TICKS_n`: optional bounded tick marker for deterministic thresholds.

### HI-FR-6 Safe Failure Behavior

If PIC/PIT init invariants fail in test variants, kernel must emit a distinct
failure marker and halt in `cli` + `hlt` loop.

## 7. Non-Functional Requirements

### HI-NFR-1 Simplicity

Implementation should remain readable in one focused review session.

### HI-NFR-2 Determinism

Test outcomes must be reproducible across repeated QEMU runs with fixed timeout.

### HI-NFR-3 Isolation

Hardware interrupt tests must run independently from keyboard, disk, and future
scheduler work.

## 8. Interface Contract

### Inputs

- Existing IDT setup helpers
- Existing IRQ0 vector stub (0x20)
- Existing debug marker output path (`debug_print_pm`)

### Outputs

- Tick counter increments in kernel state
- Marker stream proving init and IRQ0 handling
- Stable return to interrupted flow after each IRQ0

## 9. Test Specification

### HI-T1 PIC/PIT Initialization

- Boot kernel variant that performs PIC remap, mask config, and PIT init.

Acceptance:

- `HI_INIT_OK` appears.
- No exception markers indicating setup corruption.

### HI-T2 IRQ0 Delivery

- Boot and wait for at least one hardware timer interrupt.

Acceptance:

- `HI_IRQ0_OK` appears.
- Kernel remains alive long enough to observe marker.

### HI-T3 Multiple Tick Validation

- Boot and wait for bounded number of timer interrupts.

Acceptance:

- Tick counter reaches configured threshold (for example 3).
- Marker indicates deterministic tick progression.

### HI-T4 IRQ Mask Discipline

- Verify non-timer IRQs remain masked in v1 config.

Acceptance:

- No unexpected IRQ markers are observed.
- IRQ0 path remains functional.

## 10. Milestones

### HI-M1: Bring-up

- PIC remap + masking.
- PIT periodic mode setup.
- `HI_INIT_OK` marker.

### HI-M2: Runtime Validation

- IRQ0 handler integration.
- EOI behavior validation.
- `HI_IRQ0_OK` and multi-tick proof.

## 11. Phase 0 Decisions (Locked)

- Interrupt source for v1: PIT channel 0 via IRQ0.
- IRQ vector map: PIC remapped to 0x20-0x2F.
- Enabled IRQ lines in v1: IRQ0 only.
- Test strategy: debug-port markers captured in QEMU log.
- Failure strategy: marker + `cli` + `hlt` loop.

## 12. Definition of Done

This module is done when:

- HI-FR-1..HI-FR-6 are implemented.
- HI-T1..HI-T4 are reproducible in local workflow.
- `make check-hi-all` is available and deterministic.
- Docs, constants, and marker strings are synchronized with implementation.
