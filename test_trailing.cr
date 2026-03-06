require "./src/codespan"
require "golden"

files = Codespan::Reporting::Files::SimpleFiles.new
file_id = files.add(
  "tests/main.js",
  "\"use strict\";\nlet zero=0;\nfunction foo() {\n  \"use strict\";\n  one=1;\n}"
)

diagnostic = Codespan::Reporting::Diagnostic.warning
  .with_code("ParserWarning")
  .with_message("The strict mode declaration in the body of function `foo` is redundant, as the outer scope is already in strict mode")
  .with_labels([
    Codespan::Reporting::Label.primary(file_id, 45...57)
      .with_message("This strict mode declaration is redundant"),
    Codespan::Reporting::Label.secondary(file_id, 0...12)
      .with_message("Strict mode is first declared here"),
  ])

config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Medium)
actual = String.build do |io|
  Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
end

puts "Actual output (hex):"
actual.bytes.each do |b|
  printf "%02x ", b
end
puts "\n\nActual output length: #{actual.bytesize}"
if last10 = actual.bytes[-10..-1]?
  puts "Last 10 chars (hex):"
  last10.each do |b|
    printf "%02x ", b
  end
end
puts "\n\nActual output:"
print actual.inspect
