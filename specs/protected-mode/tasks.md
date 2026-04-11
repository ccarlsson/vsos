# Protected Mode Task List

This checklist translates `spec.md` into implementation-ready work.

## Phase 0 - Design Lock

- [x] Choose transition location:
  - [ ] bootloader-side transition block
  - [x] kernel early transition stub
- [x] Finalize selector constants:
  - [x] CODE_SEL = 0x08
  - [x] DATA_SEL = 0x10
- [x] Finalize 32-bit stack top address. (`ESP = 0x0009FC00`)
- [x] Finalize A20 strategy for v1. (fast gate via port 0x92 + verify)
- [x] Finalize marker strings/codes:
  - [x] PM_OK
  - [x] P1
  - [x] P2

## Phase 1 - Minimal Transition Path

### A20

- [x] Implement A20 enable path.
- [x] Implement A20 verification check.

### GDT and mode switch

- [x] Define minimal GDT (null, code, data).
- [x] Load GDTR with `lgdt`.
- [x] Set `CR0.PE = 1`.
- [x] Execute required far jump to 32-bit code selector.

### 32-bit entry

- [x] Initialize `DS`, `ES`, `FS`, `GS`, `SS` with data selector.
- [x] Initialize `ESP` to documented 32-bit stack top.
- [x] Emit `PM_OK` marker over debug channel.

### Failure validation

- [x] PM-T1: positive transition emits PM_OK.

## Phase 2 - Failure Paths

### Error paths

- [x] Route A20 failure to P1.
- [x] Route GDT/selector transition failure variant to P2.
- [x] Ensure both failure paths halt with `cli` + `hlt` loop.

### Validation

- [x] PM-T2: A20 failure scenario emits P1 and no PM_OK.
- [x] PM-T3: transition failure scenario emits P2 and no PM_OK.

## Phase 3 - Reproducibility and CI

### Local workflow

- [x] Add canonical protected-mode test scripts under `tests/`.
- [x] Add make targets for PM tests (`check-pm-t1`, `check-pm-t2`, `check-pm-t3`).
- [x] Add aggregate PM target (`check-pm-all`).

### CI workflow

- [ ] Update CI to execute protected-mode test target(s).
- [ ] Upload PM debug artifacts on failure.

### Documentation

- [ ] Keep `specs/protected-mode/spec.md` synchronized with implementation.
- [ ] Document PM test commands and expected markers.

## Requirement Traceability Checklist

- [x] PM-FR-1 satisfied.
- [x] PM-FR-2 satisfied.
- [x] PM-FR-3 satisfied.
- [x] PM-FR-4 satisfied.
- [x] PM-FR-5 satisfied.
- [x] PM-FR-6 satisfied.

## Done Criteria

- [ ] PM-T1..PM-T4 pass locally.
- [ ] CI runs and passes protected-mode tests.
- [ ] PM_OK/P1/P2 behavior is deterministic.
- [ ] Transition constants and contracts are documented and synchronized.
