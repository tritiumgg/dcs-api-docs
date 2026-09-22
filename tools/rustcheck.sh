#!/bin/sh
# The Rust half of `mise run check`: format, lint, build, test.
#
# Until the workspace exists there is nothing to check, and a check that
# fails for want of a Cargo.toml would block every document-only commit
# before the first crate lands. So the absence of the workspace is reported
# and passes; once Cargo.toml exists, every step below is a gate.

set -e

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

if [ ! -f Cargo.toml ]; then
    echo "rust: no workspace yet (Cargo.toml absent)"
    exit 0
fi

cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
cargo build --workspace --all-targets
cargo test --workspace
