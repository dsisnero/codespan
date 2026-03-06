<p align="center">
  <strong>Beautiful diagnostic reporting for text-based programming languages - crystal port of rust codespan</strong><br>
  A Crystal-native port focused on faithful diagnostic behavior.
</p>

<p align="center">
  <a href="docs/architecture.md">Architecture</a> &middot;
  <a href="docs/development.md">Development</a> &middot;
  <a href="docs/coding-guidelines.md">Guidelines</a> &middot;
  <a href="docs/testing.md">Testing</a> &middot;
  <a href="docs/pr-workflow.md">PR Workflow</a> &middot;
  <a href="docs/porting-parity.md">Porting Parity</a>
</p>

---

codespan transforms compiler errors into readable diagnostics - spanning code regions to provide context and clarity where it matters most. This Crystal port keeps the precision and clarity of rust-codespan while adapting implementation details to Crystal idioms. The goal is diagnostic output that feels native in Crystal but stays behaviorally anchored to the Rust reference.

---

## Quick Start

1. Install dependencies:

```bash
shards install
```

2. Run specs:

```bash
crystal spec
```

## Features

- Crystal shard scaffold ready for incremental rust-codespan parity porting.
- Dedicated `spec/` suite for behavior verification.
- Project docs and workflows aligned to parity-first development.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  codespan:
    github: dsisnero/codespan
```

2. Run `shards install`.

## Usage

```crystal
require "codespan"
```

<!-- TODO: Add end-to-end diagnostic usage examples once implementation is ported. -->

## Development

```bash
shards install
crystal tool format --check src spec
ameba src spec
crystal spec
```

See [Development Guide](docs/development.md) for full setup instructions.

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design and data flow |
| [Development](docs/development.md) | Setup and daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Code style and conventions |
| [Testing](docs/testing.md) | Test commands and patterns |
| [PR Workflow](docs/pr-workflow.md) | Commits, PRs, and review process |
| [Porting Parity](docs/porting-parity.md) | Upstream source pinning and parity tracking ledger |

## Contributing

1. Create an issue: `/forge-create-issue`
2. Implement: `/forge-implement-issue <number>`
3. Self-review: `/forge-reflect-pr`
4. Address feedback: `/forge-address-pr-feedback`
5. Update changelog: `/forge-update-changelog`

## Contributors

- [Dominic Sisneros](https://github.com/dsisnero) - creator and maintainer
