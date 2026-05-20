#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "set"
require "tempfile"
require_relative "parity_inventory_lib"

VALID_STATUS = Set.new(%w[missing in_progress ported partial skipped intentional_divergence]).freeze

options = {
  root_dir: Dir.pwd,
  manifest: nil,
  source_path: ENV["PORT_SOURCE_DIR"],
  language: ENV["PORT_LANGUAGE"] || "go",
  parser: ENV["PORT_PARSER"] || "auto"
}

OptionParser.new do |opts|
  opts.banner = "Usage: check_port_inventory.rb [options]"
  opts.on("--root DIR", "Project root (default: pwd)") { |v| options[:root_dir] = v }
  opts.on("--manifest FILE", "Inventory TSV path") { |v| options[:manifest] = v }
  opts.on("--source PATH", "Source path (absolute or relative to root)") { |v| options[:source_path] = v }
  opts.on("--language LANG", "Language: go|rust|crystal|java|ruby|typescript") { |v| options[:language] = v }
  opts.on("--parser MODE", "Parser: auto|regex|tree-sitter") { |v| options[:parser] = v }
end.parse!

language = options[:language]
manifest = options[:manifest] || File.join(options[:root_dir], "plans/inventory/#{language}_port_inventory.tsv")
raise "Missing manifest: #{manifest}" unless File.file?(manifest)

_, items = ParityInventory.discover_items(
  root_dir: options[:root_dir],
  source_path: options[:source_path],
  language: language,
  parser_mode: options[:parser]
)

discovered_ids = items.map(&:id).to_set

# Merge source_parity IDs to include manually curated items
source_parity_path = File.join(options[:root_dir], "plans/inventory/#{language}_source_parity.tsv")
if File.file?(source_parity_path)
  ParityInventory.load_manifest_rows(source_parity_path, min_cols: 4).each do |cols|
    discovered_ids << cols[0]
  end
end

manifest_ids = Set.new
manifest_status = {}
errors = []

ParityInventory.load_manifest_rows(manifest, min_cols: 5).each do |cols|
  id, _kind, status, refs, = cols

  errors << "Duplicate source_id: #{id}" if manifest_ids.include?(id)
  manifest_ids << id
  manifest_status[id] = status

  unless VALID_STATUS.include?(status)
    errors << "Invalid status for #{id}: #{status}"
  end

  if %w[ported partial].include?(status) && refs.to_s.empty?
    errors << "crystal_refs required when status=#{status} for #{id}"
  end
end

unless errors.empty?
  warn errors.join("\n")
  exit 2
end

missing = discovered_ids - manifest_ids
# Only flag stale items that are actively ported (ported/partial/in_progress/missing)
# skipped and intentional_divergence items are exempt from rediscovery
stale = manifest_ids.select { |id|
  !discovered_ids.include?(id) && %w[ported partial in_progress missing].include?(manifest_status[id])
}.to_set

if missing.any?
  warn "Source items missing from inventory:"
  missing.to_a.sort.each { |id| warn "  - #{id}" }
  exit 1
end

if stale.any?
  warn "Inventory has stale items not present in source:"
  stale.to_a.sort.each { |id| warn "  - #{id}" }
  exit 1
end

puts "Port inventory check passed (#{discovered_ids.size} items tracked)."
