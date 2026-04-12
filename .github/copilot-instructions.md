# Copilot Instructions

## Build and test commands

- Build the bootloader and default kernel artifacts: `make all`
- Verify the 32-bit freestanding C toolchain before touching kernel C code: `make check-c-toolchain`
- Run the full regression suite locally with the same timeout convention used in CI: `QEMU_TIMEOUT_SECONDS=5 make check-all`
- Run focused suites when working in one subsystem:
  - `make check-pm-all`
  - `make check-ih-all`
  - `make check-hi-all`
  - `make check-vga-all`
- Run individual tests from `make` targets rather than invoking scripts directly. Common single-test targets:
  - `make check-boot`
  - `make check-qemu-m1`
  - `make check-qemu-m2`
  - `make check-qemu-t3`
  - `make check-qemu-t4`
  - `make check-qemu-t5`
  - `make check-pm-t1`
  - `make check-pm-t2`
  - `make check-pm-t3`
  - `make check-ih-t1`
  - `make check-ih-t2`
  - `make check-ih-t3`
  - `make check-ih-t4`
  - `make check-hi-t1`
  - `make check-hi-t2`
  - `make check-hi-t3`
  - `make check-hi-t4`
  - `make check-vga-t1`
  - `make check-vga-t2`
  - `make check-vga-t3`
  - `make check-vga-t4`
  - `make check-vga-t5`
  - `make check-vga-t6`
  - `make check-c-t1`

## High-level architecture

- The repo builds a BIOS boot chain with a strict raw artifact contract:
  - `src/bootloader/stage1/boot.asm` assembles to `build/boot.bin`, a 512-byte boot sector.
  - The bootloader loads `build/kernel.bin` from LBA 1 into `0x1000:0x0000`.
  - The kernel image starts with the `KRNL` signature and is linked at linear address `0x00010000` by `src/kernel/linker.ld`.
- The kernel is intentionally split into two layers:
  - `src/kernel/stage0/kernel.asm` owns real-mode startup, A20 enable/verify, GDT setup, the protected-mode jump, register/stack setup, ISR entry stubs, and the `debug_print_pm` shim used by C.
  - `src/kernel/stage1/*.c` owns the first protected-mode kernel body and higher-level runtime logic: `kmain.c` sequences bring-up, `vga.c` implements VGA text output, `idt.c` populates the IDT, and `interrupts.c` handles PIC/PIT setup plus interrupt and exception bookkeeping.
- `kmain()` is not the end of startup. It brings up VGA, emits the VGA-related markers used by tests, then calls `pm_main()` back in assembly so stage0 can install the IDT, enable interrupts, and drive the interrupt/exception test modes.
- The tests are QEMU-based shell scripts that inspect `build/*.log` debug-console output. CI runs `make check-c-toolchain` and then `make check-all`; on failure it uploads generated logs, binaries, and disk images from `build/`.

## Key conventions

- Keep implementations small and isolated by subsystem. The project is intentionally educational, and features are expected to stay simple enough to reason about in isolation and to test independently.
- Preserve debug marker strings unless the tests are being updated at the same time. The bootloader and kernel mirror status strings to QEMU debugcon port `0xE9`, and the test scripts grep for exact markers such as `KERNEL_OK`, `PM_OK`, `C_ENTRY_OK`, `IH_OK`, `HI_IRQ0_OK`, and `VGA_SCROLL_OK`.
- Keep the boot artifact contract stable when changing loading or layout code. The bootloader validates a fixed sector-count/start-LBA configuration, loads the kernel from floppy LBA 1, and rejects images that do not expose the expected `KRNL` header bytes.
- Test variants are produced by rebuilding the same kernel assembly with NASM defines, not by maintaining separate source files. Existing targets rely on flags such as `FORCE_A20_FAILURE`, `CODE_SEL`, `EXCEPTION_TEST`, `INTERRUPT_TEST_MODE`, and `HARDWARE_IRQ_TEST_MODE`.
- Kernel C code is freestanding 32-bit code compiled with `-m32 -ffreestanding -fno-pic -fno-pie -fno-stack-protector -Wall -Wextra -Iinclude`. Avoid libc assumptions and follow the existing pattern of small headers under `include/kernel/` with implementation-local integer typedefs in each C file.
- When changing bring-up behavior, check both the assembly/C handoff and the marker order. The current flow intentionally prints boot/protected-mode status from assembly first, then C emits VGA markers, then control returns to assembly for IDT and interrupt setup.
