# cardano-mpfs-cage

Language-agnostic specification package for the MPFS cage validator.

Provides PlutusData types, Lean 4 formal properties, and JSON test vectors for the cage validator — enabling cross-language validation without depending on cardano-ledger.

## Components

- **Haskell library** — `Cardano.MPFS.Cage.Types`, `.Proof`, `.AssetName`: hand-written `ToData`/`FromData` instances matching the Aiken on-chain layout byte-for-byte
- **Lean 4 specification** — 16 formal safety properties (token uniqueness, phase exclusivity, fee enforcement, migration integrity, …)
- **Test vector generator** — deterministic JSON vectors for cross-language conformance testing

## Development

Requires [Nix](https://nixos.org/) with flakes enabled.

```bash
nix develop          # enter dev shell
just                 # list available recipes
just build           # build all components
just unit            # run tests
just vectors         # generate test vectors
just ci              # full CI pipeline (build + test + format-check + hlint)
```

## License

[Apache-2.0](LICENSE)
