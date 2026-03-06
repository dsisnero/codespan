require "../../../spec_helper"

describe Codespan::Reporting::Term do
  it "emits rich output with labels and notes" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add("test.rs", "let x = 1;\nlet y = x + 2;\n")

    diagnostic = Codespan::Reporting::Diagnostic.error
      .with_code("E0001")
      .with_message("unexpected type")
      .with_label(Codespan::Reporting::Label.primary(file_id, 4...7).with_message("here"))
      .with_note("expected Int")

    output = Codespan::Reporting::Term.emit_into_string(
      Codespan::Reporting::Term::Config.default,
      files,
      diagnostic
    )

    output.should contain("error[E0001]: unexpected type")
    output.should contain("  │     ^^^ here")
    output.should contain("= expected Int")
  end

  it "emits short output without notes" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add("test.rs", "run --help\n")

    config = Codespan::Reporting::Term::Config.new(
      display_style: Codespan::Reporting::Term::DisplayStyle::Short
    )

    diagnostic = Codespan::Reporting::Diagnostic.help
      .with_message("run --help")
      .with_label(Codespan::Reporting::Label.primary(file_id, 0...3))
      .with_note("extra")

    output = Codespan::Reporting::Term.emit_into_string(config, files, diagnostic)

    output.should contain("test.rs:1:1: help: run --help")
    output.should_not contain("extra")
  end

  it "emits rich source snippets with breaks for non-consecutive lines" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add("test.rs", "line1\nline2\nline3\nline4\nline5\n")

    diagnostic = Codespan::Reporting::Diagnostic.error
      .with_message("disjoint labels")
      .with_label(Codespan::Reporting::Label.primary(file_id, 0...2).with_message("first"))
      .with_label(Codespan::Reporting::Label.secondary(file_id, 24...26).with_message("second"))

    output = Codespan::Reporting::Term.emit_into_string(
      Codespan::Reporting::Term::Config.new(before_label_lines: 0, after_label_lines: 0),
      files,
      diagnostic
    )

    output.should contain("┌─ test.rs:1:1")
    output.should contain("1 │ line1")
    output.should contain("5 │ line5")
    output.should contain("·")
  end

  it "emits multiline label markers across spanned lines" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add("test.rs", "abc\n01234\nwxyz\n")

    diagnostic = Codespan::Reporting::Diagnostic.error
      .with_message("multiline")
      .with_label(Codespan::Reporting::Label.primary(file_id, 1...11).with_message("span"))

    output = Codespan::Reporting::Term.emit_into_string(
      Codespan::Reporting::Term::Config.new(before_label_lines: 0, after_label_lines: 0),
      files,
      diagnostic
    )

    output.should contain("╭──^")
    output.should contain("│")
    output.should contain("╰──^ span")
  end

  it "offsets overlapping multiline labels into deterministic columns" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add("test.rs", "abcde\n01234\nwxyz\n")

    diagnostic = Codespan::Reporting::Diagnostic.error
      .with_message("overlap")
      .with_label(Codespan::Reporting::Label.primary(file_id, 1...11).with_message("first"))
      .with_label(Codespan::Reporting::Label.secondary(file_id, 2...12).with_message("second"))

    output = Codespan::Reporting::Term.emit_into_string(
      Codespan::Reporting::Term::Config.new(before_label_lines: 0, after_label_lines: 0),
      files,
      diagnostic
    )

    output.should contain("╭──^")
    output.should contain("╭──'")
    output.should contain("╰──^ first")
    output.should contain("╰──' second")
  end
end
