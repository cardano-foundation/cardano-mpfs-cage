# Tasks: Mixed Update/Reject in Modify Redeemer

**Input**: Design documents from `/specs/001-mixed-modify-reject/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

## Phase 1: Foundational (Type Changes)

**Purpose**: Introduce `RequestAction` and update `UpdateRedeemer` — all other tasks depend on this.

- [ ] T001 [US1] Add `RequestAction` type (`Update ![ProofStep]` | `Rejected`) with Haddock in `lib/Cardano/MPFS/Cage/Types.hs`
- [ ] T002 [US1] Add `ToData`/`FromData`/`UnsafeFromData` instances for `RequestAction` in `lib/Cardano/MPFS/Cage/Types.hs`
- [ ] T003 [US1] Update `Modify` constructor from `![[ProofStep]]` to `![RequestAction]` in `lib/Cardano/MPFS/Cage/Types.hs`
- [ ] T004 [US2] Remove `Reject` constructor from `UpdateRedeemer` in `lib/Cardano/MPFS/Cage/Types.hs`
- [ ] T005 [US2] Update `ToData`/`FromData`/`UnsafeFromData` instances for `UpdateRedeemer` (drop Constr 4 cases, update Constr 2 to use `RequestAction`) in `lib/Cardano/MPFS/Cage/Types.hs`
- [ ] T006 [US1] Export `RequestAction (..)` from module header in `lib/Cardano/MPFS/Cage/Types.hs`

**Checkpoint**: Library compiles with `just build`

---

## Phase 2: Tests and Generators

**Purpose**: Update QuickCheck generators and roundtrip properties.

- [ ] T007 [US1] Add `genRequestAction` generator (produces both `Update` and `Rejected`) in `test/Cardano/MPFS/Cage/TypesSpec.hs`
- [ ] T008 [US1] Add `RequestAction` roundtrip property test in `test/Cardano/MPFS/Cage/TypesSpec.hs`
- [ ] T009 [US1] Update `genUpdateRedeemer` to use `genRequestAction` for `Modify` in `test/Cardano/MPFS/Cage/TypesSpec.hs`
- [ ] T010 [US2] Remove `Reject` case from `genUpdateRedeemer` in `test/Cardano/MPFS/Cage/TypesSpec.hs`
- [ ] T011 [US2] Add negative test: `Constr 4 []` decodes to `Nothing` in `test/Cardano/MPFS/Cage/TypesSpec.hs`

**Checkpoint**: `just unit` passes

---

## Phase 3: Test Vectors

**Purpose**: Update test vector generator with mixed Modify examples.

- [ ] T012 [US2] Remove Reject test vector from `app/test-vectors/Main.hs`
- [ ] T013 [US1] Add mixed Modify test vector (both `Update` and `Rejected` entries) in `app/test-vectors/Main.hs`
- [ ] T014 [US1] Update any existing Modify vectors to use `RequestAction` encoding in `app/test-vectors/Main.hs`

**Checkpoint**: `just vectors` generates valid JSON

---

## Phase 4: Lean Specification

**Purpose**: Update formal spec to match new types.

- [ ] T015 [P] [US3] Add `RequestAction` inductive to `lean/MpfsCage/Spec.lean`
- [ ] T016 [US3] Remove `Reject` from `SpendRedeemer` inductive in `lean/MpfsCage/Spec.lean`
- [ ] T017 [US3] Update `Modify` to carry `List RequestAction` in `lean/MpfsCage/Spec.lean`
- [ ] T018 [US3] Merge `ValidReject` logic into `Modify` branch of `validSpend` in `lean/MpfsCage/Spec.lean`
- [ ] T019 [US3] Update `datumRedeemerCompat` to remove `Reject` case in `lean/MpfsCage/Spec.lean`
- [ ] T020 [US3] Update `phase2_reject_exclusive` theorem if affected in `lean/MpfsCage/Spec.lean`

**Checkpoint**: `lake build` succeeds

---

## Phase 5: Polish

- [ ] T021 Run `just ci` to verify full pipeline
- [ ] T022 Update `.cabal` version if needed in `cardano-mpfs-cage.cabal`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** (types): No dependencies — start here
- **Phase 2** (tests): Depends on Phase 1
- **Phase 3** (vectors): Depends on Phase 1
- **Phase 4** (Lean): Independent of Phases 2-3, only needs Phase 1 design decisions
- **Phase 5** (polish): Depends on all previous phases

### Parallel Opportunities

- Phases 2, 3, 4 can run in parallel after Phase 1 completes
- Within Phase 4, T015 can run in parallel with other Lean tasks

---

## Implementation Strategy

### Vertical Commits

One commit per logical unit (per workflow rules):
1. `RequestAction` type + instances + export
2. `UpdateRedeemer` changes (remove Reject, update Modify)
3. Test generators and properties
4. Test vectors
5. Lean spec

---

## Notes

- All tasks touch existing files — no new files created
- Constructor indices: `RequestAction::Update` = Constr 0, `RequestAction::Rejected` = Constr 1
- `UpdateRedeemer::Modify` stays at Constr 2, `Retract` stays at Constr 3
