# Interrupt Handling Specification

## 1. Purpose

This module defines how VSOS responds to hardware interrupts and software exceptions
in 32-bit protected mode in a deterministic, educational, and testable way.

The intent is to keep the first interrupt-handling step minimal:

- load and activate an IDT,
- service a single well-defined interrupt (timer tick or system call),
- verify correct dispatch and return to interrupted code,
- avoid adding paging, task switching, or advanced exception recovery.

## 2. Context

Current VSOS status:

- Real-mode bootloader working.
- Kernel loading and handoff working.
- Protected mode 32-bit transition working.
- Flat address space with static code/data layout.

This spec introduces a new module boundary: interrupt/exception correctness.

## 3. Scope

In scope:

- Define and load a minimal Interrupt Descriptor Table (IDT)
- Set up IDT entries for timer interrupt and common exceptions
- Enable interrupts with `sti` instruction
- Implement timer/clock interrupt handler (or software interrupt for test)
- Implement basic exception handlers (divide by zero, invalid opcode, general protection fault)
- Return to interrupted code correctly with `iret`
- Emit success/error markers for automated tests

Out of scope (this version):

- Paging and page faults
- Task switching and TSS usage
- User mode / privilege transitions / ring 3
- Nested interrupt re-entrancy or interrupt masking strategies
- Full exception recovery (e.g., fixing and continuing)
- Syscall argument passing beyond simple register convention

## 4. Constraints (from VSOS context)

- Architecture: x86
- Tooling: NASM + GCC
- Runtime: QEMU
- Keep implementation small and understandable
- Keep each feature independently testable

## 5. Preconditions

Before interrupt handling entry:

- CPU executes in 32-bit protected mode.
- Flat memory model with code and data in base 0, limit 4 GiB.
- Stack is initialized.
- Interrupts are currently disabled.

## 6. Functional Requirements

### IH-FR-1 Minimal IDT Definition and Load

An Interrupt Descriptor Table must be defined in memory and loaded with `lidt`.
The IDT must contain descriptors for at least:

- Exception vectors 0-14 (divide by zero, debug, NMI, breakpoint, overflow, bound, invalid opcode,
  device not available, double fault, segment not present, stack segment fault, general protection fault,
  page fault, reserved, floating point, alignment check)
- Timer interrupt vector (32 for PIC mode, or 0 onward for test harness)
- Optionally: reserved exception vectors filled with dummy handlers

Descriptor format must be correct per x86 32-bit protected mode spec (gate type, DPL, segment selector, offset).

### IH-FR-2 Interrupt Enable

Interrupts must be enabled via `sti` after IDT load.
Interrupts must be disabled during critical sections with `cli`.

### IH-FR-3 Timer/Clock Interrupt Handler

The OS must service at least one recurring interrupt (QEMU timer via PIC, or test-injected IRQ).

Handler must:

- Preserve CPU state (registers, flags).
- Execute minimal logic (increment counter, emit marker, or satisfy test condition).
- Return to interrupted code with `iret`.

### IH-FR-4 Exception Handler Framework

A catch-all or specific exception handlers must be in place for:

- Division by zero (INT 0)
- Invalid opcode (INT 6)
- General protection fault (INT 13)

Handlers must:

- Emit an error marker distinct from normal operation.
- Halt or return control in a safe manner.
- Record exception context for debugging (error code, instruction pointer).

### IH-FR-5 Handler Return State

On `iret`, the CPU must restore:

- All general-purpose registers (if preserved by handler).
- EFLAGS.
- EIP and CS for correct code location.

Interrupted code must observe no handler side effects (except intentional updates like a counter).

### IH-FR-6 Success and Failure Markers

Interrupt handling correctness must be observable through distinct markers emitted to debug port `0xE9`:

- `IH_OK`: timer/clock interrupt fired and handler executed at least once.
- `IX_nn`: exception handler for vector nn executed (e.g., `IX_00` for divide by zero).

## 7. Non-Functional Requirements

### IH-NFR-1 Simplicity

Interrupt handling code should be understandable to students in one reading session.

### IH-NFR-2 Determinism

IDT load, handler dispatch, and return behavior are reproducible across QEMU runs.

### IH-NFR-3 Isolation

Interrupt tests must run independently without interaction with paging or privilege transitions.

## 8. Interface Contract

### Interrupt Entry (from CPU)

Guaranteed by hardware:

- CPU pushes: EIP, CS, EFLAGS (and error code if applicable) onto stack.
- Handler receives: CPU state as-is at interrupt time.
- Stack pointer (ESP) valid.

### Interrupt Stack Frame (on entry)

```text
[ESP+12] EFLAGS
[ESP+8]  CS
[ESP+4]  EIP
[ESP+0]  (error code, if applicable)
```

### Handler Execution

Handler must:

- Save/restore registers it uses.
- Not corrupt stack or memory outside its control.
- Call `iret` to return.

### Return to Interrupted Code

On `iret`:

- CPU pops EIP, CS, EFLAGS from stack.
- Execution resumes at the original interrupted instruction (or next instruction if advanced).

## 9. Test Specification

### IH-T1 IDT Load and Timer Interrupt

- Boot kernel in QEMU with timer enabled (default PIC mode).
- Let kernel load IDT and execute `sti`.
- Kernel waits for timer interrupt or emits a test interrupt.

Acceptance:

- `IH_OK` marker observed.
- Handler executed and returned correctly.

### IH-T2 Exception Trigger (Divide by Zero)

- Kernel deliberately executes `div 0` or similar instruction.

Acceptance:

- `IX_00` (or configured exception marker) observed.
- Kernel recovers or halts gracefully.

### IH-T3 Exception Trigger (Invalid Opcode)

- Kernel executes invalid x86 instruction or `ud2`.

Acceptance:

- `IX_06` (or configured exception marker) observed.
- CPU did not triple-fault; handler completed.

### IH-T4 Multiple Interrupts

- Kernel receives multiple timer interrupts or triggers multiple exceptions.

Acceptance:

- Each interrupt was handled and returned correctly.
- Handler state isolation verified (e.g., counter incremented per interrupt).

## 10. Milestones

### IH-M1: Minimal Interrupt Path

- IDT definition and load.
- `sti` to enable interrupts.
- Single timer or test interrupt handler.
- `IH_OK` marker on success.

### IH-M2: Exception Handling

- Exception handlers for divide by zero, invalid opcode, general protection fault.
- Distinct error markers.
- Graceful halt or recovery.

## 11. Phase 0 Design Lock

The following decisions are locked for IH Phase 0 and are now normative for implementation.

### 11.1 IDT Size and Layout

- IDT has 256 entries (vectors 0-255).
- Entry size is 8 bytes (32-bit interrupt gate).
- IDT limit is `256 * 8 - 1 = 0x07FF`.
- IDT is placed in kernel static data and aligned to 8 bytes.

### 11.2 Vector Allocation

- CPU exception vectors remain standard: 0-31.
- External interrupt vectors use PIC-remapped range: 32-47 (`0x20-0x2F`).
- Timer IRQ0 uses vector 32 (`0x20`).
- Initial dedicated handlers are required for vectors:
  - 0 (divide by zero)
  - 6 (invalid opcode)
  - 13 (general protection fault)
  - 32 (timer/test interrupt)
- All other vectors point to a default halt-safe handler.

### 11.3 PIC and Interrupt Source

- PIC mode is used (8259 compatible behavior in QEMU).
- First validation path uses deterministic software trigger `int 0x20`.
- Hardware timer IRQ validation can be added after the deterministic path is stable.

### 11.4 Handler Entry Strategy

- Use per-vector assembly stubs that dispatch to a shared common handler path.
- Stubs without CPU-pushed error codes provide a synthetic zero error code to normalize stack handling.
- Stubs with CPU-pushed error codes preserve the original error code and follow the same common path.

### 11.5 Register Preservation Convention

- Handlers preserve general-purpose registers with `pushad`/`popad`.
- Handler paths do not modify segment registers in v1.
- Return from interrupt/exception paths uses `iret` only.

### 11.6 Marker Codes

- Success marker: `IH_OK`.
- Exception markers:
  - `IX_00` for vector 0
  - `IX_06` for vector 6
  - `IX_13` for vector 13
- Unknown/default vector marker: `IX_DF` (default-fallback path).

### 11.7 First-Version Exception Policy

- No recovery from exceptions in v1.
- Exception handlers emit marker and enter `cli` + `hlt` loop.
- Nested interrupt handling is out of scope for v1.

## 12. Definition of Done

This module is done when:

- IH-FR-1..IH-FR-6 are implemented.
- IH-T1..IH-T4 are executable and passing in local workflow.
- IDT constants, handler entry points, and marker codes are documented and synchronized with code.
- CI runs the interrupt-handling test set with deterministic results.
