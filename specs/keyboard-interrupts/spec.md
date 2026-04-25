# Keyboard Interrupts Specification

## 1. Purpose

This module defines the first keyboard input path in VSOS using legacy PS/2
keyboard IRQ delivery through the 8259 PIC in 32-bit protected mode.

The intent is to keep the first keyboard milestone minimal, deterministic, and
educational:

- unmask keyboard IRQ1 alongside the existing timer IRQ0 path,
- dispatch IRQ1 through IDT vector `0x21`,
- read a raw scancode from port `0x60`,
- emit deterministic markers for test automation,
- optionally echo a small decoded character subset to VGA.

## 2. Context

Current VSOS status:

- Bootloader, kernel loading, and protected-mode transition are implemented.
- A mixed assembly + freestanding C kernel is implemented.
- VGA text output is implemented.
- IDT setup and basic exception handling are implemented.
- PIC/PIT timer initialization and timer IRQ0 handling are implemented.

This slice extends the interrupt subsystem from timer-only hardware events to
the first human-driven input device.

## 3. Scope

In scope:

- PIC mask update so IRQ0 and IRQ1 are unmasked in the keyboard-enabled variant
- IDT entry for keyboard vector `0x21`
- Assembly IRQ1 stub with `iret` return path
- C-visible keyboard handler that reads port `0x60`
- Minimal raw scancode capture and bookkeeping
- Deterministic debug markers for initialization and first key delivery
- Optional decoding of a tiny locked subset of make codes to ASCII

Out of scope (this version):

- Full PS/2 controller initialization sequence
- Key release handling beyond optional ignore/drop behavior
- Shift, Ctrl, Alt, Caps Lock, or layout handling
- Buffered line input or shell/TTY behavior
- Keyboard LED control
- Scan code set negotiation
- Mouse or other PS/2 devices

## 4. Constraints

- Architecture: x86
- Tooling: NASM + GCC
- Runtime: QEMU
- Keep implementation small and understandable
- Reuse the existing PIC/IDT/marker infrastructure
- Preserve deterministic timer behavior while adding keyboard support

## 5. Preconditions

Before keyboard IRQ enable:

- CPU is in 32-bit protected mode.
- A valid IDT is loaded.
- PIC has already been remapped to `0x20-0x2F`.
- Timer IRQ0 path remains functional.
- Interrupts are disabled (`cli`) during PIC mask updates.

## 6. Functional Requirements

### KBD-FR-1 Keyboard Vector Installation

Kernel must install a valid interrupt gate for vector `0x21` so keyboard IRQ1
dispatches through a dedicated handler path.

### KBD-FR-2 PIC Mask Policy

Keyboard-enabled builds must program the master PIC mask so:

- IRQ0 remains unmasked
- IRQ1 becomes unmasked
- all remaining master/slave IRQ lines remain masked in v1

### KBD-FR-3 Raw Scancode Read

On each keyboard IRQ1, handler must read one byte from PS/2 data port `0x60`
and record it in kernel-visible state.

### KBD-FR-4 Deterministic First-Key Contract

The first observed keyboard IRQ/scancode in a test run must emit deterministic
markers to debug port `0xE9`:

- `KBD_INIT_OK`: keyboard IRQ path initialized
- `KBD_IRQ1_OK`: IRQ1 handler executed at least once
- `KBD_SC_OK`: captured scancode matched the test's expected value

### KBD-FR-5 Minimal Decoding Option

v1 may decode only a tiny locked subset of make codes to ASCII for observability.

Recommended initial subset:

- `0x1E -> 'a'`
- `0x1C -> '\n'`
- `0x01 -> ESC` (marker only, no printable echo required)

If ASCII echo is implemented, unsupported scancodes may be ignored without
failing the IRQ path.

### KBD-FR-6 End-of-Interrupt Discipline

Keyboard IRQ handler must send EOI to the master PIC before returning with
`iret`.

### KBD-FR-7 Safe Failure Behavior

No dedicated keyboard failure marker path is required in v1.
The module validates runtime behavior through deterministic positive markers and
preserves the existing halt-safe defaults for unexpected faults.

## 7. Non-Functional Requirements

### KBD-NFR-1 Simplicity

Implementation should remain understandable in one focused review session.

### KBD-NFR-2 Determinism

Tests must use injected key events and fixed expected scancodes so outcomes are
reproducible across QEMU runs.

### KBD-NFR-3 Isolation

Keyboard tests must run independently from future shell, scheduler, and memory
management work.

## 8. Interface Contract

### Inputs

- Existing PIC remap and mask helpers
- Existing IDT setup helpers
- Existing debug marker output path (`debug_print_pm`)
- QEMU-injected keyboard input event

### Outputs

- Last observed keyboard scancode stored in kernel state
- Marker stream proving keyboard init and IRQ delivery
- Optional VGA-visible echo for supported keys

## 9. Test Specification

### KBD-T1 Keyboard IRQ Initialization

- Boot keyboard-enabled kernel variant.
- Initialize PIC mask and IDT for IRQ1.

Acceptance:

- `KBD_INIT_OK` appears.
- Existing timer path is not regressed.

### KBD-T2 First Keyboard IRQ Delivery

- Boot keyboard-enabled kernel.
- Inject a single key event through QEMU.

Acceptance:

- `KBD_IRQ1_OK` appears.
- Kernel remains alive long enough to observe marker.

### KBD-T3 Expected Scancode Capture

- Boot keyboard-enabled kernel.
- Inject a locked test key (recommended: `a`).

Acceptance:

- Kernel records expected raw scancode.
- `KBD_SC_OK` appears.

### KBD-T4 IRQ Coexistence with Timer

- Boot keyboard-enabled kernel with timer IRQ0 still active.
- Inject one key event and allow multiple timer ticks.

Acceptance:

- `KBD_IRQ1_OK` appears.
- Existing timer liveness marker still appears (for example `HI_TICKS_3`).
- No unexpected exception markers are observed.

## 10. Milestones

### KBD-M1: Keyboard Bring-up

- IRQ1 gate installed at `0x21`
- PIC mask updated to allow IRQ1
- `KBD_INIT_OK` marker

### KBD-M2: Runtime Validation

- First IRQ1 delivery observed
- Scancode capture validated
- EOI behavior verified

## 11. Phase 0 Decisions (Locked)

- Interrupt source for v1: legacy PS/2 keyboard via IRQ1.
- Keyboard vector: `0x21` after PIC remap.
- PIC mask in keyboard-enabled variant: master `0xFC`, slave `0xFF`.
- Data port read: `0x60`.
- Test strategy: inject deterministic key event in QEMU and capture debug-port markers.
- Marker contract: `KBD_INIT_OK`, `KBD_IRQ1_OK`, `KBD_SC_OK`.
- Recommended first locked key: `a`, expected make code `0x1E`.
- Optional ASCII echo is diagnostic only; marker contract is normative.

## 12. Definition of Done

This module is done when:

- KBD-FR-1..KBD-FR-7 are implemented.
- KBD-T1..KBD-T4 are reproducible in local workflow.
- `make check-kbd-all` is available and deterministic.
- Docs, constants, and marker strings are synchronized with implementation.
