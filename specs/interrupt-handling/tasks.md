# Interrupt Handling Task List

This checklist translates `spec.md` and `plan.md` into implementation-ready work.

## Phase 0 - Design Lock

- [ ] Decide IDT size and vector allocation.
- [ ] Define exception vector numbering (0-31 reserved).
- [ ] Define interrupt vector numbering (32+ for PIC/APIC).
- [ ] Choose handler entry point strategy (inline, separate section, etc.).
- [ ] Define register preservation convention in handlers.
- [ ] Choose test interrupt source (software `int` or PIC timer).
- [ ] Finalize marker codes:
  - [ ] IH_OK
  - [ ] IX_00 (divide by zero)
  - [ ] IX_06 (invalid opcode)
  - [ ] IX_13 (general protection fault)

## Phase 1 - Minimal Interrupt Path (IH-M1)

### IDT Setup

- [ ] Allocate IDT structure in kernel memory.
- [ ] Define IDT entry descriptor format (gate type, segment selector, offset, DPL, present bit).
- [ ] Implement IDT load routine using `lidt`.

### Handler Implementation

- [ ] Create timer/test interrupt handler routine.
- [ ] Save general-purpose registers on entry (push eax, ecx, edx, ebx, etc.).
- [ ] Restore registers before return (pop in reverse order).
- [ ] Verify stack frame layout (error code, EIP, CS, EFLAGS).

### Interrupt Enable and Markers

- [ ] Execute `sti` to enable interrupts after IDT load.
- [ ] Emit `IH_OK` marker to debug port on successful handler execution.
- [ ] Disable interrupts with `cli` before halt (if needed).

### Validation

- [ ] IH-T1: IDT loads, timer interrupt fires, IH_OK emitted, handler returns.

## Phase 2 - Exception Handlers (IH-M2)

### Exception Handler Framework

- [ ] Implement exception handler stubs for vectors 0, 6, 13.
- [ ] Preserve exception context:
  - [ ] Save error code (if present).
  - [ ] Save interrupted EIP, CS, EFLAGS.
  - [ ] Optionally: ESP and segment registers.

### Error Markers and Recovery

- [ ] Emit `IX_00` when divide-by-zero exception fires.
- [ ] Emit `IX_06` when invalid-opcode exception fires.
- [ ] Emit `IX_13` when general-protection-fault exception fires.
- [ ] Halt in `cli` + `hlt` loop after exception (no recovery).

### Validation

- [ ] IH-T2: Trigger divide by zero, handler catches, IX_00 emitted, CPU does not triple-fault.
- [ ] IH-T3: Execute invalid opcode, handler catches, IX_06 emitted.

## Phase 3 - Reproducibility and CI

### Local Workflow

- [ ] Create interrupt-handling test scripts under `tests/interrupt-handling/scripts/`.
- [ ] Implement check_qemu_ih_t1.sh (timer/interrupt test).
- [ ] Implement check_qemu_ih_t2.sh (divide-by-zero exception test).
- [ ] Implement check_qemu_ih_t3.sh (invalid-opcode exception test).
- [ ] Implement check_qemu_ih_t4.sh (multiple interrupts test).
- [ ] Add make targets:
  - [ ] check-ih-t1
  - [ ] check-ih-t2
  - [ ] check-ih-t3
  - [ ] check-ih-t4
  - [ ] check-ih-all

### CI Workflow

- [ ] Update GitHub Actions workflow to run interrupt-handling tests.
- [ ] Upload interrupt-handling debug artifacts on failure.

### Documentation

- [ ] Keep `specs/interrupt-handling/spec.md` synchronized with implementation.
- [ ] Create `specs/interrupt-handling/testing.md` with test commands and expected markers.

## Requirement Traceability Checklist

- [ ] IH-FR-1 satisfied.
- [ ] IH-FR-2 satisfied.
- [ ] IH-FR-3 satisfied.
- [ ] IH-FR-4 satisfied.
- [ ] IH-FR-5 satisfied.
- [ ] IH-FR-6 satisfied.

## Done Criteria

- [ ] IH-T1..IH-T4 pass locally.
- [ ] CI runs and passes interrupt-handling tests.
- [ ] IH_OK and IX_nn behavior is deterministic.
- [ ] IDT structure and handler contracts are documented and synchronized.
