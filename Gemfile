# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.1"

gem "mcp", "~> 0.18"

# Required only for the remote (Streamable HTTP) MCP server. stdio users can
# skip these with `bundle install --without http`.
group :http do
  gem "rack", "~> 3.0"
  gem "puma", "~> 6.0"
end
