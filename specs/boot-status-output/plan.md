# Boot Status Output Implementation Plan

## 1. Objective

Add clear, human-readable boot progress messages to VSOS across the bootloader,
transition, and early kernel stages while preserving all current debug-marker
based validation.

Success criteria:

- Boot flow shows meaningful status text on screen.
- Existing automated tests remain green.
- Message order matches the real boot path.

## 2. Work Breakdown

### Phase 0 - Design Lock

Goal: finalize message style, message locations, and compatibility rules.

Tasks:

- Decide which stages must be shown on screen.
- Define concise message text for each stage.
- Lock compatibility rule: debug-port markers remain unchanged.

Locked Phase 0 decisions:

- Visible stages:
	- bootloader start
	- kernel loading
	- kernel handoff
	- protected-mode entry
	- VGA ready
	- early init complete
- Final message text:
	- `Boot: start`
	- `Boot: loading kernel`
	- `Boot: entering kernel`
	- `Kernel: protected mode`
	- `Kernel: VGA ready`
	- `Kernel: init complete`
- Compatibility rule: existing debug-port markers remain unchanged and continue
	to be emitted alongside any user-visible text.

Exit criteria:

- No ambiguity about where messages should appear.

Status: Complete.

### Phase 1 - Bootloader Messages

Goal: make early boot activity visible in real mode.

Tasks:

- Add readable bootloader startup text.
- Add readable kernel-loading / handoff text.
- Keep existing debug mirror behavior intact.

Exit criteria:

- Bootloader stage messages are visible and ordered.

### Phase 2 - Early Kernel Messages

Goal: continue user-visible boot status after handoff.

Tasks:

- Show protected-mode / kernel entry message.
- Show VGA console initialization progress.
- Replace current test-like visible output with clearer status text where needed.

Exit criteria:

- User can follow the boot path on screen into early kernel bring-up.

### Phase 3 - Validation and Regression

Goal: prove visibility improvements did not break the test harness.

Tasks:

- Validate visible message sequence in QEMU.
- Run current automated suites.
- Update docs to reflect final visible stages.

Exit criteria:

- Human-visible output and automated markers coexist cleanly.

## 3. Requirement Traceability

- BSO-FR-1 -> bootloader message tasks.
- BSO-FR-2 -> protected-mode/kernel entry message tasks.
- BSO-FR-3 -> VGA output tasks.
- BSO-FR-4 -> ordered message sequencing tasks.
- BSO-FR-5 -> regression validation tasks.
- BSO-FR-6 -> failure output review tasks.

## 4. Risks and Mitigations

Risk: user-visible text changes may accidentally break log-based tests.
Mitigation: keep debug-port markers unchanged and separate from human messages.

Risk: too much visible text may make boot output noisy.
Mitigation: keep messages short and stage-oriented.

Risk: mixed BIOS/VGA paths may feel inconsistent.
Mitigation: document the transition clearly and keep wording aligned.

## 5. Definition of Done

- BSO-FR-1..BSO-FR-6 implemented.
- BSO-T1..BSO-T4 validated.
- Existing check targets continue to pass.
