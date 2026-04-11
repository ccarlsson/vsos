# C Kernel Transition Testing Guide

## Overview

The C kernel transition is validated by preserving the current external behavior while changing the internal implementation boundary.

The test strategy is intentionally conservative:

- Reuse existing marker-based QEMU tests.
- Preserve the raw kernel binary boot contract.
- Introduce one new C-entry marker when the mixed-language path first lands.

## Test Philosophy

- **Boundary-first**: Verify the asm-to-C handoff before migrating subsystems.
- **Behavior-preserving**: Existing tests must remain valid throughout the transition.
- **Incremental**: Move one subsystem at a time.
- **Artifact-stable**: Keep `build/kernel.bin` bootable throughout the transition.

## Phase 1 Tests

### CK-T1: C Entry Reached

**Objective**: Verify assembly bootstrap reaches freestanding C code.

**Test Flow**:

1. Bootloader loads the kernel as normal.
2. Assembly kernel shim enters protected mode.
3. Shim calls `kmain`.
4. C code emits a dedicated success marker.

**Expected Output**:

```text
VSOS M1
KERNEL_OK
PM_OK
C_ENTRY_OK
```

**Validation**:

- Debug log contains `C_ENTRY_OK`.
- Existing earlier markers remain present.

### CK-T2: Protected-Mode Contract Preserved

**Objective**: Verify C executes under the same stable environment as the assembly kernel.

**Validation**:

- `PM_OK` still appears.
- C code can safely call simple helper routines.
- No early triple-fault or silent hang is introduced.

### CK-T3: Existing Tests Still Pass

**Objective**: Use the current full-suite tests as regression protection.

**Command**:

```bash
make check-all
```

**Validation**:

- Bootloader tests pass.
- Protected-mode tests pass.
- Interrupt tests pass.
- VGA tests pass.

### CK-T4: Raw Binary Contract Preserved

**Objective**: Ensure the bootloader remains compatible with the new build output.

**Validation**:

- `build/kernel.bin` is still produced.
- Disk image still boots with unchanged `dd ... seek=1` flow.
- Bootloader handoff test remains green.

## Phase 2 Tests

### CK-T5: First Migrated Subsystem Passes Old Tests

**Objective**: Verify the first C-migrated subsystem preserves behavior.

If VGA is migrated first:

**Commands**:

```bash
make check-vga-all
make check-all
```

**Validation**:

- All existing VGA markers still appear.
- Aggregate suite remains green.

## Recommended Validation Sequence

After each migration step:

1. `make check-qemu-m2`
2. `make check-pm-all`
3. `make check-ih-all`
4. `make check-vga-all`
5. `make check-all`

This sequence narrows failures quickly while still validating the full path.

## CI Expectations

- CI should continue using headless QEMU test scripts.
- CI should keep `make check-all` as the main regression entry point.
- Any added C toolchain prerequisites must be installed before the build.

## Failure Modes to Watch

### 1. Linker Placement Errors

Symptoms:

- Bootloader handoff fails.
- `KERNEL_OK` appears but `PM_OK` or `C_ENTRY_OK` does not.
- QEMU resets or hangs unexpectedly.

### 2. ABI Mismatch

Symptoms:

- C entry is reached inconsistently.
- Stack corruption or garbage markers.
- Interrupt tests fail after mixed build lands.

### 3. Toolchain Configuration Errors

Symptoms:

- C objects compile but linked binary does not boot.
- Wrong architecture or section layout.
- `objcopy` output is malformed for raw boot loading.

### 4. Regression from Over-Migration

Symptoms:

- Large sets of prior tests fail after moving too much behavior at once.

Mitigation:

- Move only one subsystem per step.
- Re-run aggregate tests after each change.

## Notes

- The transition should preserve observability. Marker output is part of the architecture during migration.
- If a new C runtime helper is required, test it in isolation before wiring it into central boot flow.
