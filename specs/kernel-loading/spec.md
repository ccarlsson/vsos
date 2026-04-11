# Kernel Loading Specification

## 1. Purpose

This module specifies how VSOS kernel code is packaged, loaded, verified, and
entered after BIOS boot.

It is designed for teaching and incremental growth:

- Keep logic deterministic and easy to trace in QEMU.
- Keep the bootloader/kernel boundary explicit.
- Keep each behavior independently testable.

## 2. Context

The bootloader module is already functional and currently loads a fixed kernel
region from disk using BIOS INT 13h CHS.

This spec defines the kernel-loading contract that the bootloader and kernel
must share.

## 3. Scope

In scope:

- Kernel image layout expected by the loader
- Fixed disk placement and load destination for stage-1
- Loader-side integrity checks before handoff
- Kernel entry contract at `CS:IP = 0x1000:0x0000`
- Test criteria for success and error outcomes in QEMU

Out of scope (this version):

- Filesystem-aware loading (FAT/ext)
- Relocation and dynamic linking
- Protected mode / long mode transitions
- ELF parsing
- Multi-file kernel modules

## 4. Constraints (from VSOS context)

- Architecture: x86
- Languages/tooling: Assembly + C, NASM + GCC
- Runtime: QEMU
- Keep everything simple
- Keep modules independently testable

## 5. Fixed Constants (v1)

- `KERNEL_START_LBA = 1`
- `KERNEL_SECTOR_COUNT = 32` (allowed range: `1..32`)
- `KERNEL_LOAD_SEGMENT = 0x1000`
- `KERNEL_LOAD_OFFSET = 0x0000`
- `KERNEL_ENTRY = 0x1000:0x0000`
- Max kernel payload in stage-1 flow: `32 * 512 = 16384` bytes

## 6. Kernel Image Contract

The kernel payload is a flat binary loaded at `0x1000:0x0000`.

Required prefix contract (current v1 behavior):

- First instruction may jump over header bytes.
- Bytes at offset `+2..+5` must contain marker `KRNL`.

Purpose:

- Allows loader-side quick integrity detection before entering kernel code.
- Keeps validation simple without introducing complex binary formats.

## 7. Loader Responsibilities

### LR-1 Read Fixed Kernel Range

Read `KERNEL_SECTOR_COUNT` sectors from disk starting at `KERNEL_START_LBA`
into `KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET`.

### LR-2 Validate Read Operations

Each BIOS read call must be checked for failure. Any read failure routes to disk
error path (`E1`) and halts.

### LR-3 Validate Kernel Marker

After successful reads, verify the `KRNL` marker at expected offsets in loaded
memory. On mismatch, route to disk/integrity error path (`E1`) and halt.

### LR-4 Validate Configuration

Before reads, reject invalid configuration values (sector count zero,
out-of-range, or out-of-bounds combination). On failure, route to config error
path (`E2`) and halt.

### LR-5 Handoff State

Before jump to kernel entrypoint:

- Preserve boot drive id in `DL`.
- Jump to `0x1000:0x0000`.
- Keep behavior deterministic and documented (real mode, known segment/stack
 assumptions from bootloader spec).

## 8. Kernel Responsibilities at Entry

### KR-1 Do Not Assume Undocumented State

Kernel startup code must only depend on documented handoff values.

### KR-2 Publish Success Marker

For validation builds, kernel must emit `KERNEL_OK` so positive-path tests can
assert successful handoff.

### KR-3 Publish Received Boot Drive

For propagation tests, kernel must emit received `DL` value (e.g., `DL=00`) so
the loader->kernel register contract can be verified.

## 9. Error Model

- `E1`: disk read/integrity error
- `E2`: invalid loading configuration

Fatal behavior for both:

- Emit error marker
- Enter `cli` + `hlt` loop

## 10. Test Specification

### KL-T1 Positive Load Path

- Build disk image with valid bootloader + kernel payload
- Boot in QEMU

Acceptance:

- `KERNEL_OK` observed

### KL-T2 Boot Drive Propagation

- Boot in QEMU and capture loader + kernel `DL` markers

Acceptance:

- Loader and kernel values match

### KL-T3 Corrupted Kernel Sector

- Corrupt one kernel sector in test image
- Boot in QEMU

Acceptance:

- `E1` observed
- `KERNEL_OK` absent

### KL-T4 Invalid Config Variant

- Build with invalid `KERNEL_SECTOR_COUNT` (for example `0`)
- Boot in QEMU

Acceptance:

- `E2` observed
- `KERNEL_OK` absent

### KL-T5 Reproducible Local Run

- Execute canonical suite command

Acceptance:

- All kernel-loading tests pass with documented command flow

## 11. Implementation Notes (v1)

- Kernel binary is currently small and intentionally flat.
- Header check uses fixed marker bytes, not checksums.
- Design favors readability over throughput.

## 12. Future Evolution (Non-v1)

- Replace fixed sector range with filesystem or image table
- Introduce checksum/CRC integrity instead of marker-only check
- Move to stage-2 loader for larger kernels
- Transition from pure flat binary assumptions toward structured format

## 13. Definition of Done

This module is done for v1 when:

- Loader and kernel satisfy LR-1..LR-5 and KR-1..KR-3
- All tests KL-T1..KL-T5 pass in QEMU
- Constants and entry contract are documented and synchronized with code
