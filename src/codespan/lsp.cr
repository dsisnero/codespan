require "./reporting/files"

module Codespan
  module Lsp
    struct LspPosition
      getter line : UInt32
      getter character : UInt32

      def initialize(@line : UInt32, @character : UInt32)
      end
    end

    struct LspRange
      getter start : LspPosition
      getter end : LspPosition

      def initialize(@start : LspPosition, @end : LspPosition)
      end
    end

    private def self.byte_slice(source : String, range : Range(Int32, Int32)) : String
      String.new(source.to_slice[range.begin, range.end - range.begin])
    end

    private def self.location_to_position(line_str : String, line : Int32, column : Int32, byte_index : Int32) : LspPosition
      if column > line_str.bytesize
        raise Reporting::Files::ColumnTooLargeError.new(column, line_str.bytesize)
      end

      unless line_str.byte_index_to_char_index(column)
        raise Reporting::Files::InvalidCharBoundaryError.new(byte_index)
      end

      utf16_count = 0_u32
      byte_pos = 0
      line_str.each_char do |char|
        break if byte_pos >= column
        utf16_count += char.ord > 0xFFFF ? 2_u32 : 1_u32
        byte_pos += char.bytesize
      end

      LspPosition.new(line.to_u32, utf16_count)
    end

    def self.byte_index_to_position(files : Reporting::Files::SimpleFiles, file_id : Int32, byte_index : Int32) : LspPosition
      source = files.source(file_id)
      line_index = files.line_index(file_id, byte_index)
      line_range = files.line_range(file_id, line_index)

      if line_range.begin >= source.bytesize || line_range.end > source.bytesize
        max = source.bytesize - 1
        given = line_range.begin >= source.bytesize ? line_range.begin : line_range.end
        raise Reporting::Files::IndexTooLargeError.new(given > 0 ? given : 0, max)
      end

      column = byte_index - line_range.begin
      line_str = byte_slice(source, line_range)

      location_to_position(line_str, line_index, column, byte_index)
    end

    def self.byte_span_to_range(files : Reporting::Files::SimpleFiles, file_id : Int32, span : Range(Int32, Int32)) : LspRange
      LspRange.new(
        byte_index_to_position(files, file_id, span.begin),
        byte_index_to_position(files, file_id, span.end),
      )
    end

    private def self.character_to_line_offset(line : String, character : UInt32) : Int32
      byte_offset = 0
      utf16_offset = 0_u32

      line.each_char do |char|
        return byte_offset if utf16_offset == character

        ch_utf16 = char.ord > 0xFFFF ? 2_u32 : 1_u32
        utf16_offset += ch_utf16
        byte_offset += char.bytesize
      end

      if utf16_offset == character
        return line.bytesize
      end

      raise Reporting::Files::ColumnTooLargeError.new(utf16_offset.to_i, line.bytesize)
    end

    def self.position_to_byte_index(files : Reporting::Files::SimpleFiles, file_id : Int32, position : LspPosition) : Int32
      source = files.source(file_id)
      line_range = files.line_range(file_id, position.line.to_i)
      line_str = byte_slice(source, line_range)

      byte_offset = character_to_line_offset(line_str, position.character)

      line_range.begin + byte_offset
    end

    def self.range_to_byte_span(files : Reporting::Files::SimpleFiles, file_id : Int32, range : LspRange) : Range(Int32, Int32)
      span_begin = position_to_byte_index(files, file_id, range.start)
      span_end = position_to_byte_index(files, file_id, range.end)
      span_begin...span_end
    end
  end
end
