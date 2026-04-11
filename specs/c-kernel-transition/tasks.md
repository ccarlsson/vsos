# C Kernel Transition Task List

This checklist translates `spec.md` and `plan.md` into implementation-ready work.

## Phase 0 - Toolchain and ABI Lock

- [x] Confirm CI and local toolchain can compile freestanding 32-bit C objects.
  - [x] Added `make check-c-toolchain` probe target.
  - [x] Added CI package installation for GCC/binutils toolchain.
  - [x] Added a tracked freestanding probe source file.
- [x] Define the assembly-to-C entry contract.
  - [x] CPU mode at entry.
  - [x] Segment register expectations.
  - [x] Stack expectations.
  - [x] Interrupt state expectations.
  - [x] Boot metadata passing convention.
- [x] Define linker placement.
  - [x] Kernel virtual/linear load address.
  - [x] Section layout.
  - [x] Raw binary export flow.
- [x] Define source layout for mixed asm + C kernel.

## Phase 1 - Minimal Mixed-Language Boot

### Assembly Shim (CK-1)

- [x] Split current kernel entry path into a bootstrap shim and implementation boundary.
- [x] Add assembly callout to `kmain`.
- [x] Preserve current marker emission needed by tests.

### C Entry (CK-2)

- [x] Add freestanding C source file for kernel entry.
- [x] Add `kmain` implementation.
- [x] Emit a dedicated marker from C entry.
- [x] Provide minimal helper declarations for debug/VGA output.

### Build Pipeline (CK-3)

- [x] Add linker script.
- [x] Update Makefile to:
  - [x] Assemble NASM sources.
  - [x] Compile C sources.
  - [x] Link mixed objects.
  - [x] Convert linked output to `build/kernel.bin`.
- [x] Preserve existing disk image targets.

## Phase 1 - Validation

- [x] CK-T1: C entry marker present.
- [x] CK-T2: `PM_OK` still present before or during C entry handoff.
- [x] CK-T3: Existing bootloader tests still pass.
- [x] CK-T4: Existing kernel handoff test still passes using the raw binary.

## Phase 2 - First Subsystem Migration

- [ ] Select first subsystem for migration.
  - [x] Recommended: VGA console.
- [x] Move implementation to C.
- [x] Keep low-level wrappers in assembly only if needed.
- [x] Preserve public behavior and markers.

## Phase 2 - Validation

- [x] CK-T5: First migrated subsystem passes all prior tests.
- [x] `make check-vga-all` still passes if VGA is the first migrated subsystem.

## Phase 3 - Interrupt and Table Helper Migration

- [x] Move IDT setup helpers into C.
- [x] Keep ISR/exception entry stubs in assembly.
- [x] Optionally move exception bookkeeping helpers to C.
- [x] Preserve interrupt marker behavior.

## Phase 3 - Validation

- [x] `make check-ih-all` still passes.
- [x] `make check-pm-all` still passes.

## Phase 4 - CI and Developer Workflow

- [ ] Update CI dependencies if required by the chosen C toolchain.
- [ ] Keep `make check-all` as the aggregate validation command.
- [ ] Document local build prerequisites.
- [ ] Document mixed asm + C kernel layout for contributors.

## Requirement Traceability

- [ ] CK-1 (Assembly shim) -> Phase 1
- [ ] CK-2 (C kernel entry) -> Phase 1
- [ ] CK-3 (Build pipeline) -> Phase 1 and Phase 4
- [ ] CK-4 (ABI contract) -> Phase 0
- [ ] CK-5 (Incremental migration) -> Phase 2 onward

## Notes

- Do not rewrite the bootloader during this transition.
- Keep the raw kernel binary contract intact until the bootloader format is intentionally upgraded.
- Migrate one subsystem at a time; use the current test suite as the regression guardrail.
