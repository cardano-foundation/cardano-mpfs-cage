# cardano-mpfs-cage Constitution

## Core Principles

### I. Byte-Exact Encoding Fidelity
Every Haskell type and its `ToData`/`FromData` instance must match the Aiken on-chain layout byte-for-byte. Constructor indices, field ordering, and nesting depth are the contract — any divergence breaks cross-language validation.

### II. Cross-Language Test Vectors
Changes to types must be reflected in the test vector generator. Vectors are the bridge between Haskell, Aiken, and any future client — they are the executable specification.

### III. Formal Properties First
The Lean 4 specification captures safety invariants as propositions. Type changes that affect validator semantics must update the Lean spec before or alongside the Haskell implementation.

### IV. Minimal Dependency Surface
This package deliberately avoids cardano-ledger. It uses Plutus primitives only. No wallet, no transaction building, no network dependencies. Keep it pure.

### V. Property-Based Testing
QuickCheck properties over hand-written generators verify roundtrip encoding and constructor index correctness. Example-based tests are secondary.

## Quality Gates

- `just ci` passes (build + unit + vectors + format-check + hlint)
- All exported types have Haddock documentation
- `cabal check` passes
- Lean spec compiles with `lake build` (no sorry)
- Test vectors validate against expected JSON structure

## Governance

Constitution supersedes ad-hoc decisions. Amendments require documentation and approval.

**Version**: 1.0.0 | **Ratified**: 2026-04-13
