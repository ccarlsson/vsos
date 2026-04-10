# Bootloader Implementation Plan

## 1. Objective

Implement the bootloader module described in `spec.md` as a small, deterministic,
independently testable unit for x86 BIOS boot in QEMU.

Success criteria:

- All functional requirements FR-1..FR-7 are implemented.
- Non-functional constraints (simplicity, modularity, reproducibility) are upheld.
- Tests T-1..T-5 run reliably in local development.

## 2. Work Breakdown Structure

### Phase 0 - Decisions and Constants (Design Lock)

Goal: Resolve all open decisions that block implementation details.

Tasks:

- Choose disk read approach for initial release:
  - Option A (recommended): BIOS INT 13h CHS for simplicity.
  - Option B: BIOS INT 13h extensions (LBA).
- Choose stack location and document exact address.
- Define kernel load address constants:
  - KERNEL_LOAD_SEGMENT
  - KERNEL_LOAD_OFFSET
  - KERNEL_START_LBA
  - KERNEL_SECTOR_COUNT
- Define max kernel size policy and overflow behavior.
- Define handoff contract details:
  - Interrupt state at jump
  - Segment register values
  - Register guarantees (especially DL)

Deliverables:

- Finalized constants table.
- Updated memory layout and interface contract values in `spec.md`.

Exit criteria:

- No placeholders remain in sections 8, 9, and 12 of `spec.md`.

### Phase 1 - Boot Sector Bring-up (M1)

Goal: Produce a valid 512-byte boot sector with known execution baseline.

Tasks:

- Create boot sector entrypoint in 16-bit assembly.
- Implement FR-1:
  - Ensure image is exactly 512 bytes.
  - Ensure signature 0x55AA at bytes 510-511.
- Implement minimal setup from FR-2:
  - Controlled interrupt handling.
  - Deterministic segment initialization.
  - Stack initialization to chosen location.
- Add simple BIOS teletype routine for diagnostics.
- Print minimal startup marker (for early debugging).

Deliverables:

- Assembled boot sector binary.
- Boot image containing boot sector.

Exit criteria:

- T-1 passes.
- QEMU boots and displays startup marker.

### Phase 2 - Kernel Load Path (M2)

Goal: Load kernel sectors from disk to fixed memory and jump to kernel.

Tasks:

- Preserve BIOS boot drive id from DL (FR-3).
- Implement disk read loop for fixed sector range (FR-4).
- Validate read status for every BIOS read call (FR-5).
- Jump to kernel entrypoint using documented contract (FR-6).
- Create minimal kernel test payload that prints KERNEL_OK.

Deliverables:

- Working fixed-range load implementation.
- Minimal kernel payload for validation.

Exit criteria:

- T-2 passes.
- T-5 passes.

### Phase 3 - Failure Modes and Robustness (M3)

Goal: Make failures explicit, distinguishable, and testable.

Tasks:

- Add pre-read configuration validation (FR-7):
  - Reject zero/invalid KERNEL_SECTOR_COUNT.
  - Reject out-of-bounds combinations based on chosen policy.
- Add disk read failure path (FR-7).
- Add at least two distinct error outputs via BIOS teletype:
  - Disk read error indicator.
  - Configuration error indicator.
- Implement halt behavior: cli + hlt loop.

Deliverables:

- Distinct error handlers.
- Robust halt-on-failure flow.

Exit criteria:

- T-3 passes.
- T-4 passes.

### Phase 4 - Test Automation and Reproducibility

Goal: Make validation repeatable and easy for independent module testing.

Tasks:

- Add scripts/commands for:
  - Build artifact checks (size/signature).
  - QEMU positive path run with log capture.
  - Negative-path image manipulation for T-3.
  - Invalid configuration variant for T-4.
- Standardize timeout values and output markers.
- Document exact local run commands.
- Optional: wire tests into CI.

Deliverables:

- Repeatable local test workflow.
- Optional CI job for T-1..T-5.

Exit criteria:

- All T-1..T-5 are executable by a new contributor using documented steps.

## 3. Requirement-to-Task Traceability

- FR-1 -> Phase 1 boot sector layout/signature tasks.
- FR-2 -> Phase 1 CPU/segment/stack setup tasks.
- FR-3 -> Phase 2 DL preservation task.
- FR-4 -> Phase 2 fixed-range disk read tasks.
- FR-5 -> Phase 2 read-status validation tasks.
- FR-6 -> Phase 2 control handoff task.
- FR-7 -> Phase 3 validation and error-path tasks.
- NFR-1 -> Keep small routines, clear control flow, limited branching.
- NFR-2 -> Central constants section/include.
- NFR-3 -> Locked toolchain versions and scripted test flow.

## 4. Suggested Task Order (Day-by-Day)

Day 1:

- Complete Phase 0 decisions.
- Start and finish Phase 1.

Day 2:

- Complete Phase 2 with KERNEL_OK positive path.

Day 3:

- Complete Phase 3 failure paths.
- Start Phase 4 test scripting.

Day 4:

- Finish Phase 4 automation and documentation.
- Run full validation pass.

## 5. Risks and Mitigations

Risk: CHS geometry mismatch across environments.
Mitigation: Pin QEMU settings and geometry assumptions in tests.

Risk: Boot sector exceeds 512-byte limit due to diagnostics.
Mitigation: Keep stage-1 minimal and compress messages to short error codes.

Risk: Ambiguous handoff contract causes kernel startup bugs.
Mitigation: Document register/segment contract and verify with a dedicated test payload.

Risk: Hard-to-debug early boot failures.
Mitigation: Use deterministic markers at each boot stage and maintain a strict error code table.

## 6. Definition of Done Checklist

- [ ] Constants finalized and reflected in `spec.md`.
- [ ] Boot sector is 512 bytes with 0x55AA signature.
- [ ] Stack and segments initialized explicitly.
- [ ] DL boot drive preserved and used for all reads.
- [ ] Kernel sectors loaded from fixed range to fixed address.
- [ ] Read errors detected and routed to disk error handler.
- [ ] Invalid configuration routed to config error handler.
- [ ] Successful jump to kernel entrypoint validated by KERNEL_OK.
- [ ] Halt loop behavior implemented for all fatal errors.
- [ ] T-1..T-5 reproducibly pass using documented commands.
