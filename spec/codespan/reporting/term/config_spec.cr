require "../../../spec_helper"

describe Codespan::Reporting::Term::Config do
  it "uses rust default values" do
    config = Codespan::Reporting::Term::Config.default

    config.display_style.should eq(Codespan::Reporting::Term::DisplayStyle::Rich)
    config.tab_width.should eq(4)
    config.start_context_lines.should eq(3)
    config.end_context_lines.should eq(1)
    config.before_label_lines.should eq(0)
    config.after_label_lines.should eq(0)
    config.chars.snippet_start.should eq("┌─")
  end
end

describe Codespan::Reporting::Term::Chars do
  it "provides ascii chars" do
    chars = Codespan::Reporting::Term::Chars.ascii

    chars.snippet_start.should eq("-->")
    chars.source_border_left.should eq('|')
    chars.source_border_left_break.should eq('.')
    chars.multi_top_left.should eq('/')
    chars.multi_bottom_left.should eq('\\')
    chars.pointer_left.should eq('|')
  end

  it "provides unicode box drawing chars" do
    chars = Codespan::Reporting::Term::Chars.box_drawing

    chars.snippet_start.should eq("┌─")
    chars.source_border_left.should eq('│')
    chars.multi_top_left.should eq('╭')
    chars.multi_bottom_left.should eq('╰')
  end
end
