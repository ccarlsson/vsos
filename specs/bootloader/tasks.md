# Bootloader Task List

This checklist translates the implementation plan into concrete, file-level work items.

## Phase 0 - Design Lock

- [x] Select disk read strategy for v1:
  - [x] CHS via INT 13h
  - [ ] or LBA extensions via INT 13h
- [x] Finalize boot memory map constants:
  - [x] KERNEL_LOAD_SEGMENT = 0x1000
  - [x] KERNEL_LOAD_OFFSET = 0x0000
  - [x] KERNEL_START_LBA = 1
  - [x] KERNEL_SECTOR_COUNT = 32 (default)
  - [x] STACK_SEGMENT / STACK_OFFSET = 0x0000:0x7A00
- [x] Define maximum supported kernel size policy.
- [x] Define explicit handoff contract:
  - [x] CPU mode at handoff
  - [x] interrupt state at handoff
  - [x] segment register guarantees
  - [x] register guarantees (DL required)
- [x] Update spec placeholders with final numbers and choices in spec.md.

## Phase 1 - Boot Sector Bring-up (M1)

### Assembly implementation

- [x] Create stage-1 bootloader source (16-bit NASM) with origin at 0x7C00.
- [x] Add explicit entry label and startup sequence.
- [x] Initialize segment registers deterministically.
- [x] Initialize stack to chosen address.
- [x] Add BIOS teletype print routine (INT 10h) for diagnostics.
- [x] Add early startup marker message.

### Binary layout

- [x] Ensure boot sector pads/truncates to exactly 512 bytes.
- [x] Emit boot signature 0x55AA at bytes 510-511.

### Validation (Phase 2)

- [x] Add size/signature verification command/script for T-1.
- [x] Boot in QEMU and confirm startup marker appears.

## Phase 2 - Kernel Load and Handoff (M2)

### Read path

- [x] Preserve BIOS boot drive id from DL at entry.
- [x] Implement sector read routine for fixed range:
  - [x] start at KERNEL_START_LBA
  - [x] read KERNEL_SECTOR_COUNT sectors
  - [x] write into KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET
- [x] Check result of each BIOS read operation.

### Handoff

- [x] Jump to kernel entrypoint at configured load address.
- [x] Preserve/document required registers at handoff (DL minimum).

### Validation (Phase 3)

- [x] Create minimal kernel test payload that prints KERNEL_OK.
- [x] Run QEMU positive test and verify KERNEL_OK (T-2).
- [x] Add boot drive print in test payload and verify expected value (T-5).

## Phase 3 - Error Paths and Robustness (M3)

### Configuration validation

- [x] Reject KERNEL_SECTOR_COUNT == 0.
- [x] Reject out-of-bounds kernel load config per chosen policy.
- [x] Route invalid config to dedicated error handler.

### Read failure handling

- [x] Route BIOS read failure to dedicated disk error handler.
- [x] Emit distinct short error indicators for:
  - [x] disk read failure
  - [x] configuration failure
- [x] Implement fatal halt loop (cli + hlt).

### Validation

- [x] Corrupt kernel sector in test image and verify disk error + halt (T-3).
- [x] Build invalid configuration variant and verify config error + halt (T-4).

## Phase 4 - Test Automation and Reproducibility

### Scripted workflow

- [x] Add a single command target/script to run T-1.
- [x] Add a single command target/script to run T-2.
- [x] Add a single command target/script to run T-3.
- [x] Add a single command target/script to run T-4.
- [x] Add a single command target/script to run T-5.
- [x] Standardize timeouts and output markers.

### Documentation

- [x] Document exact local commands for build and all tests.
- [x] Document expected outputs and failure indicators.
- [x] Document fixed QEMU parameters to keep tests deterministic.

### Optional CI

- [x] Add CI job that runs T-1..T-5 on push/PR.

## Requirement Traceability Checklist

- [x] FR-1 satisfied (size + signature).
- [x] FR-2 satisfied (minimal CPU setup).
- [x] FR-3 satisfied (DL preservation).
- [x] FR-4 satisfied (fixed-range kernel read).
- [x] FR-5 satisfied (read verification).
- [x] FR-6 satisfied (documented handoff).
- [x] FR-7 satisfied (distinct error outcomes).
- [x] NFR-1 satisfied (simplicity/readability).
- [x] NFR-2 satisfied (constants modularized).
- [x] NFR-3 satisfied (reproducible workflow).

## Done Criteria

- [x] Spec contains no unresolved placeholders.
- [x] Positive boot path passes with KERNEL_OK.
- [x] Negative paths pass for disk and config errors.
- [x] Handoff contract is verified by kernel test payload.
- [x] All tests are runnable by a new contributor using documented commands.
