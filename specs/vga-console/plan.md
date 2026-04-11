# VGA Console Implementation Plan

## 1. Objective

Implement a minimal VGA text-mode console for kernel output, replacing debugcon dependency with real hardware support.

Success criteria:

- VGA console initialization (VC-1) implemented and verified.
- Character and string output (VC-2, VC-3) working reliably.
- VGA-T1 through VGA-T5 passing reproducibly locally and in CI.
- All kernel output (markers, diagnostics) transitionable from debugcon to VGA.

## 2. Work Breakdown

### Phase 0 - Specification and Constants Lock

Goal: Finalize memory layout, register usage, and calling conventions.

Tasks:

- Verify VGA framebuffer address (0xB8000) is accessible in protected mode kernel context.
- Verify cell format (2 bytes per character) matches VGA hardware expectations.
- Document register conventions for output routines (AL = char, AH = attr, or separate).
- Confirm test harness can capture VGA memory state from QEMU memory dump or serial relay.

Deliverables:

- Commented assembly constants matching spec section 5.
- Calling convention document (assembly function signatures).
- Test capture strategy defined.

Exit criteria:

- Implementation code can reference frozen constants without ambiguity.

### Phase 1 - Basic Output Routines

Goal: Implement core character/string output without scroll.

Tasks:

- Implement `vga_init`: clear framebuffer, reset cursor position.
- Implement `vga_char`: output one character, handle newline/CR/tab.
- Implement `vga_string`: output null-terminated string.
- Ensure cursor wrapping: advance row on column overflow.
- Add simple bounds check: halt on row overflow (no scroll yet).
- Emit success marker (`VGA_INIT_OK`, `VGA_CHAR_OK`, `VGA_STR_OK`, etc.) for test validation.
- Integrate into kernel entry point: call `vga_init` early, use for future kernel output.

Deliverables:

- Assembly routines in kernel source.
- Functional VGA framebuffer updates.
- Test markers in place.

Exit criteria:

- VGA-T1 through VGA-T5 pass locally.
- Markers captured in QEMU serial output or memory inspection.

### Phase 2 - Scrolling and Advanced Features

Goal: Handle screen overflow gracefully.

Tasks:

- Implement scroll-up on row overflow: shift rows 1-24 to rows 0-23, clear row 24.
- Verify cursor position reset on scroll.
- Test high-volume output without halt.

Deliverables:

- Scroll routine integrated into `vga_char`.

Exit criteria:

- Extended output sequences do not halt prematurely.
- Oldest output scrolls off top; newest appears at bottom.

### Phase 3 - Kernel Integration and CI

Goal: Make VGA console the primary kernel output mechanism.

Tasks:

- Replace debugcon markers with VGA output in kernel.asm.
- Update test scripts to validate VGA memory state (via QEMU gdb server or serial relay).
- Integrate `make check-vga-all` target into Makefile.
- Update CI workflow to run VGA test suite.

Deliverables:

- Kernel fully using VGA for output.
- Test harness for VGA validation.
- CI integration.

Exit criteria:

- All interrupt, protected-mode, and bootloader tests still passing with VGA output.
- VGA-specific tests (VGA-T1..T5) passing in CI.

## 3. Requirement Traceability

- **VC-1** (VGA init): Addressed in Phase 1, task "implement vga_init".
- **VC-2** (Char output): Addressed in Phase 1, task "implement vga_char".
- **VC-3** (String output): Addressed in Phase 1, task "implement vga_string".
- **VC-4** (Cursor query): Deferred to Phase 2 (optional).
- **VC-5** (Clear screen): Implemented as part of vga_init (Phase 1).

## 4. Test Coverage

| Test | Phase | Requirement | Success Condition |
|------|-------|-------------|-------------------|
| VGA-T1 | 1 | VC-1 | Framebuffer cleared, cursor at (0,0), marker emitted |
| VGA-T2 | 1 | VC-2 | Character placed, cursor advanced, marker emitted |
| VGA-T3 | 1 | VC-3 | String placed, cursor at end, marker emitted |
| VGA-T4 | 1 | VC-2 | Newline advances row, marker emitted |
| VGA-T5 | 1 | VC-2 | Cursor wraps at column 80, marker emitted |
| VGA-T6 | 2 | VC-2 | Tab and CR handled correctly |
| VGA-T7 | 2 | Scroll | Row 24 overflow triggers scroll-up, no halt |

## 5. Implementation Order

1. **Phase 0**: Lock constants and calling conventions in kernel.asm comments.
2. **Phase 1**: 
   - Write vga_init, vga_char, vga_string routines.
   - Add test markers to kernel startup.
   - Build disk image and validate VGA-T1..T5 locally.
3. **Phase 2**: Add scroll routine, extend vga_char, test with high-volume output.
4. **Phase 3**: Replace kernel debugcon output, update CI, achieve full integration.

## 6. Risk Mitigation

- **Memory access faults**: Test 0xB8000 accessibility early in Phase 1.
- **Cursor wraparound bugs**: Test VGA-T5 thoroughly; use QEMU memory breakpoints if needed.
- **Attribute handling**: Keep default 0x07 in Phase 1; color flexibility deferred.
