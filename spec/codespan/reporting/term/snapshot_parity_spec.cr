require "../../../spec_helper"

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

private def emit_all(
  diagnostics : Array(Codespan::Reporting::Diagnostic),
  files : Codespan::Reporting::Files::SimpleFiles,
  style : Codespan::Reporting::Term::DisplayStyle,
) : String
  config = Codespan::Reporting::Term::Config.new(display_style: style)
  String.build do |io|
    diagnostics.each do |diagnostic|
      Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
    end
  end
end

describe "term snapshot parity (empty)" do
  it "matches short_no_color snapshot" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.bug,
      Codespan::Reporting::Diagnostic.error,
      Codespan::Reporting::Diagnostic.warning,
      Codespan::Reporting::Diagnostic.note,
      Codespan::Reporting::Diagnostic.help,
      Codespan::Reporting::Diagnostic.bug,
    ]

    actual = emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Short)
    expected = snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__empty__short_no_color.snap")

    actual.should eq(expected)
  end

  it "matches medium_no_color snapshot" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.bug,
      Codespan::Reporting::Diagnostic.error,
      Codespan::Reporting::Diagnostic.warning,
      Codespan::Reporting::Diagnostic.note,
      Codespan::Reporting::Diagnostic.help,
      Codespan::Reporting::Diagnostic.bug,
    ]

    actual = emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Medium)
    expected = snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__empty__medium_no_color.snap")

    actual.should eq(expected)
  end

  it "matches rich_no_color snapshot" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.bug,
      Codespan::Reporting::Diagnostic.error,
      Codespan::Reporting::Diagnostic.warning,
      Codespan::Reporting::Diagnostic.note,
      Codespan::Reporting::Diagnostic.help,
      Codespan::Reporting::Diagnostic.bug,
    ]

    actual = emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Rich)
    expected = snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__empty__rich_no_color.snap")

    actual.should eq(expected)
  end
end

describe "term snapshot parity (message)" do
  it "matches short/medium/rich no_color snapshots" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("a message"),
      Codespan::Reporting::Diagnostic.warning.with_message("a message"),
      Codespan::Reporting::Diagnostic.note.with_message("a message"),
      Codespan::Reporting::Diagnostic.help.with_message("a message"),
    ]

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Short)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__message__short_no_color.snap"))

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Medium)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__message__medium_no_color.snap"))

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Rich)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__message__rich_no_color.snap"))
  end
end

describe "term snapshot parity (message_and_notes)" do
  it "matches medium/rich no_color snapshots" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("a message").with_notes(["a note"]),
      Codespan::Reporting::Diagnostic.warning.with_message("a message").with_notes(["a note"]),
      Codespan::Reporting::Diagnostic.note.with_message("a message").with_notes(["a note"]),
      Codespan::Reporting::Diagnostic.help.with_message("a message").with_notes(["a note"]),
    ]

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Medium)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__message_and_notes__medium_no_color.snap"))

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Rich)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__message_and_notes__rich_no_color.snap"))
  end
end

describe "term snapshot parity (message_errorcode)" do
  it "matches short/rich no_color snapshots" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("a message").with_code("E0001"),
      Codespan::Reporting::Diagnostic.warning.with_message("a message").with_code("W001"),
      Codespan::Reporting::Diagnostic.note.with_message("a message").with_code("N0815"),
      Codespan::Reporting::Diagnostic.help.with_message("a message").with_code("H4711"),
      Codespan::Reporting::Diagnostic.error.with_message("where did my errorcode go?").with_code(""),
      Codespan::Reporting::Diagnostic.warning.with_message("where did my errorcode go?").with_code(""),
      Codespan::Reporting::Diagnostic.note.with_message("where did my errorcode go?").with_code(""),
      Codespan::Reporting::Diagnostic.help.with_message("where did my errorcode go?").with_code(""),
    ]

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Short)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__message_errorcode__short_no_color.snap"))

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Rich)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__message_errorcode__rich_no_color.snap"))
  end
end

describe "term snapshot parity (same_line)" do
  it "matches short/medium/rich no_color snapshots" do
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

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Short)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__same_line__short_no_color.snap"))

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Medium)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__same_line__medium_no_color.snap"))

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Rich)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__same_line__rich_no_color.snap"))
  end
end

describe "term snapshot parity (position_indicator)" do
  it "matches short/medium no_color snapshots" do
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

    emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Short)
      .should eq(snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__position_indicator__short_no_color.snap"))

    medium_actual = emit_all(diagnostics, files, Codespan::Reporting::Term::DisplayStyle::Medium)
    medium_expected = snapshot_body("vendor/codespan/codespan-reporting/tests/snapshots/term__position_indicator__medium_no_color.snap")
    medium_actual.should eq(medium_expected.rstrip('\n') + "\n")
  end
end
