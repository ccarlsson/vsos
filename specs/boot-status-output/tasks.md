# Boot Status Output Task List

This checklist translates `spec.md` into implementation-ready work.

## Phase 0 - Design Lock

- [ ] Decide visible stages for bootloader, transition, and kernel bring-up.
- [ ] Define final short message text for each visible stage.
- [ ] Lock compatibility rule for existing debug markers.

## Phase 1 - Bootloader Messages

- [ ] Add readable bootloader startup message.
- [ ] Add readable kernel-loading progress/handoff message.
- [ ] Keep BIOS teletype path simple and deterministic.
- [ ] Verify existing debug-port mirror behavior remains intact.

## Phase 2 - Early Kernel Messages

- [ ] Add protected-mode / kernel entry message visible to the user.
- [ ] Add readable VGA-init / early-kernel progress text.
- [ ] Replace current non-user-facing visible test output where appropriate.
- [ ] Keep debug markers unchanged for automation.

## Phase 3 - Validation and Regression

- [ ] Validate visible message order in QEMU.
- [ ] Run existing automated suites.
- [ ] Update docs if visible stage text changes from initial draft.

## Requirement Traceability Checklist

- [ ] BSO-FR-1 satisfied.
- [ ] BSO-FR-2 satisfied.
- [ ] BSO-FR-3 satisfied.
- [ ] BSO-FR-4 satisfied.
- [ ] BSO-FR-5 satisfied.
- [ ] BSO-FR-6 satisfied.

## Done Criteria

- [ ] Human-readable boot messages visible from bootloader through early kernel.
- [ ] Existing automated tests still pass.
- [ ] Visible output remains short, clear, and deterministic.
