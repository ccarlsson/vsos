# VGA Console Testing Guide

## Overview

VGA console tests validate that text output to the VGA framebuffer (0xB8000) works correctly in protected mode.

All tests run via QEMU emulation and capture output markers via debugcon serial relay for validation.

## Test Philosophy

- **Isolation**: Each test focuses on a single responsibility (init, single char, string, newline, wrap).
- **Markers**: Each test emits a distinct marker (`VGA_*_OK`) that appears in QEMU serial output.
- **Simplicity**: Tests are self-contained; no external dependencies.
- **Reproducibility**: Same test produces same output every run in QEMU.

## Phase 1 Tests

### VGA-T1: Initialization

**Objective**: Verify VGA framebuffer is cleared and cursor reset on init.

**Test Flow**:
1. Bootloader loads kernel (standard path).
2. Kernel calls `vga_init` in protected mode.
3. Kernel emits marker `VGA_INIT_OK`.
4. Kernel halts.

**Expected Output**:
```
VSOS M1 DL=00
KERNEL_OK DL=00
PM_OK
VGA_INIT_OK
```

**Validation**:
- Serial output contains `VGA_INIT_OK` marker.
- (Optional) QEMU memory inspection: all 4000 bytes at 0xB8000 are (space=0x20, attr=0x07).
- Cursor position in memory is (0, 0).

**Command**: `make check-vga-t1`

---

### VGA-T2: Single Character Output

**Objective**: Verify a single character is placed at the cursor and cursor advances.

**Test Flow**:
1. Initialize VGA.
2. Call `vga_char` with 'A' (0x41).
3. Emit marker `VGA_CHAR_OK`.
4. Halt.

**Expected Output**:
```
VSOS M1 DL=00
KERNEL_OK DL=00
PM_OK
VGA_INIT_OK
VGA_CHAR_OK
```

**Validation**:
- Serial output contains `VGA_CHAR_OK`.
- (Optional) Memory: cell at offset 0 (row 0, col 0) contains 0x41 (ASCII 'A') and 0x07 (attribute).
- Cursor position is (0, 1).

**Command**: `make check-vga-t2`

---

### VGA-T3: String Output

**Objective**: Verify a null-terminated string is output correctly.

**Test Flow**:
1. Initialize VGA.
2. Call `vga_string` with pointer to "HELLO".
3. Emit marker `VGA_STR_OK`.
4. Halt.

**Expected Output**:
```
VSOS M1 DL=00
KERNEL_OK DL=00
PM_OK
VGA_INIT_OK
VGA_STR_OK
```

**Validation**:
- Serial output contains `VGA_STR_OK`.
- (Optional) Memory: cells 0-4 at row 0 contain 'H', 'E', 'L', 'L', 'O'.
- Cursor position is (0, 5).

**Command**: `make check-vga-t3`

---

### VGA-T4: Newline Handling

**Objective**: Verify newline character advances to next row and resets column to 0.

**Test Flow**:
1. Initialize VGA.
2. Call `vga_string` with "LINE1\nLINE2".
3. Emit marker `VGA_NL_OK`.
4. Halt.

**Expected Output**:
```
VSOS M1 DL=00
KERNEL_OK DL=00
PM_OK
VGA_INIT_OK
VGA_NL_OK
```

**Validation**:
- Serial output contains `VGA_NL_OK`.
- (Optional) Memory:
  - Row 0: "LINE1" at columns 0-4.
  - Row 1: "LINE2" at columns 0-4.
  - Cursor position is (1, 5).

**Command**: `make check-vga-t4`

---

### VGA-T5: Column Wrapping

**Objective**: Verify cursor wraps to next row when column exceeds 79.

**Test Flow**:
1. Initialize VGA.
2. Output 82 spaces (80 on row 0, wrap to row 1).
3. Emit marker `VGA_WRAP_OK`.
4. Halt.

**Expected Output**:
```
VSOS M1 DL=00
KERNEL_OK DL=00
PM_OK
VGA_INIT_OK
VGA_WRAP_OK
```

**Validation**:
- Serial output contains `VGA_WRAP_OK`.
- (Optional) Memory:
  - Row 0: 80 spaces (columns 0-79).
  - Row 1: 2 spaces (columns 0-1).
  - Cursor position is (1, 2).

**Command**: `make check-vga-t5`

---

## Phase 2 Tests (Scrolling)

### VGA-T6: Tab Handling (Optional)

**Objective**: Verify tab character advances to next 8-column boundary.

**Test Flow**:
1. Initialize VGA.
2. Output "A\tB" (A, tab, B).
3. Emit marker `VGA_TAB_OK`.

**Expected Behavior**:
- 'A' at column 0.
- 'B' at column 8 (next multiple of 8).

---

### VGA-T7: High-Volume Output (Scrolling)

**Objective**: Verify screen scrolls when row 24 is exceeded.

**Test Flow**:
1. Initialize VGA.
2. Output multiple full lines (30+ lines of text).
3. Emit marker `VGA_SCROLL_OK`.

**Expected Behavior**:
- Initial lines scroll off the top (not visible in final state).
- Final lines occupy rows 0-24.
- Cursor at appropriate position.
- No halt on overflow.

---

## Running Tests Locally

### All VGA Tests

```bash
make check-vga-all
```

This will run VGA-T1 through VGA-T5 in sequence and report pass/fail for each.

### Individual Test

```bash
make check-vga-t1
make check-vga-t2
# ... etc
```

### With Custom QEMU Timeout

```bash
QEMU_TIMEOUT_SECONDS=5 make check-vga-all
```

### Debug: Inspect QEMU Output

Each test captures serial output to a debug log:

```bash
cat build/qemu-vga-t1-debug.log   # Raw QEMU output for VGA-T1
cat build/qemu-vga-t2-debug.log   # Raw QEMU output for VGA-T2
# ... etc
```

To see all log files:

```bash
ls -la build/qemu-vga-*.log
```

---

## Running Tests in CI

GitHub Actions workflow automatically runs `make check-vga-all` on every push and pull request.

If a test fails:
1. Workflow uploads debug logs as artifacts.
2. Download artifacts to inspect failure details.
3. Reproduce locally with `QEMU_TIMEOUT_SECONDS=5 make check-vga-all`.

---

## Test Artifacts

Tests generate the following artifacts in `build/`:

| Artifact | Purpose |
|----------|---------|
| `disk-vga-t*.img` | Bootable disk image for test T* |
| `qemu-vga-t*-debug.log` | Raw QEMU serial output (debugcon) |
| `kernel.vga.*.bin` | Kernel binary for test T* (if variant) |

---

## Expected Markers

Each test emits a specific marker. The test harness (shell script) greps for this marker to determine pass/fail.

| Test | Marker | Meaning |
|------|--------|---------|
| VGA-T1 | `VGA_INIT_OK` | Framebuffer initialized |
| VGA-T2 | `VGA_CHAR_OK` | Single character output works |
| VGA-T3 | `VGA_STR_OK` | String output works |
| VGA-T4 | `VGA_NL_OK` | Newline handling works |
| VGA-T5 | `VGA_WRAP_OK` | Column wrapping works |

If a marker is missing from the output, the test **fails**.

---

## Debugging VGA Issues

### Marker Missing

**Problem**: Test log contains `VSOS M1`, `KERNEL_OK`, `PM_OK`, but not `VGA_INIT_OK`.

**Cause**: VGA routines not called or marker not emitted.

**Debug Steps**:
1. Verify `vga_init` is called in kernel protected-mode entry.
2. Verify marker string is present in kernel source.
3. Check kernel compiles without error: `nasm -f bin -o build/kernel.bin src/kernel/stage0/kernel.asm`.
4. Emit to debugcon immediately: `mov al, '!'; out 0xe9, al` to verify debugcon is working.

### Character Not Placed at Expected Location

**Problem**: Test passes (marker present) but memory inspection shows wrong character or position.

**Debug Steps**:
1. Add debug markers at each step: before framebuffer write, after cursor update.
2. Verify cursor position calculation: `offset = (row * 80 + col) * 2`.
3. Verify framebuffer base address is correct: `0xB8000` in protected mode linear space.
4. Use QEMU memory dump: `(qemu) x /80 0xb8000` to inspect first row of framebuffer.

### Wraparound Fails (Cursor Doesn't Advance to Row 1)

**Problem**: 80 characters output, but cursor stays on row 0.

**Debug Steps**:
1. Verify column ≥ 80 check: `if (column >= 80) { row++; column = 0; }`.
2. Check row increment happens before next character placement.
3. Test with explicit position: output char, inspect memory, verify cursor incremented.

---

## Notes

- Tests use direct VGA framebuffer access (0xB8000 linear address).
- No BIOS calls or CRTC hardware control in Phase 1.
- All output relies on software cursor tracking.
- Markers may be captured via debugcon (port 0xE9) or via kernel source inspection.
