# C Kernel Transition Task List

This checklist translates `spec.md` and `plan.md` into implementation-ready work.

## Phase 0 - Toolchain and ABI Lock

- [ ] Confirm CI and local toolchain can compile freestanding 32-bit C objects.
- [ ] Define the assembly-to-C entry contract.
  - [ ] CPU mode at entry.
  - [ ] Segment register expectations.
  - [ ] Stack expectations.
  - [ ] Interrupt state expectations.
  - [ ] Boot metadata passing convention.
- [ ] Define linker placement.
  - [ ] Kernel virtual/linear load address.
  - [ ] Section layout.
  - [ ] Raw binary export flow.
- [ ] Define source layout for mixed asm + C kernel.

## Phase 1 - Minimal Mixed-Language Boot

### Assembly Shim (CK-1)

- [ ] Split current kernel entry path into a bootstrap shim and implementation boundary.
- [ ] Add assembly callout to `kmain`.
- [ ] Preserve current marker emission needed by tests.

### C Entry (CK-2)

- [ ] Add freestanding C source file for kernel entry.
- [ ] Add `kmain` implementation.
- [ ] Emit a dedicated marker from C entry.
- [ ] Provide minimal helper declarations for debug/VGA output.

### Build Pipeline (CK-3)

- [ ] Add linker script.
- [ ] Update Makefile to:
  - [ ] Assemble NASM sources.
  - [ ] Compile C sources.
  - [ ] Link mixed objects.
  - [ ] Convert linked output to `build/kernel.bin`.
- [ ] Preserve existing disk image targets.

## Phase 1 - Validation

- [ ] CK-T1: C entry marker present.
- [ ] CK-T2: `PM_OK` still present before or during C entry handoff.
- [ ] CK-T3: Existing bootloader tests still pass.
- [ ] CK-T4: Existing kernel handoff test still passes using the raw binary.

## Phase 2 - First Subsystem Migration

- [ ] Select first subsystem for migration.
  - [ ] Recommended: VGA console.
- [ ] Move implementation to C.
- [ ] Keep low-level wrappers in assembly only if needed.
- [ ] Preserve public behavior and markers.

## Phase 2 - Validation

- [ ] CK-T5: First migrated subsystem passes all prior tests.
- [ ] `make check-vga-all` still passes if VGA is the first migrated subsystem.

## Phase 3 - Interrupt and Table Helper Migration

- [ ] Move IDT setup helpers into C.
- [ ] Keep ISR/exception entry stubs in assembly.
- [ ] Optionally move exception bookkeeping helpers to C.
- [ ] Preserve interrupt marker behavior.

## Phase 3 - Validation

- [ ] `make check-ih-all` still passes.
- [ ] `make check-pm-all` still passes.

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
