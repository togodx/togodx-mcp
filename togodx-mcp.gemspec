# frozen_string_literal: true

require_relative "lib/togodx_mcp/version"

Gem::Specification.new do |spec|
  spec.name = "togodx-mcp"
  spec.version = TogodxMcp::VERSION
  spec.authors = ["DBCLS"]
  spec.summary = "MCP server for TogoDX/Human"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"
  spec.files = Dir.chdir(__dir__) { Dir.glob("{exe,lib}/**/*") + %w[Gemfile togodx-mcp.gemspec] }
  spec.bindir = "exe"
  spec.executables = ["togodx-mcp"]
  spec.require_paths = ["lib"]
  spec.add_dependency "mcp", "~> 1.1"
end
