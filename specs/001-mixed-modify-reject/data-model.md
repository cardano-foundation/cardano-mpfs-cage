# Data Model: Mixed Update/Reject in Modify Redeemer

## Entity Changes

### RequestAction (new)

```
Update ![ProofStep]    -- Constr 0 [List [...]]
Rejected               -- Constr 1 []
```

A per-request action: either proof-based update or expiry-based rejection. Type-safe — no overloading of empty lists.

### UpdateRedeemer (modified)

**Before** (5 constructors):
```
End                          -- Constr 0 []
Contribute OnChainTxOutRef   -- Constr 1 [ref]
Modify [[ProofStep]]         -- Constr 2 [List [List [...]]]
Retract OnChainTxOutRef      -- Constr 3 [ref]
Reject                       -- Constr 4 []
```

**After** (4 constructors):
```
End                          -- Constr 0 []
Contribute OnChainTxOutRef   -- Constr 1 [ref]
Modify [RequestAction]       -- Constr 2 [List [Constr ...]]
Retract OnChainTxOutRef      -- Constr 3 [ref]
```

### On-chain encoding examples

| Haskell value | PlutusData |
|---------------|------------|
| `Modify [Update [step1], Rejected, Update [step2]]` | `Constr 2 [List [Constr 0 [List [s1]], Constr 1 [], Constr 0 [List [s2]]]]` |
| `Modify [Rejected, Rejected]` | `Constr 2 [List [Constr 1 [], Constr 1 []]]` |
| `Modify [Update [step1, step2]]` | `Constr 2 [List [Constr 0 [List [s1, s2]]]]` |

### ProofStep (unchanged)

No changes to Branch, Fork, Leaf constructors or their encoding.

## Lean Model Changes

### RequestAction (new)

```lean
inductive RequestAction where
  | Update   (proofs : List Proof)
  | Rejected
```

### SpendRedeemer (modified)

**Before**:
```lean
inductive SpendRedeemer where
  | End
  | Contribute (stateRef : OutputReference)
  | Modify     (proofs : List Proof)
  | Retract    (stateRef : OutputReference)
  | Reject
```

**After**:
```lean
inductive SpendRedeemer where
  | End
  | Contribute (stateRef : OutputReference)
  | Modify     (actions : List RequestAction)
  | Retract    (stateRef : OutputReference)
```

The `ValidReject` structure is merged into `validSpend`'s Modify branch. Per-action validation: `Update` entries require proof verification; `Rejected` entries require rejectability (phase 3 / dishonest fee).
