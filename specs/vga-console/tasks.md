# VGA Console Task List

This checklist translates `spec.md` and `plan.md` into implementation-ready work.

## Phase 0 - Specification and Constants Lock

- [x] Verify 0xB8000 accessibility in protected mode context.
  - Implemented `verify_vga_accessible` routine in kernel.asm
  - Writes test pattern (space + 0x07 attr) to first VGA cell
  - Reads back and verifies write succeeded
  - Emits `VGA_OK` marker on success
  - QEMU test confirmed: output shows "VSOS M1 DL=80 KERNEL_OK DL=80 PM_OK VGA_OK IH_OK"
- [x] Document cell format: 2 bytes (char + attr) per position.
  - Constant: VGA_CELL_SIZE = 2
  - Comment in spec: char at byte 0, attribute at byte 1
- [x] Define register conventions:
  - [x] Character output: AL = ASCII, (AH or global default) = attribute.
  - [x] String output: ESI or explicit address = string pointer.
  - Added detailed comments in kernel.asm explaining each routine's inputs/outputs
- [x] Add constants to kernel.asm source comments:
  - [x] VGA_FRAMEBUFFER = 0xB8000
  - [x] VGA_COLS = 80
  - [x] VGA_ROWS = 25
  - [x] VGA_CELL_SIZE = 2
  - [x] VGA_DEFAULT_ATTR = 0x07
  - [x] VGA_FRAMEBUFFER_SIZE = 4000 (80*25*2)
- [x] Confirm test capture strategy (QEMU serial relay or memory inspection).
  - Test strategy: Emit VGA_OK marker via debugcon (port 0xE9)
  - Capture via QEMU `-debugcon file:` option
  - Grep for marker in output log to validate accessibility

## Phase 1 - Basic Output Routines

### Initialization (VC-1)

- [x] Implement `vga_init` routine:
  - [x] Clear all 4000 bytes of framebuffer to (space, 0x07).
  - [x] Reset cursor position to (0, 0) in memory (store as word or two bytes).
  - [x] Emit marker: `VGA_INIT_OK`.

### Character Output (VC-2)

- [x] Implement `vga_char` routine:
  - [x] Handle printable characters (0x20-0x7E): place at current cursor, advance column.
  - [x] Handle newline (0x0A): move to (row+1, 0).
  - [x] Handle carriage return (0x0D): move to (current_row, 0).
  - [x] Handle tab (0x09): advance to next multiple of 8 columns (or row end).
  - [x] Handle column wraparound: if column ≥ 80, advance to (row+1, 0).
  - [x] Handle row overflow: if row ≥ 25, scroll and continue output.
  - [x] Update framebuffer at calculated offset: `(row * 80 + col) * 2`.
  - [x] Increment cursor position.
  - [x] Emit marker: `VGA_CHAR_OK` after first successful character output.

### String Output (VC-3)

- [x] Implement `vga_string` routine:
  - [x] Accept pointer to null-terminated string.
  - [x] Loop: call `vga_char` for each non-null character.
  - [x] Exit on null byte (0x00).
  - [x] Emit marker: `VGA_STR_OK` after string output completes.

### Kernel Integration (Phase 1)

- [x] Call `vga_init` early in kernel protected-mode entry point.
- [x] Replace or supplement existing debugcon output calls with `vga_char`/`vga_string` calls.
- [x] Keep existing KERNEL_OK, PM_OK, IH_OK markers functional or re-emit via VGA.
- [x] Verify kernel entry markers still appear.

### Build and Test

- [x] Add VGA test targets to Makefile.
  - [x] `check-vga-t1`, `check-vga-t2`, ..., `check-vga-t6`.
  - [x] `check-vga-all` = run all VGA tests.
- [x] Create VGA test scripts:
  - [x] `tests/vga-console/scripts/check_qemu_vga_t1.sh`: verify `VGA_INIT_OK` marker.
  - [x] `tests/vga-console/scripts/check_qemu_vga_t2.sh`: verify `VGA_CHAR_OK` marker.
  - [x] `tests/vga-console/scripts/check_qemu_vga_t3.sh`: verify `VGA_STR_OK` marker.
  - [x] `tests/vga-console/scripts/check_qemu_vga_t4.sh`: verify `VGA_NL_OK` marker.
  - [x] `tests/vga-console/scripts/check_qemu_vga_t5.sh`: verify `VGA_WRAP_OK` marker.
  - [x] `tests/vga-console/scripts/check_qemu_vga_t6.sh`: verify `VGA_SCROLL_OK` marker.
- [x] Build disk image and capture QEMU output to `build/qemu-vga-t*.log`.
- [x] Verify markers present locally.

## Phase 1 - Validation

- [x] VGA-T1: `VGA_INIT_OK` marker present and framebuffer confirmed clear.
- [x] VGA-T2: Single character placed at (0, 0), `VGA_CHAR_OK` marker present.
- [x] VGA-T3: String "HELLO" placed at (0, 0), `VGA_STR_OK` marker present.
- [x] VGA-T4: Newline handling verified, `VGA_NL_OK` marker.
- [x] VGA-T5: Column wrapping verified, `VGA_WRAP_OK` marker.

## Phase 2 - Scrolling and Advanced Features

- [x] Implement scroll-up routine:
  - [x] Shift rows 1-24 to rows 0-23 (memmove or loop-copy).
  - [x] Clear row 24 to spaces with default attribute.
  - [x] Keep cursor at same row (decrement by 1 after shift, or explicit handling).
- [x] Integrate scroll into `vga_char`:
  - [x] On row overflow (row ≥ 25), call scroll before advancing to next row.
  - [x] After scroll, reset row to 24, then continue output.
- [x] Create test for unlimited output:
  - [x] Output multiple full screens of text.
  - [x] Verify oldest text scrolls off; newest appears at bottom.
  - [x] Emit marker: `VGA_SCROLL_OK`.
- [ ] Optional: Implement cursor query routine (VC-4).

## Phase 3 - Kernel Integration and CI

- [x] Update `src/kernel/stage0/kernel.asm`:
  - [x] Demote direct debugcon callsites through a shared marker helper.
  - [x] Mirror protected-mode and interrupt markers to VGA when initialized.
  - [x] Keep existing test markers functional through debugcon.
- [x] Create test harness:
  - [x] `tests/vga-console/scripts/`: Implemented scripts for VGA-T1..VGA-T6.
  - [x] For each VGA-T*, verify expected marker via QEMU debug log capture.
- [x] Update `.github/workflows/bootloader-ci.yml`:
  - [x] CI suite runs through `make check-all` (includes VGA aggregation).
  - [x] Artifact names updated to include VGA logs.
- [x] Update `Makefile`:
  - [x] Finalized VGA test targets.
  - [x] Added `check-vga-all` aggregator.
  - [x] Ensured `make check-all` includes bootloader, protected-mode, interrupt, and VGA.
- [x] Verify regressions:
  - [x] All prior tests (boot, PM, IH) still passing with VGA kernel.
  - [x] VGA-T1..T6 passing.
  - [x] CI workflow configuration updated and ready.

## Requirement Traceability

- [x] VC-1 (Init) → Phase 1: `vga_init` routine + VGA-T1.
- [x] VC-2 (Char) → Phase 1: `vga_char` routine + VGA-T2, T4, T5; Phase 2: scroll integration.
- [x] VC-3 (String) → Phase 1: `vga_string` routine + VGA-T3.
- [ ] VC-4 (Cursor query) → Phase 2 (optional).
- [x] VC-5 (Clear) → Phase 1: part of `vga_init`.

## Notes

- Keep routines small and readable; this is educational code.
- Use direct memory writes (mov instructions) for framebuffer updates; no BIOS calls.
- Test markers are critical for validation; include them liberally.
- Decouple VGA output from existing debugcon—both can coexist in Phase 1 for safety.
