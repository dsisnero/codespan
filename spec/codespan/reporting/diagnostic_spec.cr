require "../../spec_helper"

describe Codespan::Reporting::Severity do
  it "orders severities from help to bug" do
    Codespan::Reporting::Severity::Bug.should be > Codespan::Reporting::Severity::Error
    Codespan::Reporting::Severity::Error.should be > Codespan::Reporting::Severity::Warning
    Codespan::Reporting::Severity::Warning.should be > Codespan::Reporting::Severity::Note
    Codespan::Reporting::Severity::Note.should be > Codespan::Reporting::Severity::Help
  end
end

describe Codespan::Reporting::Label do
  it "builds primary/secondary labels with messages" do
    primary = Codespan::Reporting::Label.primary(7, 1...3).with_message("p")
    secondary = Codespan::Reporting::Label.secondary(7, 3...5).with_message("s")

    primary.style.should eq(Codespan::Reporting::LabelStyle::Primary)
    secondary.style.should eq(Codespan::Reporting::LabelStyle::Secondary)
    primary.message.should eq("p")
    secondary.message.should eq("s")
  end
end

describe Codespan::Reporting::Diagnostic do
  it "supports fluent builder pattern" do
    label = Codespan::Reporting::Label.primary(1, 4...7).with_message("middle")

    diagnostic = Codespan::Reporting::Diagnostic.error
      .with_code("E0001")
      .with_message("boom")
      .with_label(label)
      .with_note("detail")

    diagnostic.severity.should eq(Codespan::Reporting::Severity::Error)
    diagnostic.code.should eq("E0001")
    diagnostic.message.should eq("boom")
    diagnostic.labels.should eq([label])
    diagnostic.notes.should eq(["detail"])
  end
end
