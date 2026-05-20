# Architecture

`codespan` is a Crystal port of [rust-codespan](https://github.com/brendanzab/codespan), providing diagnostic rendering for text-based programming languages with exact output parity.

## Project Structure

```text
src/
  codespan.cr                           # Root module, requires, version constant
  codespan/
    index.cr                            # Byte/line/column index wrappers (ByteIndex, LineIndex, etc.)
    span.cr                             # Span type with merge/disjoint operations
    location.cr                          # Line + column location representation
    file.cr                             # Files database, FileId, line_starts, source slicing
    lsp.cr                              # LSP position/range ↔ byte offset conversion (UTF-16)
    reporting.cr                         # Reporting module wiring
    reporting/
      diagnostic.cr                     # Diagnostic/Label/Severity types with fluent builders
      files.cr                          # SimpleFile/SimpleFiles, column_index, line_starts, error types
      term.cr                           # emit_into_string / emit_to_string entry points
      term/
        config.cr                       # Config, DisplayStyle, Chars (box-drawing/ascii)
        renderer.cr                     # Low-level terminal rendering (headers, snippets, carets, gutters)
        views.cr                        # RichDiagnostic / ShortDiagnostic view logic (label grouping, context)

spec/
  spec_helper.cr                        # Spec bootstrap and project require
  codespan_spec.cr                      # Core module spec
  codespan/
    file_spec.cr                        # Files, line_starts, location specs
    index_spec.cr                       # Index wrapper arithmetic specs
    location_spec.cr                    # Location initialization specs
    span_spec.cr                        # Span merge/disjoint/initial specs
    lsp_spec.cr                         # LSP conversion round-trip specs (5 tests)
    reporting/
      diagnostic_spec.cr                # Diagnostic builder API specs
      files_spec.cr                     # SimpleFiles/SimpleFile/column_index specs
      term/
        config_spec.cr                  # Config/Chars defaults specs
        term_spec.cr                    # Table-driven rich/medium/short display specs
        snapshot_parity_spec.cr         # Direct Rust snapshot comparison tests
        direct_comparison_spec.cr       # Golden file comparison tests (19 tests wired)
        golden_parity_spec.cr           # Auto-generated golden self-comparison tests (92 pending)
        actual_golden_parity_spec.cr    # Generated output vs golden comparison (4 tests)

scripts/
  generate_*.sh / check_*.sh           # Parity inventory generation and drift checks
  parity_inventory_lib.rb              # Source discovery library (regex + tree-sitter)
  ensure_parity_plan.sh                # Bootstrap missing parity manifests
  verify_parity_adversarial.sh         # Independent parity signoff

plans/
  inventory/
    rust_port_inventory.tsv            # Curated working ledger (155 items tracked)
    rust_source_parity.tsv             # Source API drift manifest (128 items)
    rust_test_parity.tsv               # Test drift manifest (22 items)
  cross_language_parity_update.md      # Multi-repo tracking and script fix log

spec/testdata/
  rust_snapshots/                      # 92 golden files extracted from Rust snapshots
  crystal_snapshots/                   # Crystal-generated golden files

vendor/
  codespan/                            # Rust upstream submodule (pinned at b563293)
    codespan-reporting/src/            # Rust source of truth for rendering
```

## Data Flow

1. **Input**: Diagnostics with severity, code, message, labels, and source files (`SimpleFiles`)
2. **Views** (`views.cr`): Group labels by file, compute line numbers, determine multi-line spans, calculate outer padding
3. **Renderer** (`renderer.cr`): Output formatted text — headers, snippet borders, source lines, single-line carets, multiline `╭│╰` markers, notes
4. **Term** (`term.cr`): Routes `DisplayStyle` → `RichDiagnostic` or `ShortDiagnostic` through `Renderer`
5. **Verification**: Golden tests compare Crystal output byte-for-byte against Rust snapshots

## Module Responsibilities

| Module | Responsibility |
|--------|---------------|
| `Codespan` | Top-level namespace, version constant |
| `Codespan::Span` | Half-open byte ranges with merge and disjoint operations |
| `Codespan::Location` | Line index + column index pair |
| `Codespan::File` | `Files` database, `FileId`, line starts, source slicing |
| `Codespan::Index` | Typed wrappers: `ByteIndex`, `ByteOffset`, `LineIndex`, `ColumnIndex`, etc. |
| `Codespan::Lsp` | Byte offset ↔ LSP position/range conversion (UTF-16 code units) |
| `Codespan::Reporting` | Namespace for diagnostic types and term rendering |
| `Codespan::Reporting::Files` | `SimpleFile`/`SimpleFiles`, `column_index`, error types |
| `Codespan::Reporting::Diagnostic` | `Severity`, `LabelStyle`, `Label`, `Diagnostic` with fluent builders |
| `Codespan::Reporting::Term::Config` | `DisplayStyle`, `Chars`, tab width, context line counts |
| `Codespan::Reporting::Term::Renderer` | Core rendering engine — headers, gutters, carets, multiline markers |
| `Codespan::Reporting::Term::Views` | `RichDiagnostic`/`ShortDiagnostic` — label grouping and orchestration |
