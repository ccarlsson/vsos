# Protected Mode Specification

## 1. Purpose

This module defines how VSOS transitions from 16-bit real mode to 32-bit
protected mode in a deterministic, educational, and testable way.

The intent is to keep the first protected-mode step minimal:

- perform the mode switch correctly,
- verify it in QEMU,
- avoid adding unrelated complexity in the same milestone.

## 2. Context

Current VSOS status:

- BIOS boot flow is working.
- Kernel loading and handoff are working in real mode.
- Local and CI tests for loader behavior are green.

This spec introduces a new module boundary: mode transition correctness.

## 3. Scope

In scope:

- Enable A20 line
- Create and load a minimal GDT
- Set `CR0.PE` to enable protected mode
- Perform mandatory far jump into 32-bit code segment
- Initialize 32-bit segment registers and stack
- Emit a protected-mode success marker for automated tests

Out of scope (this version):

- Paging setup
- User mode / privilege transitions
- Task switching / TSS usage
- Full IDT/interrupt handling strategy
- Long mode

## 4. Constraints (from VSOS context)

- Architecture: x86
- Tooling: NASM + GCC
- Runtime: QEMU
- Keep implementation small and understandable
- Keep each feature independently testable

## 5. Preconditions

Before mode switch entry:

- CPU executes in 16-bit real mode.
- Interrupts are disabled for transition-critical sequence.
- Kernel image is already loaded at agreed address.
- Transition code has access to a known stack and memory region for GDT data.

## 5.1 Phase 0 Decisions (Locked)

- Transition location for v1: kernel early transition stub.
- Selector constants:
	- `CODE_SEL = 0x08`
	- `DATA_SEL = 0x10`
- 32-bit stack top: `ESP = 0x0009FC00`
- A20 strategy for v1: fast A20 gate via port `0x92` with verification.
- Marker codes:
	- success: `PM_OK`
	- A20 failure: `P1`
	- transition/GDT failure: `P2`

## 6. Functional Requirements

### PM-FR-1 A20 Enable

The transition code must enable A20 and verify the result before attempting
protected-mode entry.

If A20 enable or verification fails:

- emit distinct error marker `P1`,
- halt in `cli` + `hlt` loop.

### PM-FR-2 Minimal GDT

A minimal GDT must be defined and loaded with `lgdt` containing at least:

- null descriptor
- 32-bit flat code descriptor (base 0, limit 4 GiB, execute/read)
- 32-bit flat data descriptor (base 0, limit 4 GiB, read/write)

Descriptor selectors must be documented constants.

### PM-FR-3 Protected Mode Enable

Transition must set `CR0.PE = 1` and immediately execute a far jump to the
32-bit code selector to flush prefetch and load `CS` correctly.

If transition fails to reach 32-bit entry marker, test must fail.

### PM-FR-4 32-bit Environment Init

At 32-bit entry, code must initialize:

- `DS`, `ES`, `FS`, `GS`, `SS` to the data selector
- `ESP` to a documented 32-bit stack top

State must be explicit and not rely on inherited undefined values.

### PM-FR-5 Success Marker

On successful mode transition, emit marker `PM_OK` through the same debug
channel used by existing QEMU-based tests (debug port `0xE9`).

### PM-FR-6 Error Behavior

All fatal protected-mode transition errors must:

- emit a short marker (`P1` for A20 failure, `P2` for GDT/setup failure),
- enter `cli` + `hlt` loop.

## 7. Non-Functional Requirements

### PM-NFR-1 Simplicity

Transition path should be understandable in one reading session by students.

### PM-NFR-2 Determinism

Given same source/toolchain, transition behavior and markers are reproducible.

### PM-NFR-3 Isolation

Protected-mode tests must be runnable independently of future paging/IDT work.

## 8. Interface Contract

### Real Mode -> Transition Entry

Guaranteed by caller:

- real mode execution
- interrupts disabled or controllably disabled by callee
- kernel already loaded

### Transition Exit (Success)

Guaranteed on success:

- CPU in 32-bit protected mode
- `CS` = configured 32-bit code selector
- `DS/ES/FS/GS/SS` = configured 32-bit data selector
- stack initialized to documented `ESP`
- success marker `PM_OK` emitted

## 9. Test Specification

### PM-T1 Positive Transition Path

- Boot image in QEMU with protected-mode transition enabled.

Acceptance:

- `PM_OK` observed.

### PM-T2 A20 Failure Handling

- Build or runtime variant that forces A20 path failure.

Acceptance:

- `P1` observed.
- `PM_OK` absent.

### PM-T3 GDT/Transition Failure Handling

- Build variant with invalid selector/descriptor configuration.

Acceptance:

- `P2` observed.
- `PM_OK` absent.

### PM-T4 Reproducible Test Entry

- Run module test command(s) through standard local workflow.

Acceptance:

- Tests produce consistent pass/fail markers across runs.

## 10. Milestones

### PM-M1: Minimal Switch

- A20 enable + verify
- GDT load
- `CR0.PE` set and far jump
- `PM_OK` marker

### PM-M2: Robustness

- Distinct failure markers (`P1`, `P2`)
- Automated positive and negative tests

## 11. Open Decisions

- Whether to add A20 fallback path (8042 controller) after v1 stabilization
- Whether to keep flat segmentation only for initial PM milestone

## 12. Definition of Done

This module is done when:

- PM-FR-1..PM-FR-6 are implemented.
- PM-T1..PM-T4 are executable and passing in local workflow.
- Transition constants/selectors are documented and synchronized with code.
- CI runs the protected-mode test set with deterministic results.
