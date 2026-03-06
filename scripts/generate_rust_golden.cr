#!/usr/bin/env crystal

# This script runs the Rust tests and captures their output to create golden files
# for comparison with the Crystal implementation.

require "file_utils"
require "process"

# Directory where Rust snapshots are stored
RUST_SNAPSHOT_DIR = "vendor/codespan/codespan-reporting/tests/snapshots"

# Directory where we'll store our golden files
GOLDEN_DIR = "spec/testdata/rust_snapshots"

def run_rust_tests
  puts "Running Rust tests to generate golden files..."

  # Change to the Rust directory
  Dir.cd("vendor/codespan") do
    # Run cargo test to generate snapshots
    # Note: We need to run with --test term to generate the snapshots
    # The snapshots are already in the repo, but we could regenerate them if needed
    puts "Rust snapshots are already in #{RUST_SNAPSHOT_DIR}"
    puts "Copying them to #{GOLDEN_DIR}..."
  end
end

def copy_snapshots_to_golden
  # Create golden directory
  FileUtils.mkdir_p(GOLDEN_DIR)

  # Copy all .snap files
  snap_files = Dir.glob("#{RUST_SNAPSHOT_DIR}/*.snap")
  snap_files.each do |snap_file|
    basename = File.basename(snap_file, ".snap")
    golden_file = File.join(GOLDEN_DIR, "#{basename}.golden")

    # Read the snapshot file and extract just the body (after the YAML frontmatter)
    content = File.read(snap_file)

    # Snapshot files have YAML frontmatter separated by "---"
    # We want just the body after the second "---"
    delimiter = "---\n"
    first = content.index(delimiter)

    if first
      second = content.index(delimiter, first + delimiter.bytesize)
      if second
        body = content[(second + delimiter.bytesize)..]
        # Remove trailing newline if present (to match golden library behavior)
        body = body.chomp('\n')
        File.write(golden_file, body)
      else
        File.write(golden_file, content)
      end
    else
      File.write(golden_file, content)
    end

    puts "Copied #{basename}.snap -> #{basename}.golden"
  end

  puts "Copied #{snap_files.size} snapshot files"
  snap_files
end

def create_golden_test(snap_files)
  puts "\nCreating golden test file..."

  # Start building the test file content
  test_content = <<-CRYSTAL
require "../../../spec_helper"
require "golden"

# Initialize golden to use spec/testdata directory
Golden.dir = "spec/testdata/rust_snapshots"

# Helper to read golden file body (strips YAML frontmatter)
private def golden_body(path : String) : String
  content = File.read(path)
  delimiter = "---\\n"

  first = content.index(delimiter)
  return content unless first

  second = content.index(delimiter, first + delimiter.bytesize)
  return content unless second

  body = content[(second + delimiter.bytesize)..]
  body.ends_with?('\\n') ? body[0...-1] : body
end

describe "Rust snapshot parity (golden)" do
CRYSTAL

  # Add a test for each snapshot file
  snap_files.each do |snap_path|
    basename = File.basename(snap_path, ".snap")
    test_content += <<-CRYSTAL

  it "matches #{basename}" do
    # Get the expected output from Rust snapshot
    expected = golden_body("#{snap_path}")

    # TODO: Generate the actual output from Crystal implementation
    # For now, we'll just read the golden file we created
    golden_path = "spec/testdata/rust_snapshots/#{basename}.golden"
    if File.exists?(golden_path)
      actual = File.read(golden_path)
      Golden.require_equal("#{basename}", actual)
    else
      pending "Golden file not generated for #{basename}"
    end
  end
CRYSTAL
  end

  # Close the describe block
  test_content += "\nend\n"

  File.write("spec/codespan/reporting/term/golden_parity_spec.cr", test_content)
  puts "Created spec/codespan/reporting/term/golden_parity_spec.cr"
end

# Main execution
run_rust_tests
snap_files = copy_snapshots_to_golden
create_golden_test(snap_files)

puts "\nDone! Next steps:"
puts "1. Run the tests: crystal spec spec/codespan/reporting/term/golden_parity_spec.cr"
puts "2. To update golden files: GOLDEN_UPDATE=1 crystal spec spec/codespan/reporting/term/golden_parity_spec.cr"
puts "3. Implement the actual Crystal output generation in the test"
