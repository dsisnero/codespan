# Testing

## Running Tests

```bash
crystal spec
```

Currently 156 examples, 0 failures, 0 errors, 0 pending.

## Test Structure

| Directory | Purpose |
|-----------|---------|
| `spec/codespan/` | Unit specs for core types (index, span, location, file, lsp) |
| `spec/codespan/reporting/` | Specs for diagnostic, files, and term modules |
| `spec/codespan/reporting/term/` | Rendering specs — direct, snapshot, and golden parity |

## Golden Parity Tests

19 golden comparison tests are permanently wired in `spec/codespan/reporting/term/direct_comparison_spec.cr`. These compare Crystal output byte-for-byte against Rust golden files extracted from `vendor/codespan/codespan-reporting/tests/snapshots/`.

### Test Coverage

| Display Style | Tests | Modules |
|---------------|-------|---------|
| Rich | 12 | empty, message, message_and_notes, message_errorcode, same_line, multiline_overlapping, fizz_buzz, overlapping, empty_ranges, same_ranges, tabbed, tab_columns |
| Medium | 5 | empty, same_line, position_indicator, multiline_overlapping |
| Short | 3 | empty, same_line, multiline_overlapping |

### Updating Goldens

When rendering changes are intentional:

```bash
GOLDEN_UPDATE=1 crystal spec spec/codespan/reporting/term/direct_comparison_spec.cr
```

## Snapshot Parity Tests

`spec/codespan/reporting/term/snapshot_parity_spec.cr` compares Crystal output directly against Rust `.snap` files (stripping YAML frontmatter). These tests normalize trailing newlines for comparison robustness.

## Writing Tests

- Add parity-focused specs for each rust-codespan behavior ported
- Assert exact rendered output using golden comparison (`Golden.require_equal`)
- For new modules, create `_spec.cr` files mirroring the `src/` structure
- Use `spec_helper.cr` for shared bootstrap and project require
