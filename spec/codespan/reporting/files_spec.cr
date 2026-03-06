require "../../spec_helper"

describe Codespan::Reporting::Files do
  it "computes column indexes like rust examples" do
    source = "\n\n🗻∈🌏\n\n"

    Codespan::Reporting::Files.column_index(source, 0...1, 0).should eq(0)
    Codespan::Reporting::Files.column_index(source, 2...13, 0).should eq(0)
    Codespan::Reporting::Files.column_index(source, 2...13, 2).should eq(0)
    Codespan::Reporting::Files.column_index(source, 2...13, 3).should eq(0)
    Codespan::Reporting::Files.column_index(source, 2...13, 6).should eq(1)
    Codespan::Reporting::Files.column_index(source, 2...13, 10).should eq(2)
    Codespan::Reporting::Files.column_index(source, 2...13, 12).should eq(2)
    Codespan::Reporting::Files.column_index(source, 2...13, 13).should eq(3)
    Codespan::Reporting::Files.column_index(source, 2...13, 14).should eq(3)
  end

  it "finds line starts" do
    source = "foo\nbar\r\n\nbaz"
    Codespan::Reporting::Files.line_starts(source).should eq([0, 4, 9, 10])
  end
end

describe Codespan::Reporting::Files::SimpleFile do
  it "returns line ranges that slice source lines" do
    file = Codespan::Reporting::Files::SimpleFile.new("test", "foo\nbar\r\n\nbaz")

    line_sources = (0..3).map do |line|
      range = file.line_range(line)
      start_char = file.source.byte_index_to_char_index(range.begin)
      end_char = file.source.byte_index_to_char_index(range.end)
      raise "unexpected non-boundary start index" if start_char.nil?
      raise "unexpected non-boundary end index" if end_char.nil?
      file.source[start_char, end_char - start_char]
    end

    line_sources.should eq(["foo\n", "bar\r\n", "\n", "baz"])
  end
end

describe Codespan::Reporting::Files::SimpleFiles do
  it "stores and retrieves multiple files" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    id1 = files.add("a", "hello")
    id2 = files.add("b", "world")

    files.name(id1).should eq("a")
    files.name(id2).should eq("b")
    files.source(id1).should eq("hello")
    files.source(id2).should eq("world")
  end
end
