# Development

## Prerequisites

- Crystal `>= 1.19.1` (from `shard.yml`)
- `shards` for dependency management

## Setup

1. Install dependencies:

```bash
shards install
```

2. Run the current spec suite:

```bash
crystal spec
```

## Daily Workflow

1. Port one unit of rust-codespan behavior into Crystal source under `src/`.
2. Add or update specs under `spec/` to match expected behavior.
3. Run golden tests to verify parity with Rust output:

```bash
# Run all tests including golden comparisons
crystal spec

# Update golden files if Crystal output is correct
GOLDEN_UPDATE=1 crystal spec spec/codespan/reporting/term/direct_comparison_spec.cr
```

4. Run Crystal code gates before opening a PR:

```bash
crystal tool format --check src spec
ameba src spec
crystal spec
```

## Available Commands

- `shards install`: install shard dependencies.
- `crystal spec`: run the Crystal spec suite.
- `crystal tool format --check src spec`: validate Crystal formatting.
- `ameba src spec`: run static analysis for source and specs.
- `GOLDEN_UPDATE=1 crystal spec`: update golden files when output changes are intentional.
