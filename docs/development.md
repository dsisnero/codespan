# Development

## Prerequisites

- Crystal `>= 1.19.1`
- `shards` for dependency management

## Setup

```bash
shards install
crystal spec
```

## Daily Workflow

1. Port one unit of rust-codespan behavior into Crystal source under `src/`.
2. Add or update specs under `spec/` to match expected behavior.
3. Run golden tests to verify parity with Rust output:

```bash
crystal spec

# Update golden files if Crystal output is correct and intentional
GOLDEN_UPDATE=1 crystal spec spec/codespan/reporting/term/direct_comparison_spec.cr
```

4. Run quality gates before committing:

```bash
crystal tool format --check src spec
ameba src spec
crystal spec
```

## Available Commands

| Command | Purpose |
|---------|---------|
| `shards install` | Install shard dependencies |
| `crystal spec` | Run full spec suite (156 tests) |
| `crystal tool format --check src spec` | Validate Crystal formatting |
| `ameba src spec` | Static analysis (13 files) |
| `GOLDEN_UPDATE=1 crystal spec` | Update golden files |

## Parity Workflow

```bash
# Bootstrap/validate parity plan
./scripts/ensure_parity_plan.sh . vendor/codespan rust auto 0

# Run drift checks
./scripts/check_port_inventory.sh . plans/inventory/rust_port_inventory.tsv vendor/codespan rust
./scripts/check_source_parity.sh . plans/inventory/rust_source_parity.tsv vendor/codespan rust
./scripts/check_test_parity.sh . plans/inventory/rust_test_parity.tsv vendor/codespan rust

# Adversarial verification
./scripts/verify_parity_adversarial.sh . vendor/codespan rust 'crystal spec' 'cargo test'
```

## Current State

| Metric | Value |
|--------|-------|
| Specs | 156 PASS |
| Golden tests wired | 19 |
| Verified golden matches | 27+ across rich/medium/short |
| Inventory ported | 117/155 items |
| Format/Ameba | PASS |
