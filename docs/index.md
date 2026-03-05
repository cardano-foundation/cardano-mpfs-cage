# MPFS Cage Specification

Language-agnostic specification package for the MPFS cage validator.

Provides PlutusData types, Lean 4 formal properties, and JSON test vectors for the cage validator — enabling cross-language validation without depending on cardano-ledger.

## Components

| Component | Description |
|-----------|-------------|
| Haskell library | `ToData`/`FromData` instances matching Aiken on-chain layout |
| Lean 4 spec | 16 formal safety properties |
| Test vectors | Deterministic JSON for cross-language conformance |

## Quick start

```bash
nix develop
just build
just unit
just vectors
```

## Documentation

- [Types](architecture/types.md) — on-chain data structures
- [Properties](architecture/properties.md) — formal safety properties
