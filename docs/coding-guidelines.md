# Coding Guidelines

## Code Style

- Format with `crystal tool format` — run `crystal tool format --check src spec` before commits
- Lint with `ameba src spec` — zero failures required
- Use `CamelCase` for modules/classes/structs, `snake_case` for methods and variables
- Keep file names aligned to module boundaries under `src/codespan/`

## Error Handling

- Match rust-codespan error semantics exactly — raise `Codespan::Reporting::Files::*Error` types for file/index/column/char-boundary violations
- Prefer explicit typed exceptions over nil-based control flow
- Error types defined in `src/codespan/reporting/files.cr`:
  - `FileMissingError`, `IndexTooLargeError`, `LineTooLargeError`, `ColumnTooLargeError`, `InvalidCharBoundaryError`, `FormatError`

## Porting Conventions

- **Byte-based semantics**: Use `Bytes`/`Slice(UInt8)` for binary offsets, `String#to_slice` for byte-indexed access
- **Crystal `String#[]` is character-indexed**: Use `String.new(source.to_slice[start, count])` for byte-based slicing
- **Unicode width**: Use `UnicodeCharWidth.width(char)` (from `uniwidth` shard) for display width
- **Tab stops**: Compute as `tab_width - (col % tab_width)`, not fixed width
- **Multiline labels**: Inner gutter is 2 chars per column (`"  "`, `" │"`, `" ╭"`, `" ╰"`)
- **Zero-width labels**: Chain a `\0` placeholder after source chars for end-of-line caret rendering

## Key Patterns

```crystal
# Byte-based source slicing
String.new(source.to_slice[range.begin, range.end - range.begin])

# Display-width-aware character iteration
display_col = 0
char_index = 0
source.each_char do |char|
  w = char_display_width(char, display_col)
  # ... render w characters ...
  display_col += w
  char_index += 1
end

# Tab-stop-aware display width
def char_display_width(char, col)
  if char == '\t'
    tw = @config.tab_width
    tw == 0 ? 0 : tw - (col % tw)
  else
    UnicodeCharWidth.width(char)
  end
end
```
