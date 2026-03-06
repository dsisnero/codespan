module Codespan
  struct Span
    getter start : ByteIndex
    getter end : ByteIndex

    def initialize(start : ByteIndex | Int, ending : ByteIndex | Int)
      @start = start.is_a?(ByteIndex) ? start : ByteIndex.from(start)
      @end = ending.is_a?(ByteIndex) ? ending : ByteIndex.from(ending)
      raise ArgumentError.new("span end must be >= span start") if @end < @start
    end

    def self.initial : Span
      new(0, 0)
    end

    def self.from_str(s : String) : Span
      new(0, s.bytesize)
    end

    def merge(other : Span) : Span
      start_index = @start < other.start ? @start : other.start
      end_index = @end > other.end ? @end : other.end
      Span.new(start_index, end_index)
    end

    def disjoint(other : Span) : Bool
      first, last = if @end < other.end
                      {self, other}
                    else
                      {other, self}
                    end
      first.end <= last.start
    end

    def to_range : Range(Int32, Int32)
      @start.to_usize...@end.to_usize
    end

    def to_s(io : IO) : Nil
      io << "[" << @start << ", " << @end << ")"
    end
  end
end
