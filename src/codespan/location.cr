module Codespan
  struct Location
    getter line : LineIndex
    getter column : ColumnIndex

    def initialize(@line : LineIndex, @column : ColumnIndex)
    end

    def self.new(line : LineIndex | Int, column : ColumnIndex | Int)
      line_index = line.is_a?(LineIndex) ? line : LineIndex.from(line)
      column_index = column.is_a?(ColumnIndex) ? column : ColumnIndex.from(column)
      new(line_index, column_index)
    end
  end
end
