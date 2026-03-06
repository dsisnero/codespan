require "./term/config"
require "./term/renderer"
require "./term/views"

module Codespan
  module Reporting
    module Term
      def self.emit_into_string(
        config : Config,
        files,
        diagnostic : Codespan::Reporting::Diagnostic,
      ) : String
        String.build do |io|
          emit_to_string(io, config, files, diagnostic)
        end
      end

      def self.emit_to_string(
        writer : IO,
        config : Config,
        files,
        diagnostic : Codespan::Reporting::Diagnostic,
      ) : Nil
        renderer = Renderer.new(writer, config)

        case config.display_style
        when DisplayStyle::Rich
          RichDiagnostic.new(diagnostic, config).render(files, renderer)
        when DisplayStyle::Medium
          ShortDiagnostic.new(diagnostic, true).render(files, renderer)
        when DisplayStyle::Short
          ShortDiagnostic.new(diagnostic, false).render(files, renderer)
        end
      end
    end
  end
end
