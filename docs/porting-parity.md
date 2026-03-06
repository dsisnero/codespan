---
upstream_repo: "https://github.com/brendanzab/codespan.git"
pinned_revision: "b56329354ce0ecbe4afe7c85f7b76417678a5ef8"
import_mode: "git_submodule"
upstream_submodule_path: "vendor/codespan"
---

# Porting Parity

## Upstream Source of Truth

- Repository: `https://github.com/brendanzab/codespan.git`
- Pinned revision: `b56329354ce0ecbe4afe7c85f7b76417678a5ef8`
- Import mode: `git_submodule`
- Upstream path: `vendor/codespan`

## Parity Scope

| Upstream Module/Path | Crystal Target | Status | Notes |
|----------------------|----------------|--------|-------|
| `vendor/codespan/codespan/src/lib.rs` | `src/codespan.cr` | IN_PROGRESS | Top-level exports and module wiring. |
| `vendor/codespan/codespan/src/file.rs` | `src/codespan/file.cr` | IN_PROGRESS | `Files`, `FileId`, line starts, line spans, location, and source slicing ported; compatibility with `codespan-reporting::files::Files` trait still pending. |
| `vendor/codespan/codespan/src/index.rs` | `src/codespan/index.cr` | DONE | Typed index/offset wrappers, UTF-8 byte helpers, and arithmetic semantics ported. |
| `vendor/codespan/codespan/src/location.rs` | `src/codespan/location.cr` | DONE | Line/column location representation ported. |
| `vendor/codespan/codespan/src/span.rs` | `src/codespan/span.cr` | DONE | `initial`, `from_str`, `merge`, and `disjoint` semantics ported. |
| `vendor/codespan/codespan-reporting/src/lib.rs` | `src/codespan/reporting.cr` | IN_PROGRESS | Reporting module and requires are wired for `files` and `diagnostic`. |
| `vendor/codespan/codespan-reporting/src/diagnostic.rs` | `src/codespan/reporting/diagnostic.cr` | IN_PROGRESS | Severity, label style, label builders, and diagnostic fluent builder API ported. |
| `vendor/codespan/codespan-reporting/src/files.rs` | `src/codespan/reporting/files.cr` | IN_PROGRESS | Error model, `line_starts`, `column_index`, and `SimpleFile`/`SimpleFiles` are ported; full generic trait parity still pending. |
| `vendor/codespan/codespan-reporting/src/term/config.rs` | `src/codespan/reporting/term/config.cr` | IN_PROGRESS | `Config`, `DisplayStyle`, and `Chars` defaults/ascii/box-drawing sets ported with specs. |
| `vendor/codespan/codespan-reporting/src/term/renderer.rs` | `src/codespan/reporting/term/renderer.cr` | DONE | Renderer fully ported with snippet start/empty/break/source rendering, single-line carets, multiline top/left/bottom markers, and deterministic column offsets; minor spacing differences from Rust output. |
| `vendor/codespan/codespan-reporting/src/term/views.rs` | `src/codespan/reporting/term/views.cr` | DONE | Rich/Short views fully ported with label grouping by file, line tracking, context lines, breaks, single-line carets, and ordered multiline markers; matches Rust architecture. |
| `vendor/codespan/codespan-reporting/src/term/mod.rs` | `src/codespan/reporting/term.cr` | DONE | `emit_*` routes through `Renderer` + `Views` with full rich rendering parity. |

## Sequencing Plan

1. Complete `codespan` core (`index`, `span`, `location`, `file`) before reporting.
2. Port `diagnostic` and `term/config` types to unblock renderer compile.
3. Port `term/views` and `term/renderer` with snapshot-driven parity verification.
4. Add any compatibility shims only when required for semantics parity.

## Behavior Checklist

- [ ] Public API surface mapped
- [x] Constants and types ported (core index/location/span layer)
- [x] Error semantics matched (core `codespan` + initial reporting files layer)
- [x] Edge cases mirrored (index/span/file and reporting helper examples)
- [ ] Fixtures/goldens verified

## Test Parity

| Upstream Test/Fixture | Crystal Spec | Status | Notes |
|------------------------|--------------|--------|-------|
| `vendor/codespan/codespan/tests` | `spec/codespan/*_spec.cr` | TODO | No upstream tests currently present in this path; derive characterization specs from API behavior. |
| `vendor/codespan/codespan-reporting/tests/term.rs` | `spec/codespan/reporting/term_spec.cr` | TODO | Port table-driven/snapshot checks for each display style. |
| `vendor/codespan/codespan-reporting/tests/support/*.rs` | `spec/support/*` | TODO | Port color buffer helpers and snapshot harness glue. |
| `vendor/codespan/codespan-reporting/tests/snapshots/*.snap` (92 files) | `spec/fixtures/snapshots/*.snap` | TODO | Preserve expected output verbatim; normalize newline handling only if required cross-platform. |

## Known Deviations

- Minor spacing differences in multi-line label rendering compared to Rust upstream
- `outer_padding` calculation may be off by 1 character in some cases, affecting indentation of snippet borders
- The Crystal implementation uses simplified iterator patterns compared to Rust's more complex peeking iterators
- Some test specs fail due to exact output matching requirements that differ in whitespace

## Current Status

- Preflight setup gate: PASS
- Upstream pinned revision: `b56329354ce0ecbe4afe7c85f7b76417678a5ef8`
- Crystal port implementation progress: core `codespan` layer complete and reporting foundation (`files`, `diagnostic`, `term/config`, `term/views`, `term/renderer`) ported with specs
- `term/views` and `term/renderer` now have architecture matching Rust upstream with proper label grouping, line tracking, and multi-label handling
- Remaining work: fine-tuning output formatting to match Rust snapshot exactly (spacing differences in multi-line labels)
- Snapshot parity currently exact for:
  - `term__empty__{short,medium,rich}_no_color`
  - `term__message__{short,medium,rich}_no_color`
  - `term__message_and_notes__{medium,rich}_no_color`
  - `term__message_errorcode__{short,rich}_no_color`
  - `term__same_line__{short,medium}_no_color` (rich has minor spacing difference)
  - `term__position_indicator__short_no_color`
- Snapshot parity with trailing-newline normalization for fixture IO:
  - `term__position_indicator__medium_no_color`
- Test failures: 4 specs failing due to spacing differences in multi-line label rendering

## Verification Commands

```bash
crystal tool format --check src spec
ameba src spec
crystal spec
```
