# C Kernel Transition Plan

## 1. Objective

Introduce a freestanding C kernel entry path while preserving the current bootloader contract, raw kernel binary output, and existing test suite behavior.

Success criteria:

- The kernel boots through the existing bootloader unchanged.
- A minimal assembly shim successfully transfers control to C.
- Existing bootloader, protected-mode, interrupt, and VGA tests continue to pass.
- At least one kernel subsystem is migrated from assembly to C without regression.

## 2. Work Breakdown

### Phase 0 - Toolchain and ABI Lock

Goal: Freeze the build model and asm-to-C entry contract before moving behavior.

Tasks:

- Define the assembly shim responsibilities.
- Define the C entry symbol and calling convention.
- Decide linker placement and raw binary generation flow.
- Confirm CI toolchain support for freestanding 32-bit C objects.

Deliverables:

- ABI notes in spec.
- Link model decision documented.
- Initial file layout defined.

Exit criteria:

- The build approach is fixed enough to implement without changing bootloader assumptions midstream.

### Phase 1 - Minimal Mixed-Language Boot

Goal: Boot through the existing path and execute a trivial C kernel body.

Tasks:

- Add an assembly shim that calls `kmain`.
- Add a freestanding `kmain.c`.
- Add a linker script.
- Update Makefile to assemble, compile, link, and emit `build/kernel.bin`.
- Emit a dedicated C-entry marker for verification.

Deliverables:

- Mixed asm + C kernel image.
- Stable `build/kernel.bin` artifact.

Exit criteria:

- The system boots and reaches C code deterministically.
- Existing `KERNEL_OK` and `PM_OK` behavior remains intact.

### Phase 2 - First Subsystem Migration

Goal: Move a contained subsystem into C while keeping low-level bootstrap in assembly.

Recommended first subsystem:

- VGA console init and output logic.

Tasks:

- Move selected logic from assembly to C.
- Keep assembly wrappers only where exact register behavior is required.
- Maintain current marker behavior and test coverage.

Deliverables:

- One production subsystem implemented in C.
- Assembly boundary reduced meaningfully.

Exit criteria:

- Existing subsystem tests still pass.
- C implementation is smaller-risk and easier to extend than the replaced assembly path.

### Phase 3 - Interrupt and Table Helpers in C

Goal: Move higher-level protected-mode setup logic into C while keeping naked stubs in assembly.

Tasks:

- Move IDT helper logic to C.
- Keep ISR entry stubs in assembly.
- Optionally move exception bookkeeping and dispatch helpers to C.

Deliverables:

- C-based setup logic for protected-mode runtime structures.

Exit criteria:

- Interrupt tests continue to pass with the mixed implementation.

### Phase 4 - Build and CI Finalization

Goal: Make the mixed asm + C kernel the default supported kernel architecture.

Tasks:

- Update CI package requirements if needed.
- Ensure `make check-all` remains the single aggregate validation target.
- Document local prerequisites and troubleshooting notes.

Deliverables:

- Stable mixed-language developer workflow.
- CI coverage for the C kernel path.

Exit criteria:

- CI runs the mixed kernel path reliably.
- The repo has a clear path for future migration of more subsystems.

## 3. Requirement Traceability

- **CK-1** (Assembly shim) -> Phase 1
- **CK-2** (C kernel entry) -> Phase 1
- **CK-3** (Build pipeline) -> Phase 1 and Phase 4
- **CK-4** (ABI contract) -> Phase 0
- **CK-5** (Incremental migration) -> Phase 2 onward

## 4. Test Coverage

|Test|Phase|Requirement|Success Condition|
|---|---|---|---|
|CK-T1|1|CK-1, CK-2|Assembly shim reaches C entry and emits C marker|
|CK-T2|1|CK-4|Protected-mode contract still valid at C entry|
|CK-T3|1-4|CK-1..CK-5|Existing boot, PM, IH, and VGA tests still pass|
|CK-T4|1|CK-3|`build/kernel.bin` remains bootable by current loader|
|CK-T5|2|CK-5|First migrated subsystem passes its prior tests unchanged|

## 5. Implementation Order

1. Freeze the ABI and linker plan.
2. Boot a trivial `kmain` from assembly.
3. Preserve the raw kernel binary output contract.
4. Migrate VGA console or another isolated subsystem to C.
5. Migrate helper logic around interrupts and descriptor tables.
6. Expand the C surface area only after existing tests are stable.

## 6. Risk Mitigation

- **Linker placement bugs**: keep the current kernel load address fixed in the first linker script.
- **ABI drift**: document register/stack assumptions before implementing `kmain`.
- **Toolchain issues**: verify CI can compile freestanding 32-bit objects before migrating behavior.
- **Overreach**: move only one subsystem at a time and keep tests green after each step.
