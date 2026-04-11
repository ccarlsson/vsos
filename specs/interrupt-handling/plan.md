# Interrupt Handling Implementation Plan

## 1. Objective

Implement interrupt handling in 32-bit protected mode for VSOS with minimal
complexity: load an IDT, service timer interrupts, handle exceptions, and verify
correct dispatch and return.

Success criteria:

- IH-FR-1..IH-FR-6 are implemented.
- IH-T1..IH-T4 are reproducible in local workflow.
- CI runs interrupt-handling tests through canonical commands.

## 2. Work Breakdown

### Phase 0 - Design Lock

Goal: Finalize IDT structure, vector numbering, and handler strategy.

Tasks:

- Decide IDT size (usually 256 entries, but start with 32 for exceptions + 16 for IRQs).
- Decide exception vector numbering:
  - 0-31 reserved for CPU exceptions.
  - 32+ for external interrupts (PIC/APIC).
- Define handler entry point locations and preserved register conventions.
- Choose test interrupt source:
  - Simulated (software `int` instruction), or
  - QEMU PIC timer (IRQ 0).
- Define marker codes:
  - success: IH_OK
  - exceptions: IX_00, IX_06, IX_13, etc.

Deliverables:

- IDT layout and vector allocation documented in spec.
- Handler calling convention documented.

Exit criteria:

- No unresolved questions about IDT size, vectors, or handler locations.

Phase 0 locked decisions:

- IDT size: 256 entries (8-byte gates, limit `0x07FF`), 8-byte aligned static table.
- Vector map:
  - Exceptions: 0-31
  - PIC IRQ range: 32-47
  - Timer IRQ0/test vector: 32 (`0x20`)
- First implemented handlers: vectors 0, 6, 13, and 32; all others use default safe handler.
- Handler strategy: per-vector stubs + common handler path.
- Register convention: preserve GPRs via `pushad`/`popad`; return via `iret`.
- Test interrupt source for IH-T1: deterministic software `int 0x20` first, hardware timer later.
- Markers: `IH_OK`, `IX_00`, `IX_06`, `IX_13`, default `IX_DF`.
- Exception policy (v1): no recovery, emit marker, then halt with `cli` + `hlt` loop.

Status: Complete.

### Phase 1 - Minimal Interrupt Path (IH-M1)

Goal: Get one interrupt firing and handled.

Tasks:

- Allocate IDT in kernel memory (aligned to 8 bytes).
- Define IDT entry structure (gate descriptor format).
- Implement IDT load routine (`lidt`).
- Create a minimal timer/test interrupt handler.
- Preserve and restore CPU state in handler (push/pop registers).
- Emit `IH_OK` marker on successful interrupt.
- Enable interrupts with `sti` after IDT load.

Deliverables:

- Working IDT load and interrupt handler.
- Positive-path verification output.

Exit criteria:

- IH-T1 passes.

Phase 1 implementation status:

- IDT table allocated in kernel static data (256 entries, 8-byte gates).
- `init_idt` sets default gates and vector 32 gate, then executes `lidt`.
- Deterministic validation uses software `int 0x20`.
- Vector 32 handler preserves GPR state, emits `IH_OK`, and returns with `iret`.
- Interrupts enabled with `sti` only after IDT initialization.

Status: Complete.

### Phase 2 - Exception Handlers (IH-M2)

Goal: Trap and handle CPU exceptions.

Tasks:

- Implement exception handlers for vectors 0, 6, 13 (divide by zero, invalid opcode, GPF).
- Preserve exception context (error code, EIP, etc.).
- Emit distinct error marker for each exception (e.g., `IX_00`, `IX_06`, `IX_13`).
- Halt or return safely without triple-fault.
- Test divide-by-zero and invalid-opcode paths.

Deliverables:

- Distinct exception markers and recovery behavior.

Exit criteria:

- IH-T2 and IH-T3 pass.

Phase 2 implementation status:

- Dedicated exception handlers installed for vectors 0, 6, and 13.
- Exception handlers capture vector id, interrupted EIP, and error code (when present).
- Marker emission implemented:
  - `IX_00` for divide-by-zero
  - `IX_06` for invalid opcode
  - `IX_13` for general protection fault
- Exception policy is enforced: `cli` + `hlt` loop after marker emission.
- Deterministic exception tests added via build variants:
  - `EXCEPTION_TEST=1` triggers divide-by-zero
  - `EXCEPTION_TEST=2` triggers invalid opcode (`ud2`)

Status: Complete.

### Phase 3 - Reproducibility and CI

Goal: Integrate interrupt tests into existing workflow.

Tasks:

- Add interrupt test scripts under `tests/interrupt-handling/`.
- Add make targets:
  - check-ih-t1 (timer interrupt)
  - check-ih-t2 (exception: divide by zero)
  - check-ih-t3 (exception: invalid opcode)
  - check-ih-t4 (multiple interrupts)
  - check-ih-all
- Wire CI to run interrupt-handling checks.
- Document test commands and expected markers.

Deliverables:

- Repeatable local + CI interrupt-handling validation flow.

Exit criteria:

- IH-T4 passes and CI includes interrupt-handling coverage.

Phase 3 implementation status:

- IH-T4 implemented with deterministic multiple software interrupts (`int 0x20` x3).
- `check_qemu_ih_t4.sh` validates multiple handler returns by requiring at least 3 `IH_OK` markers.
- Makefile includes `check-ih-t1`..`check-ih-t4` and `check-ih-all`.
- GitHub Actions workflow now runs `make check-all check-pm-all check-ih-all`.
- Interrupt-handling testing reference added in `specs/interrupt-handling/testing.md`.

Status: Complete.

## 3. Requirement Traceability

- IH-FR-1 -> IDT definition and load tasks.
- IH-FR-2 -> `sti` enable and interrupt control tasks.
- IH-FR-3 -> Timer handler implementation and marker emission.
- IH-FR-4 -> Exception handler framework and distinct error markers.
- IH-FR-5 -> Handler preserve/restore and `iret` correctness.
- IH-FR-6 -> IH_OK and IX_nn marker tasks.

## 4. Risks and Mitigations

Risk: IDT entry format is easy to get wrong; IDT misload causes triple-fault.
Mitigation: Define and document IDT layout clearly; start with static IDT in code.

Risk: Handler register clobbering causes silent failures or crashes.
Mitigation: Explicit save/restore of registers; inline documented stack layout.

Risk: QEMU timer interrupt fires at undefined rate or not at all.
Mitigation: Use test harness to inject software interrupt; fall back to `int` instruction.

Risk: Exception handling complexities (returning to faulting instruction, error codes).
Mitigation: Keep first version simple; don't try to fix faults, just halt.

Risk: Interrupt handlers conflict with existing kernel or protected-mode code.
Mitigation: Start with dedicated interrupt-handling mode or separate kernel phase.

## 5. Definition of Done

- IH-FR-1..IH-FR-6 implemented.
- IH-T1..IH-T4 passing in local workflow.
- Interrupt-handling tests included in CI.
- IDT constants, handler entry points, and contracts synchronized between spec and code.
