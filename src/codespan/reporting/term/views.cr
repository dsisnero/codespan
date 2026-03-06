require "set"

module Codespan
  module Reporting
    module Term
      def self.count_digits(n : Int32) : Int32
        return 1 if n == 0
        Math.log10(n).to_i + 1
      end

      class RichDiagnostic
        def initialize(@diagnostic : Codespan::Reporting::Diagnostic, @config : Config)
        end

        def render(files, renderer : Renderer) : Nil
          # Group labels by file
          labeled_files = [] of LabeledFile
          outer_padding = 0

          @diagnostic.labels.each do |label|
            start_line_index = files.line_index(label.file_id, label.range.begin)
            start_line_number = start_line_index + 1
            start_line_range = files.line_range(label.file_id, start_line_index)
            end_line_index = files.line_index(label.file_id, label.range.end)
            end_line_number = end_line_index + 1
            end_line_range = files.line_range(label.file_id, end_line_index)

            outer_padding = Math.max(outer_padding, Term.count_digits(start_line_number))
            outer_padding = Math.max(outer_padding, Term.count_digits(end_line_number))

            # Find or create labeled file
            labeled_file = labeled_files.find { |labeled_file_item| labeled_file_item.file_id == label.file_id }
            if labeled_file.nil?
              labeled_file = LabeledFile.new(
                file_id: label.file_id,
                start: label.range.begin,
                name: files.name(label.file_id),
                location: files.location(label.file_id, label.range.begin),
                max_label_style: label.style
              )
              labeled_files << labeled_file
            else
              # Update if this label has higher priority
              if labeled_file.max_label_style > label.style ||
                 (labeled_file.max_label_style == label.style && labeled_file.start > label.range.begin)
                labeled_file.start = label.range.begin
                labeled_file.location = files.location(label.file_id, label.range.begin)
                labeled_file.max_label_style = label.style
              end
            end

            # Add context lines before label
            (1..@config.before_label_lines).each do |offset|
              index = start_line_index - offset
              break if index < 0

              if range = files.line_range(label.file_id, index)
                line = labeled_file.get_or_insert_line(index, range, start_line_number - offset)
                line.must_render = true
              else
                break
              end
            end

            # Add context lines after label
            (1..@config.after_label_lines).each do |offset|
              index = end_line_index + offset
              if range = files.line_range(label.file_id, index)
                line = labeled_file.get_or_insert_line(index, range, end_line_number + offset)
                line.must_render = true
              else
                break
              end
            end

            if start_line_index == end_line_index
              # Single line label
              label_start = label.range.begin - start_line_range.begin
              label_end = Math.max(label.range.end - start_line_range.begin, label_start + 1)

              line = labeled_file.get_or_insert_line(start_line_index, start_line_range, start_line_number)

              # Insert sorted by range
              index = line.single_labels.bsearch_index do |(_, range, _)|
                cmp = range.begin <=> label_start
                cmp != 0 ? cmp : (range.end <=> label_end)
              end || line.single_labels.size

              line.single_labels.insert(index, {label.style, label_start...label_end, label.message})
              line.must_render = true
            else
              # Multi-line label
              label_index = labeled_file.num_multi_labels
              labeled_file.num_multi_labels += 1

              # First line
              label_start = label.range.begin - start_line_range.begin
              start_line = labeled_file.get_or_insert_line(start_line_index, start_line_range, start_line_number)
              start_line.multi_labels << {label_index, label.style, MultiLabel.new(MultiLabelType::Top, label_start)}
              start_line.must_render = true

              # Middle lines
              ((start_line_index + 1)...end_line_index).each do |line_index|
                line_range = files.line_range(label.file_id, line_index)
                line_number = line_index + 1

                outer_padding = Math.max(outer_padding, Term.count_digits(line_number))

                line = labeled_file.get_or_insert_line(line_index, line_range, line_number)
                line.multi_labels << {label_index, label.style, MultiLabel.new(MultiLabelType::Left)}

                # Render if within context
                if line_index - start_line_index <= @config.start_context_lines ||
                   end_line_index - line_index <= @config.end_context_lines
                  line.must_render = true
                end
              end

              # Last line
              label_end = label.range.end - end_line_range.begin
              end_line = labeled_file.get_or_insert_line(end_line_index, end_line_range, end_line_number)
              end_line.multi_labels << {label_index, label.style, MultiLabel.new(MultiLabelType::Bottom, label_end, label.message)}
              end_line.must_render = true
            end
          end

          # Render header
          renderer.render_header(
            nil,
            @diagnostic.severity,
            @diagnostic.code,
            @diagnostic.message
          )

          # Render snippets
          labeled_files.each do |labeled_file|
            source = files.source(labeled_file.file_id)
            lines = labeled_file.lines.select { |_, line| line.must_render }.to_a.sort_by(&.first)

            unless lines.empty?
              renderer.render_snippet_start(
                outer_padding,
                Locus.new(labeled_file.name, labeled_file.location)
              )
              renderer.render_snippet_empty(
                outer_padding,
                @diagnostic.severity,
                labeled_file.num_multi_labels,
                [] of Tuple(Int32, LabelStyle, MultiLabel)
              )
            end

            lines.each_with_index do |(line_index, line), i|
              renderer.render_snippet_source(
                outer_padding,
                line.number,
                source[line.range],
                @diagnostic.severity,
                line.single_labels,
                labeled_file.num_multi_labels,
                line.multi_labels
              )

              # Check for gaps between lines
              if i + 1 < lines.size
                next_line_index = lines[i + 1][0]
                case next_line_index - line_index
                when 1
                  # Consecutive
                when 2
                  # One line gap - render it
                  mid_index = line_index + 1
                  if mid_line = labeled_file.lines[mid_index]?
                    renderer.render_snippet_source(
                      outer_padding,
                      mid_index + 1,
                      source[files.line_range(labeled_file.file_id, mid_index)],
                      @diagnostic.severity,
                      [] of Tuple(LabelStyle, Range(Int32, Int32), String),
                      labeled_file.num_multi_labels,
                      mid_line.multi_labels
                    )
                  end
                else
                  # Break
                  renderer.render_snippet_break(
                    outer_padding,
                    @diagnostic.severity,
                    labeled_file.num_multi_labels,
                    lines[i + 1][1].multi_labels
                  )
                end
              end
            end

            # Trailing border
            unless lines.empty? || (labeled_files.last? == labeled_file && @diagnostic.notes.empty?)
              renderer.render_snippet_empty(
                outer_padding,
                @diagnostic.severity,
                labeled_file.num_multi_labels,
                [] of Tuple(Int32, LabelStyle, MultiLabel)
              )
            end
          end

          # Notes
          @diagnostic.notes.each do |note|
            renderer.render_snippet_note(outer_padding, note)
          end

          renderer.render_empty
        end
      end

      private class LabeledFile
        property file_id : Int32
        property start : Int32
        property name : String
        property location : Codespan::Reporting::Files::Location
        property num_multi_labels : Int32 = 0
        property lines : Hash(Int32, Line) = Hash(Int32, Line).new
        property max_label_style : Codespan::Reporting::LabelStyle

        def initialize(@file_id : Int32, @start : Int32, @name : String, @location : Codespan::Reporting::Files::Location, @max_label_style : Codespan::Reporting::LabelStyle)
        end

        def get_or_insert_line(line_index : Int32, line_range : Range(Int32, Int32), line_number : Int32) : Line
          @lines[line_index] ||= Line.new(line_number, line_range)
        end
      end

      private class Line
        property number : Int32
        property range : Range(Int32, Int32)
        property single_labels : Array(Tuple(Codespan::Reporting::LabelStyle, Range(Int32, Int32), String)) = [] of Tuple(Codespan::Reporting::LabelStyle, Range(Int32, Int32), String)
        property multi_labels : Array(Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)) = [] of Tuple(Int32, Codespan::Reporting::LabelStyle, MultiLabel)
        property must_render : Bool = false

        def initialize(@number, @range)
        end
      end

      class ShortDiagnostic
        def initialize(@diagnostic : Codespan::Reporting::Diagnostic, @show_notes : Bool)
        end

        def render(files, renderer : Renderer) : Nil
          # Located headers for primary labels
          primary_labels_encountered = 0
          @diagnostic.labels.each do |label|
            next unless label.style == Codespan::Reporting::LabelStyle::Primary

            primary_labels_encountered += 1
            locus = Locus.new(
              files.name(label.file_id),
              files.location(label.file_id, label.range.begin)
            )
            renderer.render_header(locus, @diagnostic.severity, @diagnostic.code, @diagnostic.message)
          end

          # Fallback to non-located header if no primary labels
          if primary_labels_encountered == 0
            renderer.render_header(nil, @diagnostic.severity, @diagnostic.code, @diagnostic.message)
          end

          if @show_notes
            @diagnostic.notes.each do |note|
              renderer.render_snippet_note(0, note)
            end
          end
        end
      end
    end
  end
end
