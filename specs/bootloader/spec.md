# Bootloader Specification

## 1. Purpose

The bootloader is the first VSOS module to execute after BIOS hands off control.
Its job is to initialize the minimum execution environment and load the kernel from
disk into memory in a deterministic, testable way.

This module is intentionally simple and educational:

- Single architecture target: x86 (BIOS boot flow)
- Small, explicit steps with minimal hidden behavior
- Clear boundaries between assembly boot code and C kernel code

## 2. Scope

Included in scope:

- 16-bit real-mode boot sector entrypoint
- Basic CPU and segment setup needed for disk reads
- Loading a fixed kernel image from disk to a fixed memory address
- Minimal user-visible diagnostics for boot failures
- Transfer of execution to the loaded kernel entrypoint

Out of scope (for this module version):

- Filesystem parsing (FAT/ext/etc.)
- Multiboot compliance
- UEFI support
- Dynamic memory map handling beyond simple assumptions
- Protected mode or long mode transitions (unless separately specified)

## 3. Design Constraints

- Keep implementation small and readable for teaching.
- Keep boot path deterministic: no dynamic discovery required for the happy path.
- Keep dependencies minimal: BIOS interrupts only.
- Keep module testable in isolation via QEMU.

## 4. Execution Environment

- Platform: x86 with BIOS-compatible boot
- Initial mode: 16-bit real mode
- Toolchain assumptions:
	- NASM for assembly sources
	- GCC + linker for kernel binary (loaded artifact)
- Runtime target: QEMU for development/testing

## 5. Inputs and Outputs

Inputs:

- Boot disk image with:
	- Boot sector at LBA 0 (this module)
	- Kernel payload stored in a predefined contiguous LBA range
- Build-time constants:
	- `KERNEL_LOAD_SEGMENT = 0x1000`
	- `KERNEL_LOAD_OFFSET = 0x0000`
	- `KERNEL_START_LBA = 1`
	- `KERNEL_SECTOR_COUNT = 32` (default)

Outputs:

- On success: control transferred to kernel entrypoint at configured load address.
- On failure: visible error code/message and halted CPU loop.

## 6. Functional Requirements

### FR-1 Boot Signature

The produced boot sector must be exactly 512 bytes and end with signature
`0x55AA` at bytes 510-511.

### FR-2 Minimal CPU Setup

On entry, the bootloader must:

- Disable interrupts during critical setup where needed
- Initialize stack segment and stack pointer to a documented location
- Initialize data/code segment assumptions explicitly (do not rely on undefined state)

### FR-3 Boot Drive Preservation

The BIOS-provided boot drive identifier in register `DL` must be preserved and used
for all disk reads.

### FR-4 Kernel Read Strategy

The bootloader must read `KERNEL_SECTOR_COUNT` sectors beginning at
`KERNEL_START_LBA` into `KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET`.

Phase 0 decision: the initial implementation uses BIOS INT 13h CHS reads.

For deterministic tests, CHS translation assumes standard floppy geometry:

- Sectors per track: 18
- Heads: 2
- Cylinders: 80

### FR-5 Read Verification

Each BIOS disk read operation must be checked for failure (carry flag and/or status
code as applicable). On failure, the bootloader must enter the defined error path.

### FR-6 Control Handoff

After successful load, the bootloader must jump to the kernel entrypoint at the
configured address, with a documented register/segment contract.

### FR-7 Error Handling

At minimum, two distinguishable error outcomes must be implemented:

- Disk read failure
- Kernel bounds/configuration failure (e.g., invalid sector count)

For both outcomes, the bootloader must print a short message or code through BIOS
teletype and then halt (`cli` + `hlt` loop).

## 7. Non-Functional Requirements

### NFR-1 Simplicity

Control flow should remain understandable in a single reading session by students
new to OS bootstrapping.

### NFR-2 Modularity

Bootloader constants and memory layout assumptions must be isolated in one include
or clearly labeled constant section.

### NFR-3 Reproducibility

Given the same source and toolchain versions, boot image layout and loader behavior
must be reproducible.

## 8. Memory Layout Contract

This section must be synchronized with implementation constants:

- Bootloader loaded by BIOS at `0x0000:0x7C00`
- Stack location:
	- `STACK_SEGMENT = 0x0000`
	- `STACK_OFFSET = 0x7A00`
- Kernel load physical address:
	- `KERNEL_LOAD_SEGMENT = 0x1000`
	- `KERNEL_LOAD_OFFSET = 0x0000`
	- `phys = (KERNEL_LOAD_SEGMENT << 4) + KERNEL_LOAD_OFFSET`
	- `phys = 0x10000`
- Kernel entrypoint: same as load base unless documented otherwise
	- Entry: `0x1000:0x0000`

Kernel size policy for stage-1:

- Supported range for `KERNEL_SECTOR_COUNT`: `1..32`
- Maximum kernel payload size: `32 * 512 = 16384` bytes (16 KiB)
- Any value outside `1..32` must trigger configuration error path

## 9. Module Interface Contract (Bootloader -> Kernel)

The bootloader must document what state is guaranteed at handoff:

- CPU mode: real mode
- Interrupt state: disabled
- Register guarantees:
	- `DL` contains BIOS boot drive id
	- `CS:IP = 0x1000:0x0000` at entry
	- Other general-purpose registers are undefined unless otherwise documented
- Segment register guarantees:
	- `DS = 0x0000`
	- `ES = 0x0000`
	- `SS = 0x0000`
	- `SP = 0x7A00`

Kernel side must not assume undocumented state.

## 10. Test Specification (Independent Module Validation)

### T-1 Build Artifact Validation

- Verify boot sector size is 512 bytes.
- Verify signature bytes `0x55AA` exist at offset 510.

Acceptance:

- Pass if both checks succeed.

### T-2 Positive Boot Path (QEMU)

- Boot disk image in QEMU.
- Expect bootloader to load kernel and transfer control.
- Kernel test payload prints a unique success marker (e.g., `KERNEL_OK`).

Acceptance:

- Pass if `KERNEL_OK` is displayed within timeout.

### T-3 Disk Read Failure Path

- Corrupt or remove one kernel sector in test image.
- Boot in QEMU.

Acceptance:

- Pass if bootloader shows disk error indicator and halts.

### T-4 Invalid Configuration Path

- Build with invalid `KERNEL_SECTOR_COUNT` (0 or out-of-bounds).
- Boot in QEMU.

Acceptance:

- Pass if bootloader shows config error indicator and halts.

### T-5 Boot Drive Propagation

- Instrument kernel payload to print received drive id from `DL`.

Acceptance:

- Pass if kernel `DL` matches bootloader-preserved `DL` at handoff.
- Optionally enforce a fixed expected id for a pinned boot mode (for floppy, typically `0x00`).

## 11. Milestones

### M1: Bring-up

- Valid boot signature
- Message output from boot sector

### M2: Kernel Load

- Fixed-range sector read into memory
- Jump to kernel payload

### M3: Robustness

- Distinct error paths and halt behavior
- Automated QEMU checks for positive and negative cases

## 12. Phase 0 Decisions (Locked)

- Disk read strategy for v1: BIOS INT 13h CHS
- Fixed CHS geometry for tests: 18 sectors/track, 2 heads, 80 cylinders
- Stack location: `0x0000:0x7A00`
- Kernel load address: `0x1000:0x0000` (physical `0x10000`)
- Kernel start LBA: `1`
- Default sector count: `32`
- Allowed sector count range: `1..32`
- Stage strategy: stage-1 only for initial release (no stage-2 in scope)

## 13. Definition of Done

This spec is complete for implementation when:

- All functional requirements (FR-1 .. FR-7) have concrete constants assigned.
- Memory layout section contains final numeric addresses.
- Handoff contract is explicit and reflected in kernel startup code.
- All tests (T-1 .. T-5) are executable in CI or a documented local script.
