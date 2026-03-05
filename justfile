# shellcheck shell=bash

set unstable := true

# List available recipes
default:
    @just --list

# Format all source files
format:
    #!/usr/bin/env bash
    set -euo pipefail
    hs_files=$(find . -name '*.hs' -not -path './dist-newstyle/*' -not -path './.direnv/*')
    for i in {1..3}; do
        fourmolu -i $hs_files
    done
    find . -name '*.cabal' -not -path './dist-newstyle/*' | xargs cabal-fmt -i
    find . -name '*.nix' -not -path './dist-newstyle/*' | xargs nixfmt

# Check formatting without modifying files
format-check:
    #!/usr/bin/env bash
    set -euo pipefail
    hs_files=$(find . -name '*.hs' -not -path './dist-newstyle/*' -not -path './.direnv/*')
    fourmolu -m check $hs_files
    find . -name '*.cabal' -not -path './dist-newstyle/*' | xargs cabal-fmt -c

# Run hlint
hlint:
    #!/usr/bin/env bash
    set -euo pipefail
    find . -name '*.hs' -not -path './dist-newstyle/*' -not -path './.direnv/*' | xargs hlint

# Build all components
build:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build all -O0 --enable-tests --enable-benchmarks

# Run unit tests
unit match="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ '{{ match }}' == "" ]]; then
        cabal test cage-tests -O0 --test-show-details=direct
    else
        cabal test cage-tests -O0 \
            --test-show-details=direct \
            --test-option=--match \
            --test-option="{{ match }}"
    fi

# Full CI pipeline
ci:
    just build
    just unit
    just vectors
    just format-check
    just hlint

# Generate test vectors
vectors:
    cabal run cage-test-vectors -O0

# Clean build artifacts
clean:
    #!/usr/bin/env bash
    cabal clean
    rm -rf result
