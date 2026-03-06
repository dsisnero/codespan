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
          @writer << @config.chars.source_border_left

          # Create a map of label column to label
          label_map = Hash(Int32, MultiLabel).new
          multi_labels.each do |label_index, _, label|
            label_map[label_index] = label
          end

          (0...num_multi_labels).each do |label_column|
            if label = label_map[label_column]?
              case label.type
              when MultiLabelType::Top
                @writer << @config.chars.multi_top_left
              when MultiLabelType::Left, MultiLabelType::Bottom
                @writer << @config.chars.multi_left
              end
            else
              @writer << ' '
            end
          end

          @writer << '\n'
        end

        def render_snippet_break(
          outer_padding : Int32,
          severity : Codespan::Reporting::Severity,
          num_multi_labels : Int32,
          multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)),
        ) : Nil
          outer_padding.times { @writer << ' ' }
          @writer << @config.chars.source_border_left_break

          # Create a map of label column to label
          label_map = Hash(Int32, MultiLabel).new
          multi_labels.each do |label_index, _, label|
            label_map[label_index] = label
          end

          (0...num_multi_labels).each do |label_column|
            if label = label_map[label_column]?
              case label.type
              when MultiLabelType::Top
                @writer << @config.chars.multi_top_left
              when MultiLabelType::Left, MultiLabelType::Bottom
                @writer << @config.chars.multi_left
              end
            else
              @writer << ' '
            end
          end

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

          # Write multi-label gutter
          # Create a map of label column to label
          label_map = Hash(Int32, Tuple(Codespan::Reporting::LabelStyle, MultiLabel)).new
          multi_labels.each do |label_index, label_style, label|
            label_map[label_index] = {label_style, label}
          end

          (0...num_multi_labels).each do |label_column|
            if entry = label_map[label_column]?
              _, label = entry
              case label.type
              when MultiLabelType::Top
                if label.position <= source.size - source.lstrip.size
                  @writer << @config.chars.multi_top_left
                else
                  @writer << ' '
                end
              when MultiLabelType::Left
                @writer << @config.chars.multi_left
              when MultiLabelType::Bottom
                @writer << @config.chars.multi_left
              end
            else
              @writer << ' '
            end
          end

          # Write source text
          @writer << " "

          # Track if we're in a primary label for coloring (simplified for now)
          source.each_char do |char|
            @writer << (char == '\t' ? " " : char)
          end

          @writer << '\n'

          # Render single labels if any
          unless single_labels.empty?
            render_single_labels(outer_padding, source, severity, single_labels, num_multi_labels, multi_labels)
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
          # Find max label end for caret line
          max_label_end = single_labels.max_of? { |(_, range, _)| range.end } || 0

          # Build caret line
          caret_line = Array(Char).new(max_label_end, ' ')

          single_labels.each do |style, range, _|
            caret = style == Codespan::Reporting::LabelStyle::Primary ? @config.chars.single_primary_caret : @config.chars.single_secondary_caret
            (range.begin...range.end).each do |column|
              caret_line[column] = caret if column < caret_line.size
            end
          end

          # Find trailing label
          trailing_label = nil
          single_labels.reverse_each do |label|
            _, range, message = label
            if range.end == max_label_end && !message.empty?
              trailing_label = label
              break
            end
          end

          # Check for overlaps
          if trailing_label
            trailing_range = trailing_label[1]
            overlaps = single_labels.any? do |label|
              next false if label == trailing_label
              other_range = label[1]
              other_range.begin < trailing_range.end && trailing_range.begin < other_range.end
            end
            trailing_label = nil if overlaps
          end

          # Write caret line
          outer_padding.times { @writer << ' ' }
          @writer << @config.chars.source_border_left

          # Multi-label gutter
          # Create a map of label column to label
          label_map = Hash(Int32, MultiLabel).new
          multi_labels.each do |label_index, _, label|
            label_map[label_index] = label
          end

          (0...num_multi_labels).each do |label_column|
            if label = label_map[label_column]?
              case label.type
              when MultiLabelType::Top
                @writer << @config.chars.multi_top_left
              when MultiLabelType::Left, MultiLabelType::Bottom
                @writer << @config.chars.multi_left
              end
            else
              @writer << ' '
            end
          end

          @writer << " "
          @writer << caret_line.join

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

          pointer_positions = hanging.map(&.[1].begin).sort!

          # Write pointer line
          outer_padding.times { @writer << ' ' }
          @writer << @config.chars.source_border_left

          # Reuse label map
          (0...num_multi_labels).each do |label_column|
            if label = label_map[label_column]?
              case label.type
              when MultiLabelType::Top
                @writer << @config.chars.multi_top_left
              when MultiLabelType::Left, MultiLabelType::Bottom
                @writer << @config.chars.multi_left
              end
            else
              @writer << ' '
            end
          end

          @writer << " "
          (0...max_label_end).each do |column|
            @writer << (pointer_positions.includes?(column) ? @config.chars.pointer_left : ' ')
          end
          @writer << '\n'

          # Write hanging messages
          hanging.sort_by(&.[1].begin).reverse_each do |(_, range, message)|
            outer_padding.times { @writer << ' ' }
            @writer << @config.chars.source_border_left

            # Reuse label map
            (0...num_multi_labels).each do |label_column|
              if label = label_map[label_column]?
                case label.type
                when MultiLabelType::Top
                  @writer << @config.chars.multi_top_left
                when MultiLabelType::Left, MultiLabelType::Bottom
                  @writer << @config.chars.multi_left
                end
              else
                @writer << ' '
              end
            end

            @writer << " "
            range.begin.times { @writer << ' ' }
            @writer << message
            @writer << '\n'
          end
        end

        def render_snippet_note(outer_padding : Int32, note : String) : Nil
          outer_padding.times { @writer << ' ' }
          @writer << " = " << note << '\n'
        end

        def render_empty : Nil
          @writer << '\n'
        end
      end
    end
  end
end
