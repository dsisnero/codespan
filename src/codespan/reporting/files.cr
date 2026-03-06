module Codespan
  module Reporting
    module Files
      abstract class Error < Exception
      end

      class FileMissingError < Error
        def initialize
          super("file missing")
        end
      end

      class IndexTooLargeError < Error
        getter given : Int32
        getter max : Int32

        def initialize(@given : Int32, @max : Int32)
          super("invalid index #{@given}, maximum index is #{@max}")
        end
      end

      class LineTooLargeError < Error
        getter given : Int32
        getter max : Int32

        def initialize(@given : Int32, @max : Int32)
          super("invalid line #{@given}, maximum line is #{@max}")
        end
      end

      class ColumnTooLargeError < Error
        getter given : Int32
        getter max : Int32

        def initialize(@given : Int32, @max : Int32)
          super("invalid column #{@given}, maximum column #{@max}")
        end
      end

      class InvalidCharBoundaryError < Error
        getter given : Int32

        def initialize(@given : Int32)
          super("index is not a code point boundary")
        end
      end

      class FormatError < Error
        def initialize
          super("formatting error")
        end
      end

      struct Location
        getter line_number : Int32
        getter column_number : Int32

        def initialize(@line_number : Int32, @column_number : Int32)
        end
      end

      def self.column_index(source : String, line_range : Range(Int32, Int32), byte_index : Int) : Int32
        line_start = line_range.begin
        line_end = line_range.end
        end_limit = line_range.excludes_end? ? line_end : line_end + 1

        end_index = {byte_index.to_i, end_limit, source.bytesize}.min
        return 0 if end_index <= line_start

        count = 0
        (line_start...end_index).each do |i|
          count += 1 if source.byte_index_to_char_index(i + 1)
        end
        count
      end

      def self.line_starts(source : String) : Array(Int32)
        starts = [0]
        source.to_slice.each_with_index do |byte, index|
          starts << (index + 1) if byte == '\n'.ord
        end
        starts
      end

      class SimpleFile
        getter name : String
        getter source : String

        def initialize(@name : String, @source : String)
          @line_starts = Files.line_starts(@source)
        end

        def line_index(byte_index : Int) : Int32
          exact = @line_starts.index(byte_index)
          return exact if exact

          next_line = @line_starts.bsearch_index { |start| start > byte_index }
          return @line_starts.size - 1 unless next_line

          next_line - 1
        end

        def line_range(line_index : Int) : Range(Int32, Int32)
          line_start = line_start(line_index)
          next_line_start = line_start(line_index + 1)
          line_start...next_line_start
        end

        private def line_start(line_index : Int) : Int32
          if line_index < @line_starts.size
            @line_starts[line_index]
          elsif line_index == @line_starts.size
            @source.bytesize
          else
            raise LineTooLargeError.new(line_index, @line_starts.size - 1)
          end
        end
      end

      class SimpleFiles
        def initialize
          @files = [] of SimpleFile
        end

        def add(name : String, source : String) : Int32
          file_id = @files.size
          @files << SimpleFile.new(name, source)
          file_id
        end

        def get(file_id : Int) : SimpleFile
          @files[file_id]? || raise FileMissingError.new
        end

        def name(file_id : Int) : String
          get(file_id).name
        end

        def source(file_id : Int) : String
          get(file_id).source
        end

        def line_index(file_id : Int, byte_index : Int) : Int32
          get(file_id).line_index(byte_index)
        end

        def line_range(file_id : Int, line_index : Int) : Range(Int32, Int32)
          get(file_id).line_range(line_index)
        end

        def location(file_id : Int, byte_index : Int) : Location
          line = line_index(file_id, byte_index)
          range = line_range(file_id, line)

          Location.new(line + 1, Files.column_index(source(file_id), range, byte_index) + 1)
        end
      end
    end
  end
end
