# Interrupt Handling Task List

This checklist translates `spec.md` and `plan.md` into implementation-ready work.

## Phase 0 - Design Lock

- [x] Decide IDT size and vector allocation (256 entries, limit `0x07FF`).
- [x] Define exception vector numbering (0-31 reserved).
- [x] Define interrupt vector numbering (PIC remap 32-47).
- [x] Choose handler entry point strategy (per-vector stubs + common handler).
- [x] Define register preservation convention in handlers (`pushad`/`popad`, `iret`).
- [x] Choose test interrupt source (deterministic software `int 0x20` first).
- [x] Finalize marker codes:
  - [x] IH_OK
  - [x] IX_00 (divide by zero)
  - [x] IX_06 (invalid opcode)
  - [x] IX_13 (general protection fault)
  - [x] IX_DF (default/fallback vector)

## Phase 1 - Minimal Interrupt Path (IH-M1)

### IDT Setup

- [x] Allocate IDT structure in kernel memory.
- [x] Define IDT entry descriptor format (gate type, segment selector, offset, DPL, present bit).
- [x] Implement IDT load routine using `lidt`.

### Handler Implementation

- [x] Create timer/test interrupt handler routine.
- [x] Save general-purpose registers on entry (push eax, ecx, edx, ebx, etc.).
- [x] Restore registers before return (pop in reverse order).
- [x] Verify stack frame layout (error code, EIP, CS, EFLAGS).

### Interrupt Enable and Markers

- [x] Execute `sti` to enable interrupts after IDT load.
- [x] Emit `IH_OK` marker to debug port on successful handler execution.
- [x] Disable interrupts with `cli` before halt (if needed).

### Validation

- [x] IH-T1: IDT loads, software interrupt `int 0x20` fires, IH_OK emitted, handler returns.

## Phase 2 - Exception Handlers (IH-M2)

### Exception Handler Framework

- [x] Implement exception handler stubs for vectors 0, 6, 13.
- [x] Preserve exception context:
  - [x] Save error code (if present).
  - [x] Save interrupted EIP, CS, EFLAGS.
  - [x] Optionally: ESP and segment registers.

### Error Markers and Recovery

- [x] Emit `IX_00` when divide-by-zero exception fires.
- [x] Emit `IX_06` when invalid-opcode exception fires.
- [x] Emit `IX_13` when general-protection-fault exception fires.
- [x] Halt in `cli` + `hlt` loop after exception (no recovery).

### Exception Handler Validation

- [x] IH-T2: Trigger divide by zero, handler catches, IX_00 emitted, CPU does not triple-fault.
- [x] IH-T3: Execute invalid opcode, handler catches, IX_06 emitted.

## Phase 3 - Reproducibility and CI

### Local Workflow

- [x] Create interrupt-handling test scripts under `tests/interrupt-handling/scripts/`.
- [x] Implement check_qemu_ih_t1.sh (timer/interrupt test).
- [x] Implement check_qemu_ih_t2.sh (divide-by-zero exception test).
- [x] Implement check_qemu_ih_t3.sh (invalid-opcode exception test).
- [x] Implement check_qemu_ih_t4.sh (multiple interrupts test).
- [x] Add make targets:
  - [x] check-ih-t1
  - [x] check-ih-t2
  - [x] check-ih-t3
  - [x] check-ih-t4
  - [x] check-ih-all

### CI Workflow

- [x] Update GitHub Actions workflow to run interrupt-handling tests.
- [x] Upload interrupt-handling debug artifacts on failure.

### Documentation

- [x] Keep `specs/interrupt-handling/spec.md` synchronized with implementation.
- [x] Create `specs/interrupt-handling/testing.md` with test commands and expected markers.

## Requirement Traceability Checklist

- [x] IH-FR-1 satisfied.
- [x] IH-FR-2 satisfied.
- [x] IH-FR-3 satisfied.
- [x] IH-FR-4 satisfied.
- [x] IH-FR-5 satisfied.
- [x] IH-FR-6 satisfied.

## Done Criteria

- [x] IH-T1..IH-T4 pass locally.
- [ ] CI runs and passes interrupt-handling tests.
- [x] IH_OK and IX_nn behavior is deterministic.
- [x] IDT structure and handler contracts are documented and synchronized.
