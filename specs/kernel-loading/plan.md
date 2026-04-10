# Kernel Loading Implementation Plan

## 1. Objective

Implement and stabilize the kernel-loading module contract defined in `spec.md` with deterministic behavior in QEMU and independent module-level validation.

Success criteria:

- Loader responsibilities LR-1..LR-5 are implemented and verified.
- Kernel responsibilities KR-1..KR-3 are implemented and verified.
- KL-T1..KL-T5 are reproducible locally and in CI.

## 2. Work Breakdown

### Phase 0 - Contract Lock and Alignment

Goal: Ensure spec constants and code assumptions are synchronized.

Tasks:

- Confirm fixed constants in code match spec:
  - KERNEL_START_LBA
  - KERNEL_SECTOR_COUNT range
  - KERNEL_LOAD_SEGMENT/OFFSET
  - entry address
- Confirm marker contract for kernel image (`KRNL` at expected offsets).
- Confirm error code mapping remains stable:
  - E1 disk/integrity path
  - E2 config path
- Confirm handoff contract assumptions documented and enforced.

Deliverables:

- Finalized constants table and contract notes in source comments/doc.

Exit criteria:

- No mismatch between spec constants and implementation constants.

### Phase 1 - Positive Load Path Hardening

Goal: Keep happy-path load stable and deterministic.

Tasks:

- Ensure fixed-range disk read path is explicit and readable.
- Ensure final jump target uses the fixed kernel entrypoint.
- Ensure kernel emits success marker (`KERNEL_OK`) in validation builds.
- Ensure build/image creation remains deterministic.

Deliverables:

- Stable positive boot path with consistent outputs.

Exit criteria:

- KL-T1 and KL-T5 pass repeatedly.

### Phase 2 - Integrity and Failure Path Hardening

Goal: Make failure modes explicit and reliable under corruption and invalid configs.

Tasks:

- Validate read status after each BIOS operation.
- Validate kernel marker immediately after load.
- Enforce config validation before read loop:
  - sector count lower/upper bounds
  - out-of-bounds load combinations
- Route failures to distinct indicators and halt path.

Deliverables:

- Reliable E1/E2 behavior for negative scenarios.

Exit criteria:

- KL-T3 and KL-T4 pass consistently.

### Phase 3 - Test Workflow and Reproducibility

Goal: Keep test entrypoints simple and standard for contributors and CI.

Tasks:

- Keep single-command execution (`make check-all`).
- Keep canonical per-test targets (`check-t1`..`check-t5`).
- Keep QEMU timeout controllable via environment variable.
- Keep debug artifacts consistent and easy to inspect.

Deliverables:

- Predictable local and CI workflow.

Exit criteria:

- KL-T1..KL-T5 pass locally and in CI with same command family.

## 3. Requirement Traceability

- LR-1 -> Fixed read loop and disk image layout tasks.
- LR-2 -> BIOS read-status validation and E1 routing tasks.
- LR-3 -> Kernel marker verification tasks.
- LR-4 -> Config guard tasks and E2 routing tasks.
- LR-5 -> Handoff and DL preservation tasks.
- KR-1 -> Startup contract compliance checks.
- KR-2 -> Success marker tasks.
- KR-3 -> DL reporting tasks.

## 4. Risks and Mitigations

Risk: Inconsistent drive-id expectations by boot mode.
Mitigation: Assert propagation consistency between loader and kernel rather than hardcoding one value.

Risk: Corruption tests become nondeterministic.
Mitigation: Corrupt a known sector deterministically and assert marker/error outcomes.

Risk: Drift between spec and implementation constants.
Mitigation: Keep constants centralized and verify in Phase 0 before feature changes.

Risk: CI/local mismatch.
Mitigation: Use the same make targets and script paths in both contexts.

## 5. Execution Order

1. Phase 0 contract alignment
2. Phase 1 happy-path hardening
3. Phase 2 failure-path hardening
4. Phase 3 test/reproducibility checks

## 6. Definition of Done

- KL-T1..KL-T5 pass locally.
- CI run executes the same suite successfully.
- Error paths E1/E2 are distinguishable and documented.
- Loader/kernel contract remains explicit and stable in spec and code.
