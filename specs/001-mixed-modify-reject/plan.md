# Implementation Plan: Mixed Update/Reject in Modify Redeemer

**Branch**: `001-mixed-modify-reject` | **Date**: 2026-04-13 | **Spec**: `specs/001-mixed-modify-reject/spec.md`

## Summary

Remove the `Reject` constructor (Constr 4) from `UpdateRedeemer` and unify rejection semantics into `Modify`. An empty proof list entry signals rejection; a non-empty one signals proof-based update. This affects Haskell types, PlutusData instances, QuickCheck tests, test vector generation, and the Lean 4 formal spec.

## Technical Context

**Language/Version**: Haskell (GHC 9.8.4)
**Primary Dependencies**: plutus-core, plutus-tx, mts:mpf, crypton, aiken-codegen
**Storage**: N/A
**Testing**: HSpec + QuickCheck (property-based roundtrip tests)
**Target Platform**: x86_64-linux, aarch64-darwin
**Project Type**: Library (specification/encoding package)
**Performance Goals**: N/A (compile-time encoding correctness)
**Constraints**: Byte-exact compatibility with Aiken on-chain layout
**Scale/Scope**: ~700 LOC library, ~340 LOC tests, ~500 LOC test vector generator, ~430 LOC Lean spec

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| I. Byte-Exact Encoding | PASS | Constructor indices 0-3 preserved; only Constr 4 removed |
| II. Cross-Language Test Vectors | PASS | Vectors updated with mixed Modify examples |
| III. Formal Properties First | PASS | Lean spec updated alongside Haskell |
| IV. Minimal Dependency Surface | PASS | No new dependencies |
| V. Property-Based Testing | PASS | Generators updated for mixed proof lists |

## Project Structure

### Documentation (this feature)

```text
specs/001-mixed-modify-reject/
├── plan.md
├── research.md
├── data-model.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/Cardano/MPFS/Cage/
├── Types.hs          # UpdateRedeemer: remove Reject, update instances
├── Proof.hs          # Unchanged
└── AssetName.hs      # Unchanged

test/Cardano/MPFS/Cage/
└── TypesSpec.hs      # Update generators and roundtrip tests

app/test-vectors/
└── Main.hs           # Replace Reject vector with mixed Modify vector

lean/MpfsCage/
└── Spec.lean         # Remove Reject from SpendRedeemer, merge into Modify
```
