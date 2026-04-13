# Research: Mixed Update/Reject in Modify Redeemer

No NEEDS CLARIFICATION items. All technical decisions are determined by the existing codebase.

## Decisions

### 1. RequestAction sum type vs. empty-list encoding

**Decision**: Introduce a `RequestAction` sum type (`Update [ProofStep] | Rejected`) instead of overloading empty lists to mean rejection.
**Rationale**: Empty lists are ambiguous — they could mean "bug" (forgot to fill proofs) or "intentional rejection". A dedicated constructor makes the intent type-safe and explicit. Pattern matching is cleaner in both Haskell and Lean.
**Alternatives considered**: Using empty `[ProofStep]` to signal rejection — rejected because it loses type-level distinction and makes the Lean spec muddier.

### 2. Remove standalone Reject constructor

**Decision**: Remove `Reject` constructor (Constr 4) entirely.
**Rationale**: `Modify [Rejected, Rejected, ...]` is the new way to reject all requests. No need for two paths.
**Alternatives considered**: Keep Reject as a pattern synonym — rejected because it complicates PlutusData encoding (two representations for the same thing).

### 3. Constructor index stability

**Decision**: Preserve indices 0-3 (End, Contribute, Modify, Retract). Remove index 4 (Reject).
**Rationale**: Retract (Constr 3) is unaffected. No index renumbering needed since we're removing the last constructor.

### 4. RequestAction encoding

**Decision**: `Update` = Constr 0, `Rejected` = Constr 1.
**Rationale**: Standard constructor ordering. Update is the common case, gets index 0.

### 5. Empty outer list semantics

**Decision**: `Modify []` (empty action list = no requests) is a valid encoding. Its on-chain semantics are defined by the Aiken validator, not by this package.
**Rationale**: This package only handles encoding/decoding. Semantic validation is the validator's responsibility.
