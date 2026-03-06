module Codespan
  module Reporting
    module Term
      enum DisplayStyle
        Rich
        Medium
        Short
      end

      struct Chars
        getter snippet_start : String
        getter source_border_left : Char
        getter source_border_left_break : Char
        getter note_bullet : Char
        getter single_primary_caret : Char
        getter single_secondary_caret : Char
        getter multi_primary_caret_start : Char
        getter multi_primary_caret_end : Char
        getter multi_secondary_caret_start : Char
        getter multi_secondary_caret_end : Char
        getter multi_top_left : Char
        getter multi_top : Char
        getter multi_bottom_left : Char
        getter multi_bottom : Char
        getter multi_left : Char
        getter pointer_left : Char

        def initialize(
          @snippet_start : String,
          @source_border_left : Char,
          @source_border_left_break : Char,
          @note_bullet : Char,
          @single_primary_caret : Char,
          @single_secondary_caret : Char,
          @multi_primary_caret_start : Char,
          @multi_primary_caret_end : Char,
          @multi_secondary_caret_start : Char,
          @multi_secondary_caret_end : Char,
          @multi_top_left : Char,
          @multi_top : Char,
          @multi_bottom_left : Char,
          @multi_bottom : Char,
          @multi_left : Char,
          @pointer_left : Char,
        )
        end

        def self.default : Chars
          box_drawing
        end

        def self.box_drawing : Chars
          Chars.new(
            snippet_start: "┌─",
            source_border_left: '│',
            source_border_left_break: '·',
            note_bullet: '=',
            single_primary_caret: '^',
            single_secondary_caret: '-',
            multi_primary_caret_start: '^',
            multi_primary_caret_end: '^',
            multi_secondary_caret_start: '\'',
            multi_secondary_caret_end: '\'',
            multi_top_left: '╭',
            multi_top: '─',
            multi_bottom_left: '╰',
            multi_bottom: '─',
            multi_left: '│',
            pointer_left: '│'
          )
        end

        def self.ascii : Chars
          Chars.new(
            snippet_start: "-->",
            source_border_left: '|',
            source_border_left_break: '.',
            note_bullet: '=',
            single_primary_caret: '^',
            single_secondary_caret: '-',
            multi_primary_caret_start: '^',
            multi_primary_caret_end: '^',
            multi_secondary_caret_start: '\'',
            multi_secondary_caret_end: '\'',
            multi_top_left: '/',
            multi_top: '-',
            multi_bottom_left: '\\',
            multi_bottom: '-',
            multi_left: '|',
            pointer_left: '|'
          )
        end
      end

      struct Config
        getter display_style : DisplayStyle
        getter tab_width : Int32
        getter chars : Chars
        getter start_context_lines : Int32
        getter end_context_lines : Int32
        getter before_label_lines : Int32
        getter after_label_lines : Int32

        def initialize(
          @display_style : DisplayStyle = DisplayStyle::Rich,
          @tab_width : Int32 = 4,
          @chars : Chars = Chars.default,
          @start_context_lines : Int32 = 3,
          @end_context_lines : Int32 = 1,
          @before_label_lines : Int32 = 0,
          @after_label_lines : Int32 = 0,
        )
        end

        def self.default : Config
          new
        end
      end
    end
  end
end
