# Architecture

`codespan` is a Crystal shard that provides diagnostic rendering for text-based programming languages, ported from rust-codespan behavior with exact output parity.

## Project Structure

```text
src/
  codespan.cr                           # Root module and version constant
  codespan/
    reporting/
      term/
        views.cr                        # Rich diagnostic view rendering
        renderer.cr                     # Low-level terminal output rendering
        config.cr                       # Configuration and character sets
      files.cr                          # File source management
      diagnostic.cr                     # Diagnostic data structures
      label.cr                          # Label styling and positioning
    file.cr                             # File abstraction
    location.cr                         # Line/column location tracking
    span.cr                             # Byte offset ranges
    index.cr                            # Line index computation
spec/
  spec_helper.cr                        # Spec bootstrap and project require
  codespan_spec.cr                      # Core module specs
  codespan/                             # Module-specific specs
    reporting/
      term/
        snapshot_parity_spec.cr         # Rust snapshot comparison tests
        direct_comparison_spec.cr       # Golden file comparison tests
        golden_parity_spec.cr           # Auto-generated golden tests
scripts/
  generate_rust_golden.cr               # Extract golden files from Rust snapshots
vendor/
  codespan/                             # Rust upstream submodule (pinned)
    codespan-reporting/                 # Rust source of truth
      tests/snapshots/                  # Rust snapshot test outputs
spec/testdata/
  rust_snapshots/                       # Extracted golden files from Rust
```

## Data Flow

1. **Input**: Diagnostics with labels, severity, and source files
2. **Processing**: Views organize labels by file, compute line numbers and padding
3. **Rendering**: Renderer outputs formatted text with borders, labels, and source snippets
4. **Verification**: Golden tests compare Crystal output against Rust snapshots

Key data structures:
- `Diagnostic`: Error/warning with message, code, severity, and labels
- `Label`: Marks a span in source code with style and message  
- `Files`: Manages source text and line indexing
- `RichDiagnostic`: Renders diagnostics with source context

## Package/Module Responsibilities

- `Codespan`: Top-level namespace for all Crystal ports of rust-codespan concepts
- `Codespan::Reporting::Term`: Terminal output rendering with rich formatting
- `Codespan::Reporting::Files`: Source file management and line indexing
- `Codespan::File`: File abstraction with name and source content
- `Codespan::Location`: Line/column location tracking
- `Codespan::Span`: Byte offset ranges within source text
- `Codespan::Index`: Line index computation and validation
- `spec`: Behavior and parity verification harness with golden testing
