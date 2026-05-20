# Cross-Language Parity Update

## Multi-Repo / Multi-Crate Setup

The codespan upstream is a monorepo (`vendor/codespan`) containing three Rust crates:

| Crate | Path | Purpose |
|-------|------|---------|
| `codespan` | `vendor/codespan/codespan/` | Core types: Span, FileId, Files, indexing |
| `codespan-reporting` | `vendor/codespan/codespan-reporting/` | Diagnostic reporting, term rendering |
| `codespan-lsp` | `vendor/codespan/codespan-lsp/` | LSP position/range conversion |

The parity scripts (`generate_port_inventory.sh`, `check_port_inventory.sh`, etc.) **already handle multi-crate repos** because `Dir.glob('**/*', base: source_path)` is fully recursive. Simply point `SOURCE_PATH` at the repo root (`vendor/codespan`).

### Discovery Command

```bash
./scripts/ensure_parity_plan.sh . vendor/codespan rust auto 0
```

This discovers all `.rs` files across all crates and generates three manifests:
- `plans/inventory/rust_port_inventory.tsv` — curated working ledger
- `plans/inventory/rust_source_parity.tsv` — source API drift manifest
- `plans/inventory/rust_test_parity.tsv` — test drift manifest

## Script Fixes Applied

### 1. Regex parser: generic Rust functions

**Problem:** The regex `/^pub\s+fn\s+([a-zA-Z_][A-Za-z0-9_]*)\s*\(/` cannot match functions with generic/lifetime parameters (e.g., `pub fn foo<'a, F>(...)`) because it requires `(` immediately after the function name.

**Fix:** Changed `fn_pat` and `method_pat` in `scripts/parity_inventory_lib.rb`:
```ruby
# Before
/^pub\s+fn\s+([a-zA-Z_][A-Za-z0-9_]*)\s*\(/

# After
/^pub\s+fn\s+([a-zA-Z_][A-Za-z0-9_]*)\s*(?:<[^>]*>)?\s*\(/
```

Also added `unless pub_impl` guard to prevent methods inside impl blocks from being matched as standalone functions.

**Coverage:** 4 previously undiscovered `codespan-lsp` functions now detected.

### 2. Stale detection: curated items

**Problem:** `check_port_inventory.rb` and `check_source_parity.rb` flagged manually curated items (e.g., `LspPosition`, `LspRange` re-exports) as "stale" because regex can't discover `use` aliases.

**Fix:** Stale detection now only errors on actively-maintained statuses:
- Port inventory: `skipped` and `intentional_divergence` items exempt
- Source parity: `skipped`, `intentional_divergence`, `mapped` items exempt

Also added source_parity cross-reference in `check_port_inventory.rb` to include manually-curated source_parity entries.

### 3. Inventory cleanup

Removed 12 duplicate `func::new` entries (methods incorrectly categorized as standalone functions by old regex). These are now correctly tracked as `method::*.new`.

## Known Regex Limitations (Documented)

The regex parser is a best-effort fallback when tree-sitter is unavailable:

| Limitation | Impact |
|------------|--------|
| Nested generics (`<T: Into<U>>`) | Functions with nested generic bounds not detected |
| Multi-line impl headers with `where` clauses | Methods incorrectly categorized as `func` |
| `use` re-exports (`pub use`, `use Foo as Bar`) | Re-exported types not discovered |
| `pub(crate)` / `pub(super)` visibility | Items with restricted visibility not discovered |
| Macro-generated items | Items produced by derive/attribute macros not detected |

**Recommendation:** Use `auto` or `tree-sitter` parser mode when `chiasmus-discover` is available for highest accuracy.

## Current Inventory Status

```
Port inventory:  152 items (97 ported, 53 skipped, 2 intentional_divergence)
Source parity:   128 API items (all missing/baseline)
Test parity:      22 tests (all missing/baseline)
```

## Verification

```bash
# All checks pass
./scripts/check_port_inventory.sh . plans/inventory/rust_port_inventory.tsv vendor/codespan rust
./scripts/check_source_parity.sh . plans/inventory/rust_source_parity.tsv vendor/codespan rust
./scripts/check_test_parity.sh . plans/inventory/rust_test_parity.tsv vendor/codespan rust

# Quality gates
crystal tool format --check src spec
ameba src spec
crystal spec  # 142 examples, 0 failures
```
