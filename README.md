<p align="center">
  <strong>Beautiful diagnostic reporting for text-based programming languages — Crystal port of rust codespan</strong><br>
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

codespan transforms compiler errors into readable diagnostics — spanning code regions with carets, underlines, and labels to provide context and clarity. This Crystal port keeps the precision and clarity of [rust-codespan](https://github.com/brendanzab/codespan) while adapting implementation details to Crystal idioms.

**Status**: 156 specs, 19 golden parity tests, rendering complete for all display styles (Rich/Medium/Short).

---

## Quick Start

```bash
shards install
crystal spec
```

## Features

- **Rich diagnostic rendering**: Box-drawing borders, carets, multiline labels with `╭│╰` markers
- **Three display styles**: Rich (full source context), Medium (header + notes), Short (header only)
- **Unicode & tab support**: Tab-stop-aware spacing, CJK/wide character display width
- **LSP integration**: Byte offset ↔ LSP position/range conversion with UTF-16 encoding
- **19 golden parity tests**: Validated byte-for-byte against Rust codespan output

## Installation

```yaml
dependencies:
  codespan:
    github: dsisnero/codespan
```

## Usage

```crystal
require "codespan"

files = Codespan::Reporting::Files::SimpleFiles.new
file_id = files.add("test.cr", "1 + \"hello\"\n")

diagnostic = Codespan::Reporting::Diagnostic.error
  .with_message("type mismatch")
  .with_code("E0001")
  .with_labels([
    Codespan::Reporting::Label.primary(file_id, 4...11)
      .with_message("expected Int, found String"),
  ])

config = Codespan::Reporting::Term::Config.new
output = Codespan::Reporting::Term.emit_into_string(config, files, diagnostic)
puts output
```

## Development

```bash
shards install
crystal tool format --check src spec
ameba src spec
crystal spec
```

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design, data flow, package responsibilities |
| [Development](docs/development.md) | Prerequisites, setup, daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Code style, error handling, naming conventions |
| [Testing](docs/testing.md) | Test commands, conventions, golden parity |
| [PR Workflow](docs/pr-workflow.md) | Commits, PRs, branch naming, review process |
| [Porting Parity](docs/porting-parity.md) | Upstream commit pin, coverage ledger, parity verification |

## Contributors

- [Dominic Sisneros](https://github.com/dsisnero) — creator and maintainer
