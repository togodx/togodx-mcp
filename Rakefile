# frozen_string_literal: true

require "json"
require "open3"

task default: %i[test smoke]

desc "Run lightweight smoke checks against live APIs"
task :smoke do
  require_relative "lib/togodx_mcp"

  catalog = TogodxMcp::Catalog.load
  raise "attribute catalog is empty" if catalog.all_attribute_ids.empty?

  client = TogodxMcp::Client::Togodx.new
  rows = client.breakdown("gene_specific_expression_in_tissues_hpa")
  raise "breakdown returned no rows" if Array(rows).empty?

  builder = TogodxMcp::PresetBuilder.new(catalog: catalog)
  preset = builder.build(
    dataset: "uniprot",
    filters: [
      { "attribute" => "gene_specific_expression_in_tissues_hpa", "nodes" => %w[Lung] },
    ],
    annotations: [{ "attribute" => "structure_data_existence_uniprot" }]
  )
  raise "preset must be an array" unless preset.is_a?(Array)

  puts "smoke: ok (#{catalog.all_attribute_ids.length} attributes)"
end

desc "Send initialize and tools/list to the MCP server"
task :test do
  server = File.expand_path("exe/togodx-mcp", __dir__)
  stdin = <<~JSON
    {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"rake","version":"1.0.0"}}}
    {"jsonrpc":"2.0","id":2,"method":"tools/list"}
  JSON

  stdout, stderr, status = Open3.capture3("bundle", "exec", "ruby", server, stdin_data: stdin)
  raise stderr unless stderr.empty?
  raise "server failed: #{stdout}" unless status.success?

  lines = stdout.lines.map { |line| JSON.parse(line) }
  tool_names = lines.last.fetch("result").fetch("tools").map { |tool| tool["name"] }
  expected = %w[
    togodx_usage_guide list_categories get_attribute search_attributes breakdown
    suggest_nodes resolve_nodes convert_ids locate_ids preview_aggregate
    build_preset get_dataframe export_preset
  ]
  missing = expected - tool_names
  raise "missing tools: #{missing.join(', ')}" unless missing.empty?

  puts "test: ok (#{tool_names.length} tools)"
end
