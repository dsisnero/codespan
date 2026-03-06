require "../../../spec_helper"
require "golden"

# Set golden to use the rust snapshots directory
Golden.dir = "spec/testdata/rust_snapshots"

# Helper to generate Crystal output for empty test
private def generate_empty_crystal_output(style : Codespan::Reporting::Term::DisplayStyle) : String
  files = Codespan::Reporting::Files::SimpleFiles.new
  diagnostics = [
    Codespan::Reporting::Diagnostic.bug,
    Codespan::Reporting::Diagnostic.error,
    Codespan::Reporting::Diagnostic.warning,
    Codespan::Reporting::Diagnostic.note,
    Codespan::Reporting::Diagnostic.help,
    Codespan::Reporting::Diagnostic.bug,
  ]

  config = Codespan::Reporting::Term::Config.new(display_style: style)
  String.build do |io|
    diagnostics.each do |diagnostic|
      Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
    end
  end
end

describe "Crystal vs Rust comparison using golden" do
  it "matches term__empty__rich_no_color" do
    # Generate actual output from Crystal
    actual = generate_empty_crystal_output(Codespan::Reporting::Term::DisplayStyle::Rich)

    # Compare using golden - this will show a nice diff if they don't match
    Golden.require_equal("term__empty__rich_no_color", actual)
  end

  it "matches term__empty__medium_no_color" do
    # Generate actual output from Crystal
    actual = generate_empty_crystal_output(Codespan::Reporting::Term::DisplayStyle::Medium)

    # Compare using golden
    Golden.require_equal("term__empty__medium_no_color", actual)
  end

  it "matches term__empty__short_no_color" do
    # Generate actual output from Crystal
    actual = generate_empty_crystal_output(Codespan::Reporting::Term::DisplayStyle::Short)

    # Compare using golden
    Golden.require_equal("term__empty__short_no_color", actual)
  end

  it "matches term__same_line__rich_no_color" do
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
    actual = String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end

    # Compare using golden - this should show a diff since we know this test was failing
    Golden.require_equal("term__same_line__rich_no_color", actual)
  end

  it "matches term__position_indicator__medium_no_color" do
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
    actual = String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end

    # Compare using golden
    Golden.require_equal("term__position_indicator__medium_no_color", actual)
  end
end
