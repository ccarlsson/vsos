# Protected Mode Implementation Plan

## 1. Objective

Implement a minimal, deterministic, and testable transition from 16-bit real
mode to 32-bit protected mode for VSOS.

Success criteria:

- PM-FR-1..PM-FR-6 are implemented.
- PM-T1..PM-T4 are reproducible in local workflow.
- CI runs protected-mode tests through canonical commands.

## 2. Work Breakdown

### Phase 0 - Design Lock

Goal: Finalize transition constants and placement decisions before coding.

Tasks:

- Decide where transition code lives initially:
  - bootloader-side tail, or
  - kernel early stub.
- Define selector constants:
  - GDT code selector
  - GDT data selector
- Define 32-bit stack top address.
- Choose A20 strategy for v1:
  - fast A20 gate only, or
  - fast gate with fallback.
- Define protected-mode markers:
  - success: PM_OK
  - errors: P1, P2.

Deliverables:

- Finalized constants and transition location notes in spec and code comments.

Exit criteria:

- No unresolved placeholders for selectors/stack/A20 strategy.

### Phase 1 - Minimal Transition Path (PM-M1)

Goal: Reach 32-bit code path and emit success marker.

Tasks:

- Implement A20 enable + verification path (PM-FR-1).
- Implement minimal GDT and `lgdt` setup (PM-FR-2).
- Set `CR0.PE` and execute far jump to 32-bit code selector (PM-FR-3).
- Initialize `DS/ES/FS/GS/SS` and `ESP` in 32-bit entry (PM-FR-4).
- Emit `PM_OK` marker over debug port (PM-FR-5).

Deliverables:

- Working protected-mode transition code.
- Positive-path verification output.

Exit criteria:

- PM-T1 passes.

### Phase 2 - Failure Paths and Robustness (PM-M2)

Goal: Make protected-mode errors explicit and testable.

Tasks:

- Route A20 verification failure to `P1` and halt (PM-FR-6).
- Route GDT/selector setup failures (or forced invalid config variant) to `P2`
  and halt (PM-FR-6).
- Ensure all fatal paths end in `cli` + `hlt` loop.
- Ensure success marker does not appear in negative tests.

Deliverables:

- Distinct protected-mode failure markers and halt behavior.

Exit criteria:

- PM-T2 and PM-T3 pass.

### Phase 3 - Reproducibility and CI

Goal: Integrate protected-mode tests into existing deterministic workflow.

Tasks:

- Add protected-mode test scripts under canonical test layout.
- Add make targets:
  - check-pm-t1
  - check-pm-t2
  - check-pm-t3
  - check-pm-all
- Fold protected-mode checks into top-level suite when stable.
- Wire CI to run protected-mode checks.

Deliverables:

- Repeatable local + CI protected-mode validation flow.

Exit criteria:

- PM-T4 passes and CI includes protected-mode coverage.

## 3. Requirement Traceability

- PM-FR-1 -> A20 enable + verify and P1 path tasks.
- PM-FR-2 -> GDT definition and `lgdt` tasks.
- PM-FR-3 -> `CR0.PE` set and far jump tasks.
- PM-FR-4 -> 32-bit segment + stack initialization tasks.
- PM-FR-5 -> PM_OK marker emission tasks.
- PM-FR-6 -> P1/P2 failure markers and halt loop tasks.

## 4. Risks and Mitigations

Risk: A20 behavior differs across environments.
Mitigation: start with fast gate in QEMU; keep fallback strategy as explicit
option.

Risk: Hard-to-debug triple-fault during mode switch.
Mitigation: keep transition steps minimal and emit markers at each stage before
critical transition instructions.

Risk: Selector/GDT mistakes silently fail.
Mitigation: use fixed constants and dedicated forced-failure variants for tests.

Risk: Transition logic coupled too tightly with future paging/IDT work.
Mitigation: keep protected-mode spec isolated; add only minimum required state.

## 5. Definition of Done

- PM-FR-1..PM-FR-6 implemented.
- PM-T1..PM-T4 passing in local workflow.
- Protected-mode tests included in CI.
- Transition constants and contracts synchronized between spec and code.
