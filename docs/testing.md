# Testing

## Running Tests

```bash
crystal spec
```

## Test Conventions

- Specs live under `spec/`.
- Spec files use the `_spec.cr` suffix (for example, `spec/codespan_spec.cr`).
- Shared test bootstrap is centralized in `spec/spec_helper.cr`.

## Writing Tests

- Add parity-focused examples for each rust-codespan behavior ported into `src/`.
- Assert exact values for spans, labels, and rendered diagnostics where output fidelity matters.
- Keep each example scoped to one behavior branch so regressions are easy to isolate.

## Coverage

<!-- TODO: Add coverage tooling/command when configured for this shard. -->
