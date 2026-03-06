module Codespan
  class FileError < Exception
  end

  class FileMissingError < FileError
    def initialize
      super("file missing")
    end
  end

  class IndexTooLargeError < FileError
    getter given : Int32
    getter max : Int32

    def initialize(@given : Int32, @max : Int32)
      super("invalid index #{@given}, maximum index is #{@max}")
    end
  end

  class LineTooLargeError < FileError
    getter given : Int32
    getter max : Int32

    def initialize(@given : Int32, @max : Int32)
      super("invalid line #{@given}, maximum line is #{@max}")
    end
  end

  class InvalidCharBoundaryError < FileError
    getter given : Int32

    def initialize(@given : Int32)
      super("index is not a code point boundary")
    end
  end

  struct FileId
    OFFSET = 1_u32

    getter value : UInt32

    def initialize(@value : UInt32)
      raise ArgumentError.new("FileId cannot be zero") if @value.zero?
    end

    def self.from_index(index : Int) : FileId
      new(index.to_u32 &+ OFFSET)
    end

    def to_index : Int32
      (@value - OFFSET).to_i
    end
  end

  class Files
    def initialize
      @files = [] of File
    end

    def add(name : String, source : String) : FileId
      file_id = FileId.from_index(@files.size)
      @files << File.new(name, source)
      file_id
    end

    def update(file_id : FileId, source : String) : Nil
      get_mut(file_id).update(source)
    end

    def name(file_id : FileId) : String
      get(file_id).name
    end

    def line_span(file_id : FileId, line_index : LineIndex | Int) : Span
      get(file_id).line_span(cast_line_index(line_index))
    end

    def line_index(file_id : FileId, byte_index : ByteIndex | Int) : LineIndex
      get(file_id).line_index(cast_byte_index(byte_index))
    end

    def location(file_id : FileId, byte_index : ByteIndex | Int) : Location
      get(file_id).location(cast_byte_index(byte_index))
    end

    def source(file_id : FileId) : String
      get(file_id).source
    end

    def source_span(file_id : FileId) : Span
      get(file_id).source_span
    end

    def source_slice(file_id : FileId, span : Span) : String
      get(file_id).source_slice(span)
    end

    private def cast_line_index(line_index : LineIndex | Int) : LineIndex
      line_index.is_a?(LineIndex) ? line_index : LineIndex.from(line_index)
    end

    private def cast_byte_index(byte_index : ByteIndex | Int) : ByteIndex
      byte_index.is_a?(ByteIndex) ? byte_index : ByteIndex.from(byte_index)
    end

    private def get(file_id : FileId) : File
      @files[file_id.to_index]? || raise FileMissingError.new
    end

    private def get_mut(file_id : FileId) : File
      @files[file_id.to_index]? || raise FileMissingError.new
    end

    private class File
      getter name : String
      getter source : String

      def initialize(@name : String, @source : String)
        @line_starts = Codespan.line_starts(@source)
      end

      def update(source : String) : Nil
        @source = source
        @line_starts = Codespan.line_starts(@source)
      end

      def line_span(line_index : LineIndex) : Span
        line_start = line_start(line_index)
        next_line_start = line_start(line_index + LineOffset.from(1))
        Span.new(line_start, next_line_start)
      end

      def line_index(byte_index : ByteIndex) : LineIndex
        value = byte_index.to_usize
        exact = @line_starts.index(value)
        return LineIndex.from(exact) if exact

        next_line = @line_starts.bsearch_index { |candidate| candidate > value }
        return LineIndex.from(@line_starts.size - 1) unless next_line

        LineIndex.from(next_line - 1)
      end

      def location(byte_index : ByteIndex) : Location
        byte = byte_index.to_usize
        max = max_index
        if byte > max
          raise IndexTooLargeError.new(byte, max)
        end

        line = line_index(byte_index)
        line_start_index = line_start(line).to_usize

        start_char_index = @source.byte_index_to_char_index(line_start_index)
        end_char_index = @source.byte_index_to_char_index(byte)

        if start_char_index.nil? || end_char_index.nil?
          raise InvalidCharBoundaryError.new(byte)
        end

        Location.new(line, ColumnIndex.from(end_char_index - start_char_index))
      end

      def source_span : Span
        Span.from_str(@source)
      end

      def source_slice(span : Span) : String
        start_byte = span.start.to_usize
        end_byte = span.end.to_usize

        max = max_index
        start_char_index = @source.byte_index_to_char_index(start_byte)
        end_char_index = @source.byte_index_to_char_index(end_byte)

        if start_char_index.nil? || end_char_index.nil?
          given = start_byte > max ? start_byte : end_byte
          raise IndexTooLargeError.new(given, max)
        end

        @source[start_char_index, end_char_index - start_char_index]
      end

      private def line_start(line_index : LineIndex) : ByteIndex
        last = last_line_index

        if line_index < last
          ByteIndex.from(@line_starts[line_index.to_usize])
        elsif line_index == last
          source_span.end
        else
          raise LineTooLargeError.new(line_index.to_usize, last.to_usize)
        end
      end

      private def last_line_index : LineIndex
        LineIndex.from(@line_starts.size)
      end

      private def max_index : Int32
        return 0 if @source.empty?

        @source.bytesize - 1
      end
    end
  end

  def self.line_starts(source : String) : Array(Int32)
    starts = [0]
    source.to_slice.each_with_index do |byte, index|
      starts << (index + 1) if byte == '\n'.ord
    end
    starts
  end
end
