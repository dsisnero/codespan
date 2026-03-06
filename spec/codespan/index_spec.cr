require "../spec_helper"

describe Codespan::LineIndex do
  it "returns one-indexed line numbers" do
    Codespan::LineIndex.from(0).number.should eq(Codespan::LineNumber.new(1_u32))
    Codespan::LineIndex.from(3).number.should eq(Codespan::LineNumber.new(4_u32))
  end
end

describe Codespan::ColumnIndex do
  it "returns one-indexed column numbers" do
    Codespan::ColumnIndex.from(0).number.should eq(Codespan::ColumnNumber.new(1_u32))
    Codespan::ColumnIndex.from(3).number.should eq(Codespan::ColumnNumber.new(4_u32))
  end
end

describe Codespan::ByteOffset do
  it "computes UTF-8 char lengths" do
    Codespan::ByteOffset.from_char_len('A').to_usize.should eq(1)
    Codespan::ByteOffset.from_char_len('ß').to_usize.should eq(2)
    Codespan::ByteOffset.from_char_len('ℝ').to_usize.should eq(3)
    Codespan::ByteOffset.from_char_len('💣').to_usize.should eq(4)
  end

  it "computes UTF-8 string lengths" do
    Codespan::ByteOffset.from_str_len("A").to_usize.should eq(1)
    Codespan::ByteOffset.from_str_len("ß").to_usize.should eq(2)
    Codespan::ByteOffset.from_str_len("ℝ").to_usize.should eq(3)
    Codespan::ByteOffset.from_str_len("💣").to_usize.should eq(4)
  end
end
