# VGA Console Specification

## 1. Purpose

This module specifies how VSOS provides text output to the VGA display in protected mode.

It is designed for teaching and simplicity:

- Keep output logic minimal and readable.
- Use direct memory writes to VGA framebuffer (no BIOS).
- Make output testable via QEMU's serial capture.
- Support basic debugging and kernel messages.

## 2. Context

The kernel currently uses QEMU debugcon (port 0xE9) for diagnostic output. This spec defines 
a minimal replacement using actual VGA hardware, suitable for real machines and standard emulation.

The VGA console will be initialized early in kernel protected mode, before any user-facing output.

## 3. Scope

In scope:

- VGA text mode 80x25 (standard VGA setup inherited from bootloader)
- Direct memory writes to VGA framebuffer at linear address 0xB8000
- Character output with color support (foreground/background)
- Cursor position tracking and line wrapping
- Newline and carriage-return handling
- String output routine for kernel messages

Out of scope (this version):

- Cursor hardware control (CRTC registers)
- Scrolling (will need explicit implementation in Phase 2)
- Special key handling or input
- Alternative color modes or palettes
- Protected mode paging assumptions (assumes flat 32-bit linear addressing at 0xB8000)

## 4. Constraints (from VSOS context)

- Architecture: x86 protected mode
- Languages/tooling: Assembly + C, NASM
- Runtime: QEMU (with serial capture for test validation)
- Linear address space: flat 32-bit model with kernel at 0x10000
- Font: 8x8 VGA ROM font (hardware-provided, no explicit font data)

## 5. Fixed Constants

### VGA Framebuffer

- Base address: `0xB8000` (linear, protected mode)
- Mode: 80 columns × 25 rows
- Cell size: 2 bytes per character (char + attribute)
- Total size: 80 × 25 × 2 = 4000 bytes

### Cell Format (word at offset)

```
Byte 0: ASCII character code
Byte 1: Attribute byte
  Bits 7-4: Background color (IRGB)
  Bits 3-0: Foreground color (IRGB)
```

### Standard Color Values

```
0 = Black
1 = Blue
2 = Green
3 = Cyan
4 = Red
5 = Magenta
6 = Brown
7 = Light Gray
8 = Dark Gray
9 = Light Blue
A = Light Green
B = Light Cyan
C = Light Red
D = Light Magenta
E = Yellow
F = White
```

### Cursor State

- Current column (0-79)
- Current row (0-24)
- Attribute byte for text output (default: 0x07 = white on black)

## 6. Responsibilities

### VGA Console Module

**VC-1**: Initialize VGA state on protected mode entry.
- Clear framebuffer to spaces with default attribute (0x07).
- Reset cursor position to (0, 0).
- Mark VGA subsystem as ready.

**VC-2**: Character output routine.
- Accept ASCII character code and current attribute.
- Handle special characters:
  - Newline (0x0A): advance to next line at column 0.
  - Carriage return (0x0D): move cursor to column 0.
  - Tab (0x09): advance to next multiple of 8 columns (or EOL).
  - Other printable (0x20-0x7E): place at current cursor, advance column.
  - Non-printable: emit as-is or substitute (spec allows either).
- Wrap: if column ≥ 80, advance to next line column 0.
- Wrap: if row ≥ 25, halt with marker (Phase 1: no scrolling).

**VC-3**: String output routine.
- Accept pointer to null-terminated ASCII string.
- Call character output for each character.
- Return when null byte encountered.

**VC-4**: Cursor position query.
- Return current (row, column) position.
- Used by kernel for formatting and diagnostics.

**VC-5**: Clear screen routine (optional Phase 1).
- Fill entire framebuffer with space + default attribute.
- Reset cursor to (0, 0).

## 7. Call Contract

### Character Output

```
Input:
  AL = ASCII character code
  AH or context = attribute byte (or use global default)
  
Output:
  Cursor advanced as per VC-2 rules
  Framebuffer updated
  
Side effects:
  Changes cursor position
  Modifies framebuffer cells
```

### String Output

```
Input:
  ESI or absolute address = pointer to null-terminated string
  
Output:
  String copied to framebuffer starting at current cursor
  Cursor advanced to end of string
  
Side effects:
  Multiple framebuffer updates
  Cursor advanced past string output
```

## 8. Test Criteria

### VGA-T1: Initialization

- Call VC-1 init routine.
- Verify entire framebuffer is spaces with attribute 0x07.
- Verify cursor is at (0, 0).
- Emit marker: `VGA_INIT_OK`.

### VGA-T2: Single Character

- Initialize VGA.
- Output character 'A' (0x41) at cursor.
- Verify cell at (0, 0) contains 'A' with default attribute.
- Verify cursor advanced to (0, 1).
- Emit marker: `VGA_CHAR_OK`.

### VGA-T3: String Output

- Initialize VGA.
- Output string `"HELLO"`.
- Verify cells (0, 0)–(0, 4) contain 'H', 'E', 'L', 'L', 'O'.
- Verify cursor is at (0, 5).
- Emit marker: `VGA_STR_OK`.

### VGA-T4: Newline Handling

- Initialize VGA.
- Output `"LINE1\nLINE2"`.
- Verify row 0 contains `"LINE1"` at columns 0–4.
- Verify row 1 contains `"LINE2"` at columns 0–4.
- Verify cursor is at (1, 5).
- Emit marker: `VGA_NL_OK`.

### VGA-T5: Column Wrapping

- Initialize VGA.
- Output 82 spaces (wraps at 80).
- Verify cursor is at (1, 2) (wrapped to row 1, col 2).
- Emit marker: `VGA_WRAP_OK`.

### VGA-T6: Edge Cases (Phase 1, optional)

- Verify tab behavior: advance to next 8-column boundary.
- Verify carriage return: move to column 0 without advancing row.

## 9. Integration Points

### With Protected Mode Kernel

- VGA init called early after PM entry (before interrupts or memory management).
- Character/string routines callable from C (via assembly wrappers) or pure assembly.
- Does not depend on interrupts, timers, or other subsystems.
- Uses only protected mode memory addressing at 0xB8000.

### With Bootloader/Kernel Handoff

- No handoff requirements.
- Bootloader leaves VGA hardware in standard text mode (inherited state).
- Kernel re-initializes VGA framebuffer unconditionally.

### With Exception/Interrupt Handling

- VGA output can be called from exception handlers (e.g., to print error messages).
- No mutual exclusion required in Phase 1 (no multitasking).

## 10. Notes

- This spec does NOT include scrolling. Once row 24 is full and a newline is issued, 
  the kernel halts and emits a marker. Scrolling can be added in Phase 2.
- Color attributes are fixed to 0x07 (white on black) in Phase 1.
- Cursor hardware control (via CRTC registers) is deferred; cursor position is 
  tracked in software.
