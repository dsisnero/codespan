require "../spec_helper"

describe Codespan::Files do
  it "computes line spans for mixed newline styles" do
    files = Codespan::Files.new
    file_id = files.add("test", "foo\nbar\r\n\nbaz")

    spans = (0..3).map { |line| files.line_span(file_id, line) }

    spans.should eq([
      Codespan::Span.new(0, 4),
      Codespan::Span.new(4, 9),
      Codespan::Span.new(9, 10),
      Codespan::Span.new(10, 13),
    ])

    expect_raises(Codespan::LineTooLargeError) { files.line_span(file_id, 4) }
  end

  it "computes line indices at byte positions" do
    files = Codespan::Files.new
    file_id = files.add("test", "foo\nbar\r\n\nbaz")

    files.line_index(file_id, 0).should eq(Codespan::LineIndex.from(0))
    files.line_index(file_id, 7).should eq(Codespan::LineIndex.from(1))
    files.line_index(file_id, 8).should eq(Codespan::LineIndex.from(1))
    files.line_index(file_id, 9).should eq(Codespan::LineIndex.from(2))
    files.line_index(file_id, 100).should eq(Codespan::LineIndex.from(3))
  end

  it "computes locations and reports out-of-range indexes" do
    files = Codespan::Files.new
    file_id = files.add("test", "foo\nbar\r\n\nbaz")

    files.location(file_id, 0).should eq(Codespan::Location.new(0, 0))
    files.location(file_id, 7).should eq(Codespan::Location.new(1, 3))
    files.location(file_id, 8).should eq(Codespan::Location.new(1, 4))
    files.location(file_id, 9).should eq(Codespan::Location.new(2, 0))

    expect_raises(Codespan::IndexTooLargeError) { files.location(file_id, 100) }
  end

  it "returns source slices for spans" do
    files = Codespan::Files.new
    file_id = files.add("test", "hello world!")

    files.source_slice(file_id, Codespan::Span.new(0, 5)).should eq("hello")
    expect_raises(Codespan::IndexTooLargeError) { files.source_slice(file_id, Codespan::Span.new(0, 100)) }
  end
end
