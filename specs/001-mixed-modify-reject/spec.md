# Feature Specification: Mixed Update/Reject in Modify Redeemer

**Feature Branch**: `001-mixed-modify-reject`
**Created**: 2026-04-13
**Status**: Draft
**Input**: User description: "Support mixed update/reject in Modify redeemer"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Oracle processes mixed batch (Priority: P1)

The oracle operator submits a single transaction that processes multiple pending requests against the same cage token. Some requests are fulfilled (proofs provided) and others are rejected (expired or invalid). Currently this requires two separate transactions — one Modify and one Reject. With this change, a single Modify transaction handles both via a new `RequestAction` type that distinguishes update from rejection at the type level.

**Why this priority**: This is the core value proposition — reducing transaction count and enabling atomic mixed batches.

**Independent Test**: Construct a Modify redeemer with a mix of `Update [steps]` and `Rejected` actions, encode to PlutusData, decode back, and confirm the roundtrip preserves the structure.

**Acceptance Scenarios**:

1. **Given** a Modify redeemer with actions `[Update [step1, step2], Rejected, Update [step3]]`, **When** encoded to PlutusData and decoded back, **Then** the result equals the original — two updates and one rejection.
2. **Given** a Modify redeemer where all actions are `Rejected`, **When** encoded, **Then** it produces a valid PlutusData (Constr 2 with a list of Constr 1 entries).

---

### User Story 2 - Reject constructor removed (Priority: P1)

The separate `Reject` constructor (Constr 4) is removed from `UpdateRedeemer`. Any code that previously used `Reject` must use `Modify [Rejected, ...]` instead. Test vectors for Reject are replaced with mixed Modify vectors.

**Why this priority**: This is a breaking change that simplifies the on-chain interface. The Aiken validator must match.

**Independent Test**: Verify that the Haskell type no longer has a Reject constructor, that FromData rejects Constr 4 payloads, and that test vectors reflect the new encoding.

**Acceptance Scenarios**:

1. **Given** the updated `UpdateRedeemer` type, **When** a PlutusData `Constr 4 []` is decoded, **Then** `fromBuiltinData` returns `Nothing`.
2. **Given** the updated test vector generator, **When** vectors are generated, **Then** no vector uses the old Reject encoding, and at least one uses mixed `RequestAction` entries.

---

### User Story 3 - Lean specification updated (Priority: P2)

The Lean 4 formal spec is updated to reflect the new `RequestAction` inductive type. The `SpendRedeemer` drops `Reject`. The `ValidReject` structure is folded into `ValidModify` with per-action semantics based on the `RequestAction` variant.

**Why this priority**: Formal properties must stay in sync with the on-chain encoding, but this is a documentation/verification change, not a runtime change.

**Independent Test**: `lake build` compiles with no errors.

**Acceptance Scenarios**:

1. **Given** the updated Lean spec, **When** `lake build` runs, **Then** it completes with no errors.
2. **Given** the updated `validSpend` definition, **When** the redeemer is `Modify actions` and some actions are `Rejected`, **Then** the specification requires rejection semantics for those entries and proof semantics for `Update` entries.

### Edge Cases

- What happens when the action list in Modify is completely empty? `Modify []` — valid encoding, semantics defined by the validator.
- What happens with a single rejected request? `Modify [Rejected]` — one request, rejected via type-safe constructor.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `RequestAction` sum type MUST be introduced with constructors `Update ![ProofStep]` (Constr 0) and `Rejected` (Constr 1).
- **FR-002**: The `Modify` constructor MUST carry `![RequestAction]` instead of `![[ProofStep]]`.
- **FR-003**: The `Modify` constructor MUST retain its encoding as Constr 2.
- **FR-004**: The `Reject` constructor (Constr 4) MUST be removed from `UpdateRedeemer`.
- **FR-005**: `ToData`/`FromData`/`UnsafeFromData` instances MUST be implemented for `RequestAction`.
- **FR-006**: `ToData`/`FromData`/`UnsafeFromData` instances for `UpdateRedeemer` MUST be updated to use `RequestAction`.
- **FR-007**: `fromBuiltinData` MUST return `Nothing` for `Constr 4 []` (old Reject encoding).
- **FR-008**: QuickCheck generators MUST produce mixed action lists (some `Update`, some `Rejected`).
- **FR-009**: Test vectors MUST include at least one mixed Modify vector with both `Update` and `Rejected` entries.
- **FR-010**: The Lean `SpendRedeemer` inductive MUST drop the `Reject` variant.
- **FR-011**: A Lean `RequestAction` inductive MUST be added with `Update` and `Rejected` variants.
- **FR-012**: The Lean `validSpend` function MUST handle `Rejected` actions as rejection within the `Modify` branch.

### Key Entities

- **RequestAction**: Per-request action — `Update [ProofStep]` (Constr 0) or `Rejected` (Constr 1). New type.
- **UpdateRedeemer**: Spending redeemer — `End | Contribute | Modify | Retract` (4 constructors, down from 5). Modified.
- **ProofStep**: Individual step in a Merkle proof (Branch, Fork, Leaf) — unchanged.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All existing roundtrip property tests pass with the updated types.
- **SC-002**: `just ci` passes (build, unit tests, vector generation, format check, hlint).
- **SC-003**: `lake build` compiles the updated Lean specification with no errors.
- **SC-004**: Test vectors include a mixed Modify redeemer with both `Update` and `Rejected` entries.

## Assumptions

- The Aiken on-chain validator will be updated separately (cardano-foundation/cardano-mpfs-onchain#39).
- Constructor indices for End (0), Contribute (1), Modify (2), Retract (3) are preserved — only Reject (4) is removed.
- The oracle service will be updated to produce mixed Modify redeemers instead of separate Modify + Reject transactions.
