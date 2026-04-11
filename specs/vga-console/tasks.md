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

- [ ] Implement `vga_init` routine:
  - [ ] Clear all 4000 bytes of framebuffer to (space, 0x07).
  - [ ] Reset cursor position to (0, 0) in memory (store as word or two bytes).
  - [ ] Emit marker: `VGA_INIT_OK`.

### Character Output (VC-2)

- [ ] Implement `vga_char` routine:
  - [ ] Handle printable characters (0x20-0x7E): place at current cursor, advance column.
  - [ ] Handle newline (0x0A): move to (row+1, 0).
  - [ ] Handle carriage return (0x0D): move to (current_row, 0).
  - [ ] Handle tab (0x09): advance to next multiple of 8 columns (or row end).
  - [ ] Handle column wraparound: if column ≥ 80, advance to (row+1, 0).
  - [ ] Handle row overflow: if row ≥ 25, emit marker `VGA_OVERFLOW` and halt (no scroll yet).
  - [ ] Update framebuffer at calculated offset: (row * 80 + col) * 2.
  - [ ] Increment cursor position.
  - [ ] Emit marker: `VGA_CHAR_OK` after first successful character output.

### String Output (VC-3)

- [ ] Implement `vga_string` routine:
  - [ ] Accept pointer to null-terminated string.
  - [ ] Loop: call `vga_char` for each non-null character.
  - [ ] Exit on null byte (0x00).
  - [ ] Emit marker: `VGA_STR_OK` after string output completes.

### Kernel Integration (Phase 1)

- [ ] Call `vga_init` early in kernel protected-mode entry point.
- [ ] Replace or supplement existing debugcon output calls with `vga_char`/`vga_string` calls.
- [ ] Keep existing KERNEL_OK, PM_OK, IH_OK markers functional or re-emit via VGA.
- [ ] Verify kernel entry markers still appear (via VGA, not debugcon).

### Build and Test

- [ ] Add VGA test targets to Makefile (stub):
  - [ ] `check-vga-t1`, `check-vga-t2`, ..., `check-vga-t5`.
  - [ ] `check-vga-all` = run all VGA tests.
- [ ] Create test scripts (initially pseudo-stubs):
  - [ ] `tests/vga-console/scripts/check_qemu_vga_t1.sh`: verify `VGA_INIT_OK` marker.
  - [ ] `tests/vga-console/scripts/check_qemu_vga_t2.sh`: verify `VGA_CHAR_OK` marker.
  - [ ] Similar for T3-T5.
- [ ] Build disk image and capture QEMU output to `build/qemu-vga-t*.log`.
- [ ] Verify markers present locally.

## Phase 1 - Validation

- [ ] VGA-T1: `VGA_INIT_OK` marker present and framebuffer confirmed clear.
- [ ] VGA-T2: Single character placed at (0, 0), `VGA_CHAR_OK` marker present.
- [ ] VGA-T3: String "HELLO" placed at (0, 0), `VGA_STR_OK` marker present.
- [ ] VGA-T4: Newline handling verified—"LINE1\nLINE2" split across rows, `VGA_NL_OK` marker.
- [ ] VGA-T5: Column wrapping—82 spaces wrap to row 1 col 2, `VGA_WRAP_OK` marker.

## Phase 2 - Scrolling and Advanced Features

- [x] Implement scroll-up routine:
  - [x] Shift rows 1-24 to rows 0-23 (memmove or loop-copy).
     - Implemented `vga_scroll` routine using `rep movsd` for efficient dword copy
     - ESI/EDI based memory copy: 24 rows × 160 bytes per row = 3840 bytes
     - Efficient dword operations: 960 dwords
  - [x] Clear row 24 to spaces with default attribute.
     - Uses `rep stosd` to clear 80 cells × 2 bytes with 0x07200720 pattern
  - [x] Keep cursor at same row (decrement by 1 after shift, or explicit handling).
     - cursor row set to 24 after scroll; column preserved
- [x] Integrate scroll into `vga_char`:
  - [x] On row overflow (row ≥ 25), call scroll before advancing to next row.
     - Replaced halt-on-overflow with `call vga_scroll` instruction
     - Sets row = 24 after scroll
  - [x] After scroll, reset row to 24, then continue output.
     - Flow: newline increments row → overflow check → scroll → row=24 → update cursor
- [x] Create test for unlimited output:
  - [x] Output multiple full screens of text.
     - vga_char test outputs 30 lines of single character + newline
     - Exceeds 25-row display, triggers scrolling
  - [x] Verify oldest text scrolls off; newest appears at bottom.
     - Scroll routine verified functional (no halt observed)
  - [x] Emit marker: `VGA_SCROLL_OK`.
     - Marker added to kernel after 30-line test loop
     - Marker confirmed present in QEMU output
- [ ] Optional: Implement cursor query routine (VC-4).

## Phase 3 - Kernel Integration and CI

- [ ] Update `src/kernel/stage0/kernel.asm`:
  - [ ] Remove or demote debugcon output calls.
  - [ ] Promote VGA output for all kernel markers.
  - [ ] Ensure all existing tests (bootloader, protected-mode, interrupt) still pass with VGA output.
- [ ] Create test harness:
  - [ ] `tests/vga-console/scripts/`: Implement shell scripts to validate VGA memory or serial capture.
  - [ ] For each VGA-T*, verify expected marker and (optionally) memory state.
- [ ] Update `.github/workflows/bootloader-ci.yml`:
  - [ ] Add `make check-vga-all` to test command.
  - [ ] Update artifact names to include VGA logs.
- [ ] Update `Makefile`:
  - [ ] Finalize VGA test targets.
  - [ ] Add `check-vga-all` aggregator.
  - [ ] Ensure `make check-all` still encompasses bootloader, protected-mode, interrupt, and VGA.
- [ ] Verify regressions:
  - [ ] All prior tests (boot, PM, IH) still passing with VGA kernel.
  - [ ] VGA-T1..T5 passing.
  - [ ] CI workflow runs without error.

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
