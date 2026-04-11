# C Kernel Transition Specification

## 1. Purpose

This module specifies how VSOS transitions kernel implementation from pure assembly to a mixed assembly + freestanding C architecture.

The intent is to keep the hardware-critical bootstrap path small and stable while allowing higher-level kernel logic to be written in C.

Goals:

- Preserve the current bootloader and disk layout contract.
- Keep the protected-mode entry path deterministic and testable.
- Minimize assembly to the parts that require exact machine control.
- Enable incremental migration of kernel subsystems without rewriting the boot path.

## 2. Context

The current VSOS kernel is assembled directly from [src/kernel/stage0/kernel.asm](../src/kernel/stage0/kernel.asm) into a flat binary written to sector 1 of the disk image.

Today, the kernel already performs these critical steps successfully:

- Starts from a raw bootloader handoff.
- Enables A20.
- Loads a GDT.
- Enters 32-bit protected mode.
- Establishes segment registers and stack.
- Runs protected-mode kernel logic.
- Handles interrupts and exceptions.
- Emits serial/debug markers used by the test harness.

That means VSOS is already at the point where a freestanding C entry function can be introduced behind a small assembly shim.

## 3. Scope

In scope:

- Introduce a protected-mode assembly shim that calls a C kernel entry point.
- Introduce a linker-driven kernel build instead of direct flat assembly-only output.
- Preserve output artifact compatibility with the current bootloader (`build/kernel.bin`).
- Migrate selected kernel logic from assembly to C incrementally.
- Keep interrupt and exception entry stubs in assembly initially.
- Maintain compatibility with current marker-based QEMU tests.

Out of scope (this version):

- Rewriting the boot sector in C.
- Rewriting real-mode logic in C.
- Paging, user mode, ELF loading in bootloader, or dynamic relocation.
- Replacing all assembly immediately.
- Rust support (covered by a separate future transition path).

## 4. Constraints (from VSOS context)

- Architecture: x86, 16-bit real mode boot to 32-bit protected mode kernel.
- Current kernel load address: `0x00010000` linear.
- Current kernel packaging: raw flat binary placed at sector 1 in disk image.
- Current toolchain baseline: NASM, Make, QEMU, shell-based tests.
- Test contract: marker strings captured from debugcon output must remain stable.
- CI must remain headless and reproducible.

## 5. Fixed Architectural Decisions

### Bootstrap Boundary

The following code remains in assembly for the initial C transition:

- Real-mode startup and bootloader handoff handling.
- A20 enable and verification logic.
- GDT setup and protected-mode switch.
- Far jump into 32-bit code.
- Initial protected-mode stack and segment setup.
- Exception and interrupt entry stubs.

### C Boundary

The following code becomes eligible for C migration once the boundary exists:

- VGA console logic.
- Kernel init sequence after protected-mode entry.
- IDT table setup helpers.
- Higher-level interrupt dispatch logic.
- Memory/string helper routines.
- General kernel subsystems that do not depend on raw entry semantics.

### Locked Phase 0 Entry Contract

The initial asm-to-C boundary is locked to the current kernel entry behavior:

- CPU mode at C entry: 32-bit protected mode.
- Paging state: disabled.
- Code selector: `CODE_SEL = 0x08`.
- Data selector: `DATA_SEL = 0x10`.
- Segment registers on entry: `ds = es = fs = gs = ss = DATA_SEL`.
- Stack setup before `call kmain`: `esp = PM_STACK_TOP = 0x0009FC00`.
- Interrupt state at first C entry: interrupts disabled (`IF = 0`).
- Kernel load base remains `KERNEL_LINEAR_BASE = 0x00010000`.

This means the C entry point can assume a flat 32-bit address space with a valid downward-growing stack and no asynchronous interrupts until the kernel enables them explicitly.

### Output Artifact Contract

The bootloader contract stays unchanged in the first transition:

- Kernel output file remains `build/kernel.bin`.
- Disk image layout remains boot sector at LBA 0, kernel beginning at LBA 1.
- Bootloader remains unaware of C or ELF internals.

This implies the C build must ultimately emit a raw binary compatible with the current loader.

### Locked Phase 0 Link Model

The first C transition uses the following link model:

- Link target format: ELF32 i386 during intermediate link step.
- Final boot artifact: flat raw binary produced from the linked image.
- Final output path: `build/kernel.bin`.
- Bootloader-facing disk layout remains unchanged.
- Sections are expected to be laid out contiguously beginning at `0x00010000`.

## 6. Responsibilities

### CK-1: Assembly Shim

Provide a minimal 32-bit assembly entry shim that:

- Runs after the mode switch.
- Initializes `ds`, `es`, `fs`, `gs`, `ss`.
- Establishes a valid stack.
- Preserves any boot metadata that must be passed forward.
- Calls a C kernel entry function.

### CK-2: C Kernel Entry

Provide a freestanding C entry function, for example `kmain`, that:

- Assumes protected mode is already active.
- Assumes a valid stack and flat segmentation model.
- Performs higher-level kernel initialization.
- Preserves the existing externally visible behavior used by tests.

### CK-3: Build Pipeline

Provide a linker-driven build that:

- Compiles C as freestanding 32-bit objects.
- Links assembly and C into a fixed-address kernel image.
- Converts the linked result into a flat binary.
- Produces `build/kernel.bin` for the existing image build.

### CK-4: ABI Contract

Define a stable asm-to-C contract covering:

- CPU mode.
- Stack validity.
- Segment setup.
- Interrupt enable/disable state.
- Calling convention.
- Optional boot metadata passing.

For Phase 0, boot metadata passing is locked to the conservative option:

- No register arguments are passed into `kmain` initially.
- The boot drive remains stored by assembly in kernel memory and can later be wrapped in a C-visible structure.

### CK-5: Incremental Migration

Support subsystem-by-subsystem migration rather than a full rewrite.

The first recommended subsystem for C migration is VGA console output, because it is already isolated, testable, and does not require modifying the bootloader contract.

## 7. Call Contract

### Assembly to C Entry

Recommended initial contract:

```text
Input:
  CPU in 32-bit protected mode
  Flat segments loaded
  ds = es = fs = gs = ss = DATA_SEL (0x10)
  esp = PM_STACK_TOP before call into C
  Interrupts disabled
  No register arguments passed initially

Output:
  Control either returns to shim or enters kernel halt loop

Side effects:
  C code may initialize kernel subsystems, update VGA/debug output, install tables
```

### Interrupt Path (Initial State)

Interrupt and exception stubs remain assembly-first:

```text
Assembly stub:
  saves machine state
  records vector/error metadata
  calls C helper only after ABI is stable
  restores state or halts as required
```

## 8. Build Requirements

### Source Layout (Recommended)

Recommended first-step layout:

```text
src/kernel/stage0/kernel.asm        ; hardware-critical bootstrap + stubs
src/kernel/stage1/kmain.c           ; first C kernel body
src/kernel/linker.ld                ; kernel linker script
include/kernel/*.h                  ; freestanding kernel headers
```

Phase 0 locks this layout as the target structure for Phase 1 implementation.

### Toolchain Requirements

Required capabilities:

- NASM for assembly.
- A C compiler capable of freestanding 32-bit object generation.
- GNU `ld` or equivalent linker capable of fixed-address 32-bit linking.
- `objcopy` or equivalent to convert linked output to raw binary.

Recommended compile/link characteristics:

- `-ffreestanding`
- `-m32`
- `-fno-pic`
- `-fno-pie`
- `-nostdlib` at link stage
- fixed linker script placement at kernel load address

## 9. Test Criteria

### CK-T1: Assembly Shim Calls C Entry

- Build kernel through mixed asm + C pipeline.
- Boot normally.
- Confirm existing kernel handoff marker still appears.
- Confirm C entry emits a unique success marker.

### CK-T2: Protected Mode Contract Preserved

- Confirm `PM_OK` still appears with C entry in place.
- Confirm stack-sensitive C code executes reliably.

### CK-T3: Existing Marker Behavior Preserved

- Existing bootloader, protected-mode, interrupt, and VGA tests continue to pass.
- Marker names remain stable unless explicitly versioned.

### CK-T4: Raw Binary Contract Preserved

- `build/kernel.bin` remains bootable by current bootloader.
- Disk layout does not change.

### CK-T5: First Subsystem Migrated

- Migrate one isolated subsystem to C.
- Verify no behavioral regression through existing tests.

## 10. Integration Points

### With Bootloader

- No changes required in the initial transition.
- Bootloader continues loading a raw kernel image from sector 1.

### With Current Kernel Assembly

- Existing kernel assembly becomes the boundary layer rather than the full implementation.
- Protected-mode entry will eventually call into C instead of containing all kernel logic inline.

### With Test Harness

- Marker-based tests remain the primary regression safety net.
- QEMU-based test scripts remain valid if the external marker contract is preserved.

## 11. Risks

- Toolchain mismatch for 32-bit freestanding C objects.
- Incorrect linker placement producing an invalid raw binary.
- ABI mismatch between assembly shim and C entry.
- Implicit assembly assumptions not captured in the C boundary.
- Excessive migration scope causing regressions across many phases at once.

## 12. Notes

- This transition should be treated as an architectural refactor under stable behavior, not a rewrite.
- The first milestone is not “kernel in C”; it is “assembly reduced to a stable boundary.”
- C is chosen first because it minimizes build-system and runtime complexity compared with Rust.
