module Codespan
  module Reporting
    enum Severity
      Help
      Note
      Warning
      Error
      Bug
    end

    enum LabelStyle
      Primary
      Secondary
    end

    struct Label
      getter style : LabelStyle
      getter file_id : Int32
      getter range : Range(Int32, Int32)
      getter message : String

      def initialize(@style : LabelStyle, @file_id : Int32, @range : Range(Int32, Int32), @message : String = "")
      end

      def self.primary(file_id : Int, range : Range(Int32, Int32)) : Label
        new(LabelStyle::Primary, file_id.to_i, range)
      end

      def self.secondary(file_id : Int, range : Range(Int32, Int32)) : Label
        new(LabelStyle::Secondary, file_id.to_i, range)
      end

      def with_message(message) : Label
        Label.new(@style, @file_id, @range, message.to_s)
      end
    end

    struct Diagnostic
      getter severity : Severity
      getter code : String?
      getter message : String
      getter labels : Array(Label)
      getter notes : Array(String)

      def initialize(
        @severity : Severity,
        @code : String? = nil,
        @message : String = "",
        @labels : Array(Label) = [] of Label,
        @notes : Array(String) = [] of String,
      )
      end

      def self.bug : Diagnostic
        Diagnostic.new(Severity::Bug)
      end

      def self.error : Diagnostic
        Diagnostic.new(Severity::Error)
      end

      def self.warning : Diagnostic
        Diagnostic.new(Severity::Warning)
      end

      def self.note : Diagnostic
        Diagnostic.new(Severity::Note)
      end

      def self.help : Diagnostic
        Diagnostic.new(Severity::Help)
      end

      def with_code(code) : Diagnostic
        copy_with(code: code.to_s)
      end

      def with_message(message) : Diagnostic
        copy_with(message: message.to_s)
      end

      def with_label(label : Label) : Diagnostic
        labels = @labels.dup
        labels << label
        copy_with(labels: labels)
      end

      def with_labels(labels : Array(Label)) : Diagnostic
        next_labels = @labels.dup
        next_labels.concat(labels)
        copy_with(labels: next_labels)
      end

      def with_note(note) : Diagnostic
        notes = @notes.dup
        notes << note.to_s
        copy_with(notes: notes)
      end

      def with_notes(notes : Array(String)) : Diagnostic
        next_notes = @notes.dup
        next_notes.concat(notes)
        copy_with(notes: next_notes)
      end

      private def copy_with(
        severity : Severity = @severity,
        code : String? = @code,
        message : String = @message,
        labels : Array(Label) = @labels,
        notes : Array(String) = @notes,
      ) : Diagnostic
        Diagnostic.new(severity, code, message, labels, notes)
      end
    end
  end
end
