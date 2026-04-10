# Protected Mode Task List

This checklist translates `spec.md` into implementation-ready work.

## Phase 0 - Design Lock

- [ ] Choose transition location:
  - [ ] bootloader-side transition block
  - [ ] kernel early transition stub
- [ ] Finalize selector constants:
  - [ ] CODE_SEL
  - [ ] DATA_SEL
- [ ] Finalize 32-bit stack top address.
- [ ] Finalize A20 strategy for v1.
- [ ] Finalize marker strings/codes:
  - [ ] PM_OK
  - [ ] P1
  - [ ] P2

## Phase 1 - Minimal Transition Path

### A20

- [ ] Implement A20 enable path.
- [ ] Implement A20 verification check.

### GDT and mode switch

- [ ] Define minimal GDT (null, code, data).
- [ ] Load GDTR with `lgdt`.
- [ ] Set `CR0.PE = 1`.
- [ ] Execute required far jump to 32-bit code selector.

### 32-bit entry

- [ ] Initialize `DS`, `ES`, `FS`, `GS`, `SS` with data selector.
- [ ] Initialize `ESP` to documented 32-bit stack top.
- [ ] Emit `PM_OK` marker over debug channel.

### Validation

- [ ] PM-T1: positive transition emits PM_OK.

## Phase 2 - Failure Paths

### Error paths

- [ ] Route A20 failure to P1.
- [ ] Route GDT/selector transition failure variant to P2.
- [ ] Ensure both failure paths halt with `cli` + `hlt` loop.

### Validation

- [ ] PM-T2: A20 failure scenario emits P1 and no PM_OK.
- [ ] PM-T3: transition failure scenario emits P2 and no PM_OK.

## Phase 3 - Reproducibility and CI

### Local workflow

- [ ] Add canonical protected-mode test scripts under `tests/`.
- [ ] Add make targets for PM tests (`check-pm-t1`, `check-pm-t2`, `check-pm-t3`).
- [ ] Add aggregate PM target (`check-pm-all`).

### CI workflow

- [ ] Update CI to execute protected-mode test target(s).
- [ ] Upload PM debug artifacts on failure.

### Documentation

- [ ] Keep `specs/protected-mode/spec.md` synchronized with implementation.
- [ ] Document PM test commands and expected markers.

## Requirement Traceability Checklist

- [ ] PM-FR-1 satisfied.
- [ ] PM-FR-2 satisfied.
- [ ] PM-FR-3 satisfied.
- [ ] PM-FR-4 satisfied.
- [ ] PM-FR-5 satisfied.
- [ ] PM-FR-6 satisfied.

## Done Criteria

- [ ] PM-T1..PM-T4 pass locally.
- [ ] CI runs and passes protected-mode tests.
- [ ] PM_OK/P1/P2 behavior is deterministic.
- [ ] Transition constants and contracts are documented and synchronized.
