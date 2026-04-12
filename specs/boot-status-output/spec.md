# Boot Status Output Specification

## 1. Purpose

This module defines how VSOS presents human-readable boot progress on screen so
the user can see what the system is doing while it starts.

The intent is to keep the first version simple, educational, and testable:

- show meaningful stage messages during bootloader execution,
- preserve visibility during early kernel/protected-mode bring-up,
- use the VGA text display once protected-mode kernel output is available,
- keep existing debug-port markers intact for automated tests.

## 2. Context

Current VSOS status:

- The bootloader already prints short messages via BIOS teletype.
- The protected-mode kernel already has a VGA text console implementation.
- Automated tests currently verify progress through debug-port markers.

This slice adds a clearer on-screen boot narrative for humans without replacing
the current machine-readable test markers.

## 3. Scope

In scope:

- Define visible boot messages for key startup stages
- Use BIOS text output in real mode during bootloader execution
- Use VGA text output in protected mode after VGA console init
- Keep messages short, deterministic, and stable across runs
- Document which boot stages should be visible to the user

Out of scope (this version):

- Animated progress indicators
- Graphical boot splash/logo
- Color themes beyond simple readable defaults
- User input during boot
- Runtime logging after normal kernel bring-up

## 4. Constraints

- Architecture: x86
- Tooling: NASM + GCC
- Runtime: QEMU
- Keep implementation small and understandable
- Do not break existing debug-port based tests

## 5. Preconditions

Before boot status output begins:

- BIOS has transferred control to the boot sector.
- Text-mode output is available through BIOS interrupt services.
- Later protected-mode stages can access VGA text memory.

## 6. Functional Requirements

### BSO-FR-1 Bootloader Visibility

The bootloader must display short readable status messages for major early boot
steps, such as startup, validation, kernel loading, and handoff.

### BSO-FR-2 Protected-Mode Transition Visibility

The kernel transition path must expose at least one visible message indicating
that control reached protected-mode kernel code.

### BSO-FR-3 VGA Console Bring-up Visibility

Once VGA output is initialized, the kernel must display readable boot progress
messages through the VGA console.

### BSO-FR-4 Stage Ordering

Messages must appear in deterministic order that matches the actual boot flow.

### BSO-FR-5 Test Compatibility

Existing debug-port markers such as `KERNEL_OK`, `PM_OK`, `IH_OK`, and VGA/HI
markers must remain present and unchanged for automated validation.

### BSO-FR-6 Failure Visibility

Fatal boot failures should continue to show short visible indicators before
halting, and may be supplemented with clearer user-facing text when safe.

## 7. Non-Functional Requirements

### BSO-NFR-1 Simplicity

The message path should be understandable in one reading session.

### BSO-NFR-2 Determinism

Visible output order must be reproducible across runs.

### BSO-NFR-3 Separation of Concerns

Human-readable boot output must not replace or weaken machine-readable test
markers.

## 8. Interface Contract

### Real Mode

- Output mechanism: BIOS teletype (`int 0x10`)
- Message style: short ASCII strings

### Protected Mode

- Output mechanism: VGA text buffer through existing console helpers
- Message style: short ASCII strings

## 9. Test Specification

### BSO-T1 Bootloader Message Presence

- Boot in QEMU.

Acceptance:

- Bootloader startup and kernel-load messages are visible on screen.

### BSO-T2 Handoff Visibility

- Boot through protected-mode transition.

Acceptance:

- A message indicates control reached the kernel/protected-mode stage.

### BSO-T3 VGA Boot Progress

- Boot through VGA console initialization.

Acceptance:

- The screen shows readable status text through the existing VGA console.

### BSO-T4 Regression Compatibility

- Run existing automated test suites.

Acceptance:

- Existing debug-port marker based tests continue to pass unchanged.

## 10. Milestones

### BSO-M1: Bootloader Status Messages

- Define short bootloader status text.
- Display progress before kernel handoff.

### BSO-M2: Early Kernel Status Messages

- Show protected-mode / kernel entry progress.
- Route user-visible progress through VGA after init.

## 11. Phase 0 Decisions (Initial Draft)

- Real-mode visibility uses the existing BIOS teletype path.
- Protected-mode visibility uses the existing VGA console path.
- Debug-port markers remain the canonical automated test contract.
- Messages should be short, stable, and ASCII-only.

## 12. Definition of Done

This module is done when:

- BSO-FR-1..BSO-FR-6 are implemented.
- BSO-T1..BSO-T4 pass with deterministic output.
- Human-readable boot messages are visible without breaking existing tests.
