# Coding Guidelines

## Code Style

- Keep Crystal code formatted with `crystal tool format`.
- Keep static analysis clean with `ameba src spec`.
- Preserve a minimal public surface under the `Codespan` namespace until behavior is ported and tested.

## Error Handling

- Match rust-codespan behavior and edge cases before introducing Crystal-specific abstractions.
- Prefer explicit types and return values over implicit nil-based control flow where parity-sensitive behavior is involved.

<!-- TODO: Add concrete error type and diagnostic propagation rules once implementation exists. -->

## Naming Conventions

- Use `CamelCase` for module/class/type names (for example, `Codespan`).
- Use `snake_case` for methods, variables, and file names.
- Keep file names aligned to Crystal constants and module boundaries as files are added.

## Documentation

- Document public APIs in `src/` as they are introduced.
- When behavior differs from rust-codespan due to Crystal runtime constraints, document the rationale near the code and in docs.

<!-- TODO: Add side-by-side porting examples from rust-codespan once first non-trivial modules land. -->
