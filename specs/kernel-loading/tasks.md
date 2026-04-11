# Kernel Loading Task List

This checklist translates `spec.md` into implementation-ready work.

## Phase 0 - Contract Lock and Alignment

- [x] Verify implementation constants match spec:
  - [x] KERNEL_START_LBA
  - [x] KERNEL_SECTOR_COUNT default and allowed range
  - [x] KERNEL_LOAD_SEGMENT and KERNEL_LOAD_OFFSET
  - [x] KERNEL_ENTRY address
- [x] Verify kernel marker contract (`KRNL`) placement and offsets.
- [x] Verify error mapping:
  - [x] E1 = disk/integrity failure
  - [x] E2 = configuration failure
- [x] Verify handoff contract assumptions are documented and consistent.

## Phase 1 - Positive Path (KL-T1, KL-T2)

### Loader path

- [x] Ensure fixed-range read loop is explicit and deterministic.
- [x] Ensure jump target is fixed kernel entrypoint.

### Kernel path

- [x] Ensure validation payload emits `KERNEL_OK`.
- [x] Ensure validation payload emits received `DL` value.

### Validation

- [x] KL-T1: positive load path reports `KERNEL_OK`.
- [x] KL-T2: loader and kernel `DL` values match.

## Phase 2 - Negative Paths (KL-T3, KL-T4)

### Read/integrity handling

- [x] Check BIOS read status on every read operation.
- [x] Verify loaded marker after reads; route mismatch to E1.
- [x] Route read failure to E1.

### Configuration handling

- [x] Reject invalid `KERNEL_SECTOR_COUNT` lower bound.
- [x] Reject invalid `KERNEL_SECTOR_COUNT` upper bound.
- [x] Reject out-of-bounds combinations.
- [x] Route all config violations to E2.

### Fatal behavior

- [x] Ensure both E1 and E2 end in `cli` + `hlt` loop.

### Negative Path Validation

- [x] KL-T3: corrupted kernel sector triggers E1 and no `KERNEL_OK`.
- [x] KL-T4: invalid config variant triggers E2 and no `KERNEL_OK`.

## Phase 3 - Reproducibility and CI

### Local workflow

- [x] Keep one-command suite entrypoint (`make check-all`).
- [x] Keep per-test targets (`check-t1`..`check-t5`).
- [x] Keep timeout control (`QEMU_TIMEOUT_SECONDS`).

### CI workflow

- [x] CI executes `make check-all` on push and PR.
- [x] CI uploads debug artifacts on failure.

### Documentation

- [x] Verify `specs/kernel-loading/spec.md` matches implemented behavior.
- [x] Verify testing docs describe canonical commands and expected outputs.

## Requirement Traceability Checklist

- [x] LR-1 satisfied.
- [x] LR-2 satisfied.
- [x] LR-3 satisfied.
- [x] LR-4 satisfied.
- [x] LR-5 satisfied.
- [x] KR-1 satisfied.
- [x] KR-2 satisfied.
- [x] KR-3 satisfied.

## Done Criteria

- [x] KL-T1..KL-T5 pass locally.
- [x] CI passes with same canonical test flow.
- [x] E1 and E2 behaviors are distinct and stable.
- [x] Spec and implementation constants remain synchronized.
