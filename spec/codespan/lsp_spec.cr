require "../spec_helper"

UNICODE = "åä t𐐀b"

describe Codespan::Lsp do
  describe ".byte_index_to_position" do
    it "converts byte index to LSP position" do
      files = Codespan::Reporting::Files::SimpleFiles.new
      file_id = files.add("unicode", UNICODE)
      file_id2 = files.add("unicode newline", "\n" + UNICODE)

      result = Codespan::Lsp.byte_index_to_position(files, file_id, 5)
      result.line.should eq(0)
      result.character.should eq(3)

      result = Codespan::Lsp.byte_index_to_position(files, file_id, 10)
      result.line.should eq(0)
      result.character.should eq(6)

      result = Codespan::Lsp.byte_index_to_position(files, file_id2, 11)
      result.line.should eq(1)
      result.character.should eq(6)
    end
  end

  describe ".position_to_byte_index" do
    it "converts LSP position to byte index" do
      files = Codespan::Reporting::Files::SimpleFiles.new
      file_id = files.add("unicode", UNICODE)

      result = Codespan::Lsp.position_to_byte_index(
        files,
        file_id,
        Codespan::Lsp::LspPosition.new(0_u32, 3_u32),
      )
      result.should eq(5)

      result = Codespan::Lsp.position_to_byte_index(
        files,
        file_id,
        Codespan::Lsp::LspPosition.new(0_u32, 6_u32),
      )
      result.should eq(10)
    end

    it "handles multi-line source correctly" do
      text = "\nlet test = 2\nlet test1 = \"\"\ntest\n"
      files = Codespan::Reporting::Files::SimpleFiles.new
      file_id = files.add("test", text)

      pos = Codespan::Lsp.position_to_byte_index(
        files,
        file_id,
        Codespan::Lsp::LspPosition.new(3_u32, 2_u32),
      )
      loc = files.location(file_id, pos)
      loc.line_number.should eq(4)
      loc.column_number.should eq(3)
    end
  end

  describe ".byte_span_to_range" do
    it "converts byte span to LSP range" do
      files = Codespan::Reporting::Files::SimpleFiles.new
      file_id = files.add("unicode", UNICODE)

      range = Codespan::Lsp.byte_span_to_range(files, file_id, 5...10)
      range.start.line.should eq(0)
      range.start.character.should eq(3)
      range.end.line.should eq(0)
      range.end.character.should eq(6)
    end
  end

  describe ".range_to_byte_span" do
    it "converts LSP range back to byte span" do
      files = Codespan::Reporting::Files::SimpleFiles.new
      file_id = files.add("unicode", UNICODE)

      lsp_range = Codespan::Lsp::LspRange.new(
        Codespan::Lsp::LspPosition.new(0_u32, 3_u32),
        Codespan::Lsp::LspPosition.new(0_u32, 6_u32),
      )
      byte_span = Codespan::Lsp.range_to_byte_span(files, file_id, lsp_range)
      byte_span.should eq(5...10)
    end
  end
end
