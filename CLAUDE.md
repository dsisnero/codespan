# codespan

Beautiful diagnostic reporting for text-based programming languages - crystal port of rust codespan

## Commands

```bash
shards install
crystal spec
crystal tool format --check src spec
ameba src spec
```

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design, data flow, package responsibilities |
| [Development](docs/development.md) | Prerequisites, setup, daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Code style, error handling, naming conventions |
| [Testing](docs/testing.md) | Test commands, conventions, patterns |
| [PR Workflow](docs/pr-workflow.md) | Commits, PRs, branch naming, review process |
| [Porting Parity](docs/porting-parity.md) | Upstream commit pin, coverage ledger, and parity verification status |

## Core Principles

1. Rust code is the source of truth.
2. Do not skip functionality.
3. Port logic faithfully while using Crystal libraries and idioms.

## Commits

Format: `<type>(<scope>): <description>`

Types: feat, fix, docs, refactor, test, chore, perf

- `feat(parser): port diagnostic label merging from rust-codespan`
- `fix(span): align byte offset handling with rust reference`
- `test(spec): add parity coverage for multiline diagnostics`

## Crystal Code Gates

```bash
crystal tool format --check src spec
ameba src spec
crystal spec
```

## Conventions

- Do not add attribution trailers (for example, `Co-Authored-By`) in commits or PRs.
- Keep parity notes explicit in PR descriptions: which rust-codespan behavior was ported and how it was verified.
