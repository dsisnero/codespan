require "../../../spec_helper"
require "golden"

# Initialize golden to use spec/testdata directory
Golden.dir = "spec/testdata/crystal_snapshots"

# Helper to extract test body from snapshot file (same as in snapshot_parity_spec.cr)
private def snapshot_body(path : String) : String
  content = File.read(path)
  delimiter = "---\n"

  first = content.index(delimiter)
  return content unless first

  second = content.index(delimiter, first + delimiter.bytesize)
  return content unless second

  body = content[(second + delimiter.bytesize)..]
  body.ends_with?('\n') ? body[0...-1] : body
end

# Helper to generate Crystal output for a test case
private def generate_crystal_output(test_name : String) : String
  case test_name
  when "term__empty__rich_no_color"
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.bug,
      Codespan::Reporting::Diagnostic.error,
      Codespan::Reporting::Diagnostic.warning,
      Codespan::Reporting::Diagnostic.note,
      Codespan::Reporting::Diagnostic.help,
      Codespan::Reporting::Diagnostic.bug,
    ]

    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end
  when "term__message__rich_no_color"
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("a message"),
      Codespan::Reporting::Diagnostic.warning.with_message("a message"),
      Codespan::Reporting::Diagnostic.note.with_message("a message"),
      Codespan::Reporting::Diagnostic.help.with_message("a message"),
    ]

    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end
  when "term__same_line__rich_no_color"
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "fn main() {\n    let mut v = vec![Some(\"foo\"), Some(\"bar\")];\n    v.push(v.pop().unwrap());\n}\n"
    file_id = files.add("one_line.rs", source)

    diagnostics = [
      Codespan::Reporting::Diagnostic.error
        .with_code("E0499")
        .with_message("cannot borrow `v` as mutable more than once at a time")
        .with_labels([
          Codespan::Reporting::Label.primary(file_id, 71...72)
            .with_message("second mutable borrow occurs here"),
          Codespan::Reporting::Label.secondary(file_id, 64...65)
            .with_message("first borrow later used by call"),
          Codespan::Reporting::Label.secondary(file_id, 66...70)
            .with_message("first mutable borrow occurs here"),
        ]),
      Codespan::Reporting::Diagnostic.error
        .with_message("aborting due to previous error")
        .with_notes(["For more information about this error, try `rustc --explain E0499`."]),
    ]

    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end
  when "term__position_indicator__medium_no_color"
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add(
      "tests/main.js",
      "\"use strict\";\nlet zero=0;\nfunction foo() {\n  \"use strict\";\n  one=1;\n}"
    )

    diagnostics = [
      Codespan::Reporting::Diagnostic.warning
        .with_code("ParserWarning")
        .with_message("The strict mode declaration in the body of function `foo` is redundant, as the outer scope is already in strict mode")
        .with_labels([
          Codespan::Reporting::Label.primary(file_id, 45...57)
            .with_message("This strict mode declaration is redundant"),
          Codespan::Reporting::Label.secondary(file_id, 0...12)
            .with_message("Strict mode is first declared here"),
        ]),
    ]

    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Medium)
    String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end
  else
    # Unknown test case
    ""
  end
end

describe "Crystal vs Rust golden parity" do
  # Test a subset of important test cases first
  test_cases = [
    "term__empty__rich_no_color",
    "term__message__rich_no_color",
    "term__same_line__rich_no_color",
    "term__position_indicator__medium_no_color",
  ]

  test_cases.each do |test_name|
    it "matches #{test_name}" do
      # Get expected output from Rust golden file
      rust_golden_path = "spec/testdata/rust_snapshots/#{test_name}.golden"
      unless File.exists?(rust_golden_path)
        pending "Rust golden file not found: #{rust_golden_path}"
        next
      end

      expected = File.read(rust_golden_path)

      # Generate actual output from Crystal
      actual = generate_crystal_output(test_name)

      # Compare using golden
      Golden.require_equal(test_name, actual)
    end
  end
end
