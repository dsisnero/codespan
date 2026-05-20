require "uniwidth"

module Codespan
  module Reporting
    module Term
      struct Locus
        getter name : String
        getter location : Codespan::Reporting::Files::Location

        def initialize(@name : String, @location : Codespan::Reporting::Files::Location)
        end
      end

      alias SingleLabel = Tuple(Codespan::Reporting::LabelStyle, Range(Int32, Int32), String)

      enum MultiLabelType
        Top
        Left
        Bottom
      end

      struct MultiLabel
        getter type : MultiLabelType
        getter position : Int32
        getter message : String

        def initialize(@type : MultiLabelType, @position : Int32 = 0, @message : String = "")
        end
      end

      class Renderer
        def initialize(@writer : IO, @config : Config)
        end

        private def char_display_width(char : Char, col : Int32) : Int32
          if char == '\t'
            tw = @config.tab_width
            tw == 0 ? 0 : tw - (col % tw)
          else
            UnicodeCharWidth.width(char)
          end
        end

        def render_header(
          locus : Locus?,
          severity : Codespan::Reporting::Severity,
          code : String?,
          message : String,
        ) : Nil
          if locus
            @writer << locus.name
            @writer << ":"
            @writer << locus.location.line_number
            @writer << ":"
            @writer << locus.location.column_number
            @writer << ": "
          end

          @writer << severity.to_s.downcase
          if code && !code.empty?
            @writer << "[" << code << "]"
          end

          @writer << ": "
          @writer << message
          @writer << '\n'
        end

        def render_snippet_start(outer_padding : Int32, locus : Locus) : Nil
          outer_padding.times { @writer << ' ' }
          @writer << ' '
          @writer << @config.chars.snippet_start
          @writer << " "
          @writer << locus.name
          @writer << ":"
          @writer << locus.location.line_number
          @writer << ":"
          @writer << locus.location.column_number
          @writer << '\n'
        end

        def render_snippet_empty(
          outer_padding : Int32,
          severity : Codespan::Reporting::Severity,
          num_multi_labels : Int32,
          multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)),
        ) : Nil
          outer_padding.times { @writer << ' ' }
          @writer << ' '
          @writer << @config.chars.source_border_left

          write_inner_gutter(num_multi_labels, multi_labels)

          @writer << '\n'
        end

        def render_snippet_break(
          outer_padding : Int32,
          severity : Codespan::Reporting::Severity,
          num_multi_labels : Int32,
          multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)),
        ) : Nil
          outer_padding.times { @writer << ' ' }
          @writer << ' '
          @writer << @config.chars.source_border_left_break

          write_inner_gutter(num_multi_labels, multi_labels)

          @writer << '\n'
        end

        def render_label_line(label : Codespan::Reporting::Label) : Nil
          @writer << "  - "
          @writer << label.style.to_s.downcase
          @writer << " @"
          @writer << label.file_id
          @writer << ":"
          @writer << label.range.begin
          @writer << "..."
          @writer << label.range.end
          unless label.message.empty?
            @writer << " " << label.message
          end
          @writer << '\n'
        end

        private def write_inner_gutter(
          num_multi_labels : Int32,
          multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)),
          source_line : String? = nil,
        ) : Nil
          whitespace_len = source_line ? (source_line.bytesize - source_line.lstrip.bytesize) : 0
          label_map = Hash(Int32, Tuple(Codespan::Reporting::LabelStyle, MultiLabel)).new
          multi_labels.each do |label_index, label_style, label|
            label_map[label_index] = {label_style, label}
          end

          (0...num_multi_labels).each do |label_column|
            entry = label_map[label_column]?
            if entry
              _, label = entry
              case label.type
              when MultiLabelType::Top
                if source_line && label.position <= whitespace_len
                  @writer << ' '
                  @writer << @config.chars.multi_top_left
                else
                  @writer << "  "
                end
              when MultiLabelType::Left, MultiLabelType::Bottom
                @writer << ' '
                @writer << @config.chars.multi_left
              end
            else
              @writer << "  "
            end
          end
        end

        def render_snippet_source(
          outer_padding : Int32,
          line_number : Int32,
          source : String,
          severity : Codespan::Reporting::Severity,
          single_labels : Array(Tuple(Codespan::Reporting::LabelStyle, Range(Int32, Int32), String)),
          num_multi_labels : Int32,
          multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)),
        ) : Nil
          # Trim trailing newlines, linefeeds, and null chars
          source = source.rstrip("\n\r\0")

          # Write line number and border
          line_number_str = line_number.to_s
          (outer_padding - line_number_str.size).times { @writer << ' ' }
          @writer << line_number_str
          @writer << " "
          @writer << @config.chars.source_border_left

          # Write multi-label gutter (2 chars per column, matching Rust)
          write_inner_gutter(num_multi_labels, multi_labels, source)

          # Write source text
          @writer << " "

          # Write source with tab-stop aware spacing
          col = 0
          source.each_char do |char|
            w = char_display_width(char, col)
            if char == '\t'
              w.times { @writer << ' ' }
            else
              @writer << char
            end
            col += w
          end

          @writer << '\n'

          # Render single labels if any
          unless single_labels.empty?
            render_single_labels(outer_padding, source, severity, single_labels, num_multi_labels, multi_labels)
          end

          # Render multiline labels if any
          unless multi_labels.empty?
            render_multi_labels(outer_padding, source, severity, multi_labels, num_multi_labels)
          end
        end

        private def render_single_labels(
          outer_padding : Int32,
          source : String,
          severity : Codespan::Reporting::Severity,
          single_labels : Array(Tuple(Codespan::Reporting::LabelStyle, Range(Int32, Int32), String)),
          num_multi_labels : Int32,
          multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)),
        ) : Nil
          # Find max label positions (character indices)
          max_label_start = single_labels.max_of? { |(_, range, _)| range.begin } || 0
          max_label_end = single_labels.max_of? { |(_, range, _)| range.end } || 0

          # Find trailing label (message at the end of the last label)
          trailing_label = nil
          single_labels.reverse_each do |label|
            _, range, message = label
            if range.end == max_label_end && !message.empty?
              trailing_label = label
              break
            end
          end

          # Check for overlaps with trailing label
          if trailing_label
            trailing_range = trailing_label[1]
            overlaps = single_labels.any? do |label|
              next false if label == trailing_label
              other_range = label[1]
              other_range.begin < trailing_range.end && trailing_range.begin < other_range.end
            end
            trailing_label = nil if overlaps
          end

          # Write caret line using display-width-aware iteration
          outer_padding.times { @writer << ' ' }
          @writer << ' '
          @writer << @config.chars.source_border_left

          write_inner_gutter(num_multi_labels, multi_labels)

          @writer << " "

          # Render carets with display width, using character-index ranges
          # Chain a placeholder to handle labels at end-of-line (matches Rust \0)
          display_col = 0
          char_index = 0
          chars = source.each_char.to_a
          chars << '\0' # placeholder for end-of-line caret
          chars.each do |char|
            w = char == '\0' ? 1 : char_display_width(char, display_col)
            # Check if current character index overlaps with any label
            label_style = nil
            single_labels.each do |style, range, _|
              if char_index >= range.begin && char_index < range.end
                ls = style
                label_style = ls if label_style.nil? || (ls == Codespan::Reporting::LabelStyle::Primary)
              end
            end
            caret_char = case label_style
                         when Codespan::Reporting::LabelStyle::Primary
                           @config.chars.single_primary_caret
                         when Codespan::Reporting::LabelStyle::Secondary
                           @config.chars.single_secondary_caret
                         else
                           char_index < max_label_end ? ' ' : nil
                         end
            if caret_char
              w.times { @writer << caret_char }
            end
            display_col += w
            char_index += 1
          end

          if trailing_label
            @writer << " "
            @writer << trailing_label[2]
          end

          @writer << '\n'

          # Write hanging labels
          hanging = single_labels.select do |label|
            !label[2].empty? && label != trailing_label
          end

          return if hanging.empty?

          # Pointer positions: character indices where hanging labels start
          pointer_positions = hanging.map(&.[1].begin).sort!

          # Write pointer line (display-width-aware)
          outer_padding.times { @writer << ' ' }
          @writer << ' '
          @writer << @config.chars.source_border_left

          write_inner_gutter(num_multi_labels, multi_labels)

          @writer << " "
          display_col = 0
          char_index = 0
          ptr_chars = source.each_char.to_a
          ptr_chars << '\0'
          ptr_chars.each do |char|
            break if char_index > max_label_start
            w = char == '\0' ? 1 : char_display_width(char, display_col)
            if pointer_positions.includes?(char_index)
              @writer << @config.chars.pointer_left
              (w - 1).times { @writer << ' ' }
            else
              w.times { @writer << ' ' }
            end
            display_col += w
            char_index += 1
          end
          @writer << '\n'

          # Write hanging messages (display-width-aware)
          hanging.sort_by(&.[1].begin).reverse_each do |(_, range, message)|
            outer_padding.times { @writer << ' ' }
            @writer << ' '
            @writer << @config.chars.source_border_left

            write_inner_gutter(num_multi_labels, multi_labels)

            @writer << " "

            display_col = 0
            char_index = 0
            hang_chars = source.each_char.to_a
            hang_chars << '\0'
            hang_chars.each do |char|
              break if char_index >= range.begin
              w = char == '\0' ? 1 : char_display_width(char, display_col)
              if pointer_positions.includes?(char_index)
                @writer << @config.chars.pointer_left
                (w - 1).times { @writer << ' ' }
              else
                w.times { @writer << ' ' }
              end
              display_col += w
              char_index += 1
            end

            @writer << message
            @writer << '\n'
          end
        end

        def render_snippet_note(outer_padding : Int32, note : String) : Nil
          note.each_line.with_index do |line, note_line_index|
            outer_padding.times { @writer << ' ' }
            @writer << ' '
            if note_line_index == 0
              @writer << @config.chars.note_bullet
            else
              @writer << ' '
            end
            @writer << ' '
            @writer << line
            @writer << '\n'
          end
        end

        private def render_multi_labels(
          outer_padding : Int32,
          source : String,
          severity : Codespan::Reporting::Severity,
          multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)),
          num_multi_labels : Int32,
        ) : Nil
          whitespace_len = source.bytesize - source.lstrip.bytesize

          # Build label map indexed by column
          label_map = Hash(Int32, Tuple(Codespan::Reporting::LabelStyle, MultiLabel)).new
          multi_labels.each do |label_index, label_style, label|
            label_map[label_index] = {label_style, label}
          end

          # Render top/bottom carets for each multi-label index
          multi_labels.each do |label_index, label_style, label|
            if label.type == MultiLabelType::Left
              next
            end
            if label.type == MultiLabelType::Top && label.position <= whitespace_len
              next
            end

            label_range = label.position
            bottom_message = label.type == MultiLabelType::Bottom ? label.message : nil

            # Write outer gutter and border
            outer_padding.times { @writer << ' ' }
            @writer << ' '
            @writer << @config.chars.source_border_left

            # Write inner gutter with underline continuations
            underline_label_style = nil
            (0...num_multi_labels).each do |label_column|
              entry = label_map[label_column]?
              if entry
                _, col_label = entry
                if col_label.type == MultiLabelType::Left
                  ch = underline_label_style ? @config.chars.multi_top : ' '
                  @writer << ch
                  @writer << @config.chars.multi_left
                elsif col_label.type == MultiLabelType::Top
                  if label_index > label_column
                    ch = underline_label_style ? @config.chars.multi_top : ' '
                    @writer << ch
                    @writer << @config.chars.multi_left
                  elsif label_index == label_column
                    underline_label_style = label_style
                    @writer << ' '
                    @writer << @config.chars.multi_top_left
                  else
                    if underline_label_style
                      @writer << @config.chars.multi_bottom
                      @writer << @config.chars.multi_bottom
                    else
                      @writer << "  "
                    end
                  end
                elsif col_label.type == MultiLabelType::Bottom
                  if label_index < label_column
                    ch = underline_label_style ? @config.chars.multi_top : ' '
                    @writer << ch
                    @writer << @config.chars.multi_left
                  elsif label_index == label_column
                    underline_label_style = label_style
                    @writer << ' '
                    @writer << @config.chars.multi_bottom_left
                  else
                    if underline_label_style
                      @writer << @config.chars.multi_top
                      @writer << @config.chars.multi_top
                    else
                      @writer << "  "
                    end
                  end
                end
              else
                if underline_label_style
                  ch = bottom_message.nil? ? @config.chars.multi_top : @config.chars.multi_bottom
                  @writer << ch
                  @writer << ch
                else
                  @writer << "  "
                end
              end
            end

            # Render horizontal line and caret using byte-based position
            if bottom_message.nil?
              line_char = @config.chars.multi_top
              caret_char = label_style == Codespan::Reporting::LabelStyle::Primary ? @config.chars.multi_primary_caret_start : @config.chars.multi_secondary_caret_start
              reader = Char::Reader.new(source)
              col = 0
              reader.each do |char|
                break if reader.pos >= label_range + 1
                w = char_display_width(char, col)
                w.times { @writer << line_char }
                col += w
              end
              @writer << caret_char
              @writer << '\n'
            else
              line_char = @config.chars.multi_bottom
              caret_char = label_style == Codespan::Reporting::LabelStyle::Primary ? @config.chars.multi_primary_caret_start : @config.chars.multi_secondary_caret_start
              reader = Char::Reader.new(source)
              col = 0
              reader.each do |char|
                break if reader.pos >= label_range
                w = char_display_width(char, col)
                w.times { @writer << line_char }
                col += w
              end
              @writer << caret_char
              unless bottom_message.empty?
                @writer << " " << bottom_message
              end
              @writer << '\n'
            end
          end
        end

        def render_empty : Nil
          @writer << '\n'
        end
      end
    end
  end
end
