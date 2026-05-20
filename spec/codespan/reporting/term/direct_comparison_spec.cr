require "../../../spec_helper"
require "golden"

# Set golden to use the rust snapshots directory
Golden.dir = "spec/testdata/rust_snapshots"

# Helper to generate Crystal output for empty test
private def generate_empty_crystal_output(style : Codespan::Reporting::Term::DisplayStyle) : String
  files = Codespan::Reporting::Files::SimpleFiles.new
  diagnostics = [
    Codespan::Reporting::Diagnostic.bug,
    Codespan::Reporting::Diagnostic.error,
    Codespan::Reporting::Diagnostic.warning,
    Codespan::Reporting::Diagnostic.note,
    Codespan::Reporting::Diagnostic.help,
    Codespan::Reporting::Diagnostic.bug,
  ]

  config = Codespan::Reporting::Term::Config.new(display_style: style)
  String.build do |io|
    diagnostics.each do |diagnostic|
      Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
    end
  end
end

describe "Crystal vs Rust comparison using golden" do
  it "matches term__empty__rich_no_color" do
    actual = generate_empty_crystal_output(Codespan::Reporting::Term::DisplayStyle::Rich)
    Golden.require_equal("term__empty__rich_no_color", actual)
  end

  it "matches term__empty__medium_no_color" do
    actual = generate_empty_crystal_output(Codespan::Reporting::Term::DisplayStyle::Medium)
    Golden.require_equal("term__empty__medium_no_color", actual)
  end

  it "matches term__empty__short_no_color" do
    actual = generate_empty_crystal_output(Codespan::Reporting::Term::DisplayStyle::Short)
    Golden.require_equal("term__empty__short_no_color", actual)
  end

  it "matches term__message__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("a message"),
      Codespan::Reporting::Diagnostic.warning.with_message("a message"),
      Codespan::Reporting::Diagnostic.note.with_message("a message"),
      Codespan::Reporting::Diagnostic.help.with_message("a message"),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__message__rich_no_color", actual)
  end

  it "matches term__message_and_notes__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("a message").with_notes(["a note"]),
      Codespan::Reporting::Diagnostic.warning.with_message("a message").with_notes(["a note"]),
      Codespan::Reporting::Diagnostic.note.with_message("a message").with_notes(["a note"]),
      Codespan::Reporting::Diagnostic.help.with_message("a message").with_notes(["a note"]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__message_and_notes__rich_no_color", actual)
  end

  it "matches term__message_errorcode__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("a message").with_code("E0001"),
      Codespan::Reporting::Diagnostic.warning.with_message("a message").with_code("W001"),
      Codespan::Reporting::Diagnostic.note.with_message("a message").with_code("N0815"),
      Codespan::Reporting::Diagnostic.help.with_message("a message").with_code("H4711"),
      Codespan::Reporting::Diagnostic.error.with_message("where did my errorcode go?").with_code(""),
      Codespan::Reporting::Diagnostic.warning.with_message("where did my errorcode go?").with_code(""),
      Codespan::Reporting::Diagnostic.note.with_message("where did my errorcode go?").with_code(""),
      Codespan::Reporting::Diagnostic.help.with_message("where did my errorcode go?").with_code(""),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__message_errorcode__rich_no_color", actual)
  end

  it "matches term__same_line__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "fn main() {\n    let mut v = vec![Some(\"foo\"), Some(\"bar\")];\n    v.push(v.pop().unwrap());\n}\n"
    file_id = files.add("one_line.rs", source)

    diagnostics = [
      Codespan::Reporting::Diagnostic.error
        .with_code("E0499")
        .with_message("cannot borrow `v` as mutable more than once at a time")
        .with_labels([
          Codespan::Reporting::Label.primary(file_id, 71...72)
            .with_message("second mutable borrow occurs here"),
          Codespan::Reporting::Label.secondary(file_id, 64...65)
            .with_message("first borrow later used by call"),
          Codespan::Reporting::Label.secondary(file_id, 66...70)
            .with_message("first mutable borrow occurs here"),
        ]),
      Codespan::Reporting::Diagnostic.error
        .with_message("aborting due to previous error")
        .with_notes(["For more information about this error, try `rustc --explain E0499`."]),
    ]

    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end

    # Compare using golden - this should show a diff since we know this test was failing
    Golden.require_equal("term__same_line__rich_no_color", actual)
  end

  it "matches term__same_line__medium_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "fn main() {\n    let mut v = vec![Some(\"foo\"), Some(\"bar\")];\n    v.push(v.pop().unwrap());\n}\n"
    file_id = files.add("one_line.rs", source)
    diagnostics = [
      Codespan::Reporting::Diagnostic.error
        .with_code("E0499")
        .with_message("cannot borrow `v` as mutable more than once at a time")
        .with_labels([
          Codespan::Reporting::Label.primary(file_id, 71...72).with_message("second mutable borrow occurs here"),
          Codespan::Reporting::Label.secondary(file_id, 64...65).with_message("first borrow later used by call"),
          Codespan::Reporting::Label.secondary(file_id, 66...70).with_message("first mutable borrow occurs here"),
        ]),
      Codespan::Reporting::Diagnostic.error
        .with_message("aborting due to previous error")
        .with_notes(["For more information about this error, try `rustc --explain E0499`."]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Medium)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__same_line__medium_no_color", actual)
  end

  it "matches term__same_line__short_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "fn main() {\n    let mut v = vec![Some(\"foo\"), Some(\"bar\")];\n    v.push(v.pop().unwrap());\n}\n"
    file_id = files.add("one_line.rs", source)
    diagnostics = [
      Codespan::Reporting::Diagnostic.error
        .with_code("E0499")
        .with_message("cannot borrow `v` as mutable more than once at a time")
        .with_labels([
          Codespan::Reporting::Label.primary(file_id, 71...72).with_message("second mutable borrow occurs here"),
          Codespan::Reporting::Label.secondary(file_id, 64...65).with_message("first borrow later used by call"),
          Codespan::Reporting::Label.secondary(file_id, 66...70).with_message("first mutable borrow occurs here"),
        ]),
      Codespan::Reporting::Diagnostic.error
        .with_message("aborting due to previous error")
        .with_notes(["For more information about this error, try `rustc --explain E0499`."]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Short)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__same_line__short_no_color", actual)
  end

  it "matches term__position_indicator__medium_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add(
      "tests/main.js",
      "\"use strict\";\nlet zero=0;\nfunction foo() {\n  \"use strict\";\n  one=1;\n}"
    )

    diagnostics = [
      Codespan::Reporting::Diagnostic.warning
        .with_code("ParserWarning")
        .with_message("The strict mode declaration in the body of function `foo` is redundant, as the outer scope is already in strict mode")
        .with_labels([
          Codespan::Reporting::Label.primary(file_id, 45...57)
            .with_message("This strict mode declaration is redundant"),
          Codespan::Reporting::Label.secondary(file_id, 0...12)
            .with_message("Strict mode is first declared here"),
        ]),
    ]

    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Medium)
    actual = String.build do |io|
      diagnostics.each do |diagnostic|
        Codespan::Reporting::Term.emit_to_string(io, config, files, diagnostic)
      end
    end

    # Compare using golden
    Golden.require_equal("term__position_indicator__medium_no_color", actual)
  end

  it "matches term__multiline_overlapping__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "        match line_index.compare(self.last_line_index()) {\n            Ordering::Less => Ok(self.line_starts()[line_index.to_usize()]),\n            Ordering::Equal => Ok(self.source_span().end()),\n            Ordering::Greater => LineIndexOutOfBoundsError {\n                given: line_index,\n                max: self.last_line_index(),\n            },\n        }"
    file_id = files.add("codespan/src/file.rs", source)
    diagnostics = [
      Codespan::Reporting::Diagnostic.error
        .with_message("match arms have incompatible types")
        .with_code("E0308")
        .with_labels([
          Codespan::Reporting::Label.secondary(file_id, 89...134).with_message("this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"),
          Codespan::Reporting::Label.primary(file_id, 230...351).with_message("expected enum `Result`, found struct `LineIndexOutOfBoundsError`"),
          Codespan::Reporting::Label.secondary(file_id, 8...362).with_message("`match` arms have incompatible types"),
          Codespan::Reporting::Label.secondary(file_id, 167...195).with_message("this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"),
        ])
        .with_notes(["expected type `Result<ByteIndex, LineIndexOutOfBoundsError>`\n   found type `LineIndexOutOfBoundsError`"]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__multiline_overlapping__rich_no_color", actual)
  end

  it "matches term__fizz_buzz__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "module FizzBuzz where\n\nfizz₁ : Nat → String\nfizz₁ num = case (mod num 5) (mod num 3) of\n    0 0 => \"FizzBuzz\"\n    0 _ => \"Fizz\"\n    _ 0 => \"Buzz\"\n    _ _ => num\n\nfizz₂ : Nat → String\nfizz₂ num =\n    case (mod num 5) (mod num 3) of\n        0 0 => \"FizzBuzz\"\n        0 _ => \"Fizz\"\n        _ 0 => \"Buzz\"\n        _ _ => num\n"
    file_id = files.add("FizzBuzz.fun", source)
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("`case` clauses have incompatible types").with_code("E0308")
        .with_labels([Codespan::Reporting::Label.primary(file_id, 163...166).with_message("expected `String`, found `Nat`"),
                      Codespan::Reporting::Label.secondary(file_id, 62...166).with_message("`case` clauses have incompatible types"),
                      Codespan::Reporting::Label.secondary(file_id, 41...47).with_message("expected type `String` found here")])
        .with_notes(["expected type `String`\n   found type `Nat`"]),
      Codespan::Reporting::Diagnostic.error.with_message("`case` clauses have incompatible types").with_code("E0308")
        .with_labels([Codespan::Reporting::Label.primary(file_id, 328...331).with_message("expected `String`, found `Nat`"),
                      Codespan::Reporting::Label.secondary(file_id, 211...331).with_message("`case` clauses have incompatible types"),
                      Codespan::Reporting::Label.secondary(file_id, 258...268).with_message("this is found to be of type `String`"),
                      Codespan::Reporting::Label.secondary(file_id, 284...290).with_message("this is found to be of type `String`"),
                      Codespan::Reporting::Label.secondary(file_id, 306...312).with_message("this is found to be of type `String`"),
                      Codespan::Reporting::Label.secondary(file_id, 186...192).with_message("expected type `String` found here")])
        .with_notes(["expected type `String`\n   found type `Nat`"]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__fizz_buzz__rich_no_color", actual)
  end

  it "matches term__overlapping__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id1 = files.add("nested_impl_trait.rs", "use std::fmt::Debug;\n\nfn fine(x: impl Into<u32>) -> impl Into<u32> { x }\n\nfn bad_in_ret_position(x: impl Into<u32>) -> impl Into<impl Debug> { x }\n")
    file_id2 = files.add("typeck_type_placeholder_item.rs", "fn fn_test1() -> _ { 5 }\nfn fn_test2(x: i32) -> (_, _) { (x, x) }\n")
    file_id3 = files.add("libstd/thread/mod.rs", "#[stable(feature = \"rust1\", since = \"1.0.0\")]\npub fn spawn<F, T>(self, f: F) -> io::Result<JoinHandle<T>>\nwhere\n    F: FnOnce() -> T,\n    F: Send + 'static,\n    T: Send + 'static,\n{\n    unsafe { self.spawn_unchecked(f) }\n}\n")
    file_id4 = files.add("no_send_res_ports.rs", "use std::thread;\nuse std::rc::Rc;\n\n#[derive(Debug)]\nstruct Port<T>(Rc<T>);\n\nfn main() {\n    #[derive(Debug)]\n    struct Foo {\n        _x: Port<()>,\n    }\n\n    impl Drop for Foo {\n        fn drop(&mut self) {}\n    }\n\n    fn foo(x: Port<()>) -> Foo {\n        Foo {\n            _x: x\n        }\n    }\n\n    let x = foo(Port(Rc::new(())));\n\n    thread::spawn(move|| {\n        let y = x;\n        println!(\"{:?}\", y);\n    });\n}\n")
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_code("E0666").with_message("nested `impl Trait` is not allowed")
        .with_labels([Codespan::Reporting::Label.primary(file_id1, 129...139).with_message("nested `impl Trait` here"),
                      Codespan::Reporting::Label.secondary(file_id1, 119...140).with_message("outer `impl Trait`")]),
      Codespan::Reporting::Diagnostic.error.with_code("E0121").with_message("the type placeholder `_` is not allowed within types on item signatures")
        .with_labels([Codespan::Reporting::Label.primary(file_id2, 17...18).with_message("not allowed in type signatures"),
                      Codespan::Reporting::Label.secondary(file_id2, 17...18).with_message("help: replace with the correct return type: `i32`")]),
      Codespan::Reporting::Diagnostic.error.with_code("E0121").with_message("the type placeholder `_` is not allowed within types on item signatures")
        .with_labels([Codespan::Reporting::Label.primary(file_id2, 49...50).with_message("not allowed in type signatures"),
                      Codespan::Reporting::Label.primary(file_id2, 52...53).with_message("not allowed in type signatures"),
                      Codespan::Reporting::Label.secondary(file_id2, 48...54).with_message("help: replace with the correct return type: `(i32, i32)`")]),
      Codespan::Reporting::Diagnostic.error.with_code("E0277").with_message("`std::rc::Rc<()>` cannot be sent between threads safely")
        .with_labels([Codespan::Reporting::Label.primary(file_id4, 339...352).with_message("`std::rc::Rc<()>` cannot be sent between threads safely"),
                      Codespan::Reporting::Label.secondary(file_id4, 353...416).with_message("within this `[closure@no_send_res_ports.rs:29:19: 33:6 x:main::Foo]`"),
                      Codespan::Reporting::Label.secondary(file_id3, 141...145).with_message("required by this bound in `std::thread::spawn`")])
        .with_notes(["help: within `[closure@no_send_res_ports.rs:29:19: 33:6 x:main::Foo]`, the trait `std::marker::Send` is not implemented for `std::rc::Rc<()>`",
                     "note: required because it appears within the type `Port<()>`", "note: required because it appears within the type `main::Foo`",
                     "note: required because it appears within the type `[closure@no_send_res_ports.rs:29:19: 33:6 x:main::Foo]`"]),
      Codespan::Reporting::Diagnostic.error.with_message("aborting due 5 previous errors")
        .with_notes(["Some errors have detailed explanations: E0121, E0277, E0666.", "For more information about an error, try `rustc --explain E0121`."]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__overlapping__rich_no_color", actual)
  end

  it "matches term__empty_ranges__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "Hello world!\nBye world!\n   "
    file_id = files.add("hello", source)
    eof = source.bytesize
    diagnostics = [
      Codespan::Reporting::Diagnostic.note.with_message("middle").with_labels([Codespan::Reporting::Label.primary(file_id, 6...6).with_message("middle")]),
      Codespan::Reporting::Diagnostic.note.with_message("end of line").with_labels([Codespan::Reporting::Label.primary(file_id, 12...12).with_message("end of line")]),
      Codespan::Reporting::Diagnostic.note.with_message("end of line").with_labels([Codespan::Reporting::Label.primary(file_id, 23...23).with_message("end of line")]),
      Codespan::Reporting::Diagnostic.note.with_message("end of file").with_labels([Codespan::Reporting::Label.primary(file_id, eof...eof).with_message("end of file")]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__empty_ranges__rich_no_color", actual)
  end

  it "matches term__same_ranges__rich_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    file_id = files.add("same_range", "::S { }")
    diagnostics = [
      Codespan::Reporting::Diagnostic.error.with_message("Unexpected token")
        .with_labels([Codespan::Reporting::Label.primary(file_id, 4...4).with_message("Unexpected '{'"),
                      Codespan::Reporting::Label.secondary(file_id, 4...4).with_message("Expected '('")]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__same_ranges__rich_no_color", actual)
  end

  it "matches term__tabbed__tab_width_default_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "Entity:\n\tArmament:\n\t\tWeapon: DogJaw\n\t\tReloadingCondition:\tattack-cooldown\n\tFoo: Bar"
    file_id = files.add("tabbed", source)
    diagnostics = [
      Codespan::Reporting::Diagnostic.warning.with_message("unknown weapon `DogJaw`")
        .with_labels([Codespan::Reporting::Label.primary(file_id, 29...35).with_message("the weapon")]),
      Codespan::Reporting::Diagnostic.warning.with_message("unknown condition `attack-cooldown`")
        .with_labels([Codespan::Reporting::Label.primary(file_id, 58...73).with_message("the condition")]),
      Codespan::Reporting::Diagnostic.warning.with_message("unknown field `Foo`")
        .with_labels([Codespan::Reporting::Label.primary(file_id, 75...78).with_message("the field")]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__tabbed__tab_width_default_no_color", actual)
  end

  it "matches term__tab_columns__tab_width_default_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "\thello\n\u{2219}\thello\n\u{2219}\u{2219}\thello\n\u{2219}\u{2219}\u{2219}\thello\n\u{2219}\u{2219}\u{2219}\u{2219}\thello\n\u{2219}\u{2219}\u{2219}\u{2219}\u{2219}\thello\n\u{2219}\u{2219}\u{2219}\u{2219}\u{2219}\u{2219}\thello"
    file_id = files.add("tab_columns", source)
    ranges = [] of Range(Int32, Int32)
    offset = 0
    while idx = source.byte_index("hello", offset)
      ranges << (idx...(idx + 5))
      offset = idx + 1
    end
    diagnostics = [Codespan::Reporting::Diagnostic.warning.with_message("tab test").with_labels(ranges.map { |r| Codespan::Reporting::Label.primary(file_id, r) })]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Rich)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__tab_columns__tab_width_default_no_color", actual)
  end

  it "matches term__multiline_overlapping__medium_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "        match line_index.compare(self.last_line_index()) {\n            Ordering::Less => Ok(self.line_starts()[line_index.to_usize()]),\n            Ordering::Equal => Ok(self.source_span().end()),\n            Ordering::Greater => LineIndexOutOfBoundsError {\n                given: line_index,\n                max: self.last_line_index(),\n            },\n        }"
    file_id = files.add("codespan/src/file.rs", source)
    diagnostics = [
      Codespan::Reporting::Diagnostic.error
        .with_message("match arms have incompatible types")
        .with_code("E0308")
        .with_labels([
          Codespan::Reporting::Label.secondary(file_id, 89...134).with_message("this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"),
          Codespan::Reporting::Label.primary(file_id, 230...351).with_message("expected enum `Result`, found struct `LineIndexOutOfBoundsError`"),
          Codespan::Reporting::Label.secondary(file_id, 8...362).with_message("`match` arms have incompatible types"),
          Codespan::Reporting::Label.secondary(file_id, 167...195).with_message("this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"),
        ])
        .with_notes(["expected type `Result<ByteIndex, LineIndexOutOfBoundsError>`\n   found type `LineIndexOutOfBoundsError`"]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Medium)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__multiline_overlapping__medium_no_color", actual)
  end

  it "matches term__multiline_overlapping__short_no_color" do
    files = Codespan::Reporting::Files::SimpleFiles.new
    source = "        match line_index.compare(self.last_line_index()) {\n            Ordering::Less => Ok(self.line_starts()[line_index.to_usize()]),\n            Ordering::Equal => Ok(self.source_span().end()),\n            Ordering::Greater => LineIndexOutOfBoundsError {\n                given: line_index,\n                max: self.last_line_index(),\n            },\n        }"
    file_id = files.add("codespan/src/file.rs", source)
    diagnostics = [
      Codespan::Reporting::Diagnostic.error
        .with_message("match arms have incompatible types")
        .with_code("E0308")
        .with_labels([
          Codespan::Reporting::Label.secondary(file_id, 89...134).with_message("this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"),
          Codespan::Reporting::Label.primary(file_id, 230...351).with_message("expected enum `Result`, found struct `LineIndexOutOfBoundsError`"),
          Codespan::Reporting::Label.secondary(file_id, 8...362).with_message("`match` arms have incompatible types"),
          Codespan::Reporting::Label.secondary(file_id, 167...195).with_message("this is found to be of type `Result<ByteIndex, LineIndexOutOfBoundsError>`"),
        ])
        .with_notes(["expected type `Result<ByteIndex, LineIndexOutOfBoundsError>`\n   found type `LineIndexOutOfBoundsError`"]),
    ]
    config = Codespan::Reporting::Term::Config.new(display_style: Codespan::Reporting::Term::DisplayStyle::Short)
    actual = String.build { |io| diagnostics.each { |d| Codespan::Reporting::Term.emit_to_string(io, config, files, d) } }
    Golden.require_equal("term__multiline_overlapping__short_no_color", actual)
  end
end
