# PR Workflow

## Commit Conventions

Format: `<type>(<scope>): <description>`

Types: feat, fix, docs, refactor, test, chore, perf

### Examples

- `feat(diagnostic): port rust-codespan primary label rendering`
- `fix(span): correct utf8 byte index handling parity`
- `test(spec): add regression for multiline underline formatting`

## Branch Naming

Format: `<type>/<issue-number>-<short-kebab-description>`

### Examples

- `feat/42-port-diagnostic-renderer`
- `fix/87-byte-offset-parity`
- `test/103-add-span-edge-cases`

## PR Checklist

- [ ] Code follows project guidelines (see [Coding Guidelines](coding-guidelines.md))
- [ ] Tests added/updated (see [Testing](testing.md))
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated for user-facing changes
- [ ] Lint/format checks pass
- [ ] All tests pass

## Review Process

1. Verify parity intent for each change against rust-codespan behavior.
2. Run Crystal code gates locally:
   - `crystal tool format --check src spec`
   - `ameba src spec`
   - `crystal spec`
3. Confirm the PR description explains which rust behavior was ported and which edge cases were covered by specs.
