module Codespan
  alias RawIndex = UInt32
  alias RawOffset = Int64

  def self.wrap_raw_index(value : Int64) : RawIndex
    (value & 0xFFFF_FFFF_i64).to_u32
  end

  struct LineIndex
    include Comparable(LineIndex)

    getter value : RawIndex

    def initialize(@value : RawIndex)
    end

    def self.from(value : Int)
      new(value.to_u32)
    end

    def number : LineNumber
      LineNumber.new(@value &+ 1_u32)
    end

    def to_usize : Int32
      @value.to_i
    end

    def +(other : LineOffset) : LineIndex
      LineIndex.new(Codespan.wrap_raw_index(@value.to_i64 + other.value))
    end

    def -(other : LineOffset) : LineIndex
      LineIndex.new(Codespan.wrap_raw_index(@value.to_i64 - other.value))
    end

    def -(other : LineIndex) : LineOffset
      LineOffset.new(@value.to_i64 - other.value.to_i64)
    end

    def <=>(other : LineIndex)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "LineIndex(" << @value << ")"
    end
  end

  struct LineNumber
    include Comparable(LineNumber)

    getter value : RawIndex

    def initialize(@value : RawIndex)
    end

    def to_usize : Int32
      @value.to_i
    end

    def <=>(other : LineNumber)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "LineNumber(" << @value << ")"
    end
  end

  struct LineOffset
    include Comparable(LineOffset)

    ZERO = new(0_i64)

    getter value : RawOffset

    def initialize(@value : RawOffset)
    end

    def self.from(value : Int)
      new(value.to_i64)
    end

    def - : LineOffset
      LineOffset.new(-@value)
    end

    def +(other : LineOffset) : LineOffset
      LineOffset.new(@value + other.value)
    end

    def -(other : LineOffset) : LineOffset
      LineOffset.new(@value - other.value)
    end

    def <=>(other : LineOffset)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "LineOffset(" << @value << ")"
    end
  end

  struct ColumnIndex
    include Comparable(ColumnIndex)

    getter value : RawIndex

    def initialize(@value : RawIndex)
    end

    def self.from(value : Int)
      new(value.to_u32)
    end

    def number : ColumnNumber
      ColumnNumber.new(@value &+ 1_u32)
    end

    def to_usize : Int32
      @value.to_i
    end

    def +(other : ColumnOffset) : ColumnIndex
      ColumnIndex.new(Codespan.wrap_raw_index(@value.to_i64 + other.value))
    end

    def -(other : ColumnOffset) : ColumnIndex
      ColumnIndex.new(Codespan.wrap_raw_index(@value.to_i64 - other.value))
    end

    def -(other : ColumnIndex) : ColumnOffset
      ColumnOffset.new(@value.to_i64 - other.value.to_i64)
    end

    def <=>(other : ColumnIndex)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "ColumnIndex(" << @value << ")"
    end
  end

  struct ColumnNumber
    include Comparable(ColumnNumber)

    getter value : RawIndex

    def initialize(@value : RawIndex)
    end

    def <=>(other : ColumnNumber)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "ColumnNumber(" << @value << ")"
    end
  end

  struct ColumnOffset
    include Comparable(ColumnOffset)

    ZERO = new(0_i64)

    getter value : RawOffset

    def initialize(@value : RawOffset)
    end

    def self.from(value : Int)
      new(value.to_i64)
    end

    def - : ColumnOffset
      ColumnOffset.new(-@value)
    end

    def +(other : ColumnOffset) : ColumnOffset
      ColumnOffset.new(@value + other.value)
    end

    def -(other : ColumnOffset) : ColumnOffset
      ColumnOffset.new(@value - other.value)
    end

    def <=>(other : ColumnOffset)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "ColumnOffset(" << @value << ")"
    end
  end

  struct ByteIndex
    include Comparable(ByteIndex)

    getter value : RawIndex

    def initialize(@value : RawIndex)
    end

    def self.from(value : Int)
      new(value.to_u32)
    end

    def to_usize : Int32
      @value.to_i
    end

    def +(other : ByteOffset) : ByteIndex
      ByteIndex.new(Codespan.wrap_raw_index(@value.to_i64 + other.value))
    end

    def -(other : ByteOffset) : ByteIndex
      ByteIndex.new(Codespan.wrap_raw_index(@value.to_i64 - other.value))
    end

    def -(other : ByteIndex) : ByteOffset
      ByteOffset.new(@value.to_i64 - other.value.to_i64)
    end

    def <=>(other : ByteIndex)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "ByteIndex(" << @value << ")"
    end
  end

  struct ByteOffset
    include Comparable(ByteOffset)

    ZERO = new(0_i64)

    getter value : RawOffset

    def initialize(@value : RawOffset = 0_i64)
    end

    def self.from(value : Int)
      new(value.to_i64)
    end

    def self.from_char_len(ch : Char) : ByteOffset
      new(ch.bytesize.to_i64)
    end

    def self.from_str_len(value : String) : ByteOffset
      new(value.bytesize.to_i64)
    end

    def to_usize : Int32
      @value.to_i
    end

    def - : ByteOffset
      ByteOffset.new(-@value)
    end

    def +(other : ByteOffset) : ByteOffset
      ByteOffset.new(@value + other.value)
    end

    def -(other : ByteOffset) : ByteOffset
      ByteOffset.new(@value - other.value)
    end

    def <=>(other : ByteOffset)
      @value <=> other.value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "ByteOffset(" << @value << ")"
    end
  end
end
