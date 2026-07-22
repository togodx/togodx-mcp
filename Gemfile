# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.1"

gem "mcp", "~> 0.18"

# Pulled in transitively (mcp -> json-schema -> bigdecimal). Pin to the 3.1
# series: bigdecimal 4.1.2 uses `#elif __has_include(<stdckdint.h>)`, which
# older system compilers (GCC < 5) cannot parse, breaking `bundle install` on
# some deployment servers. 3.1.x satisfies json-schema's `>= 3.1, < 5`.
gem "bigdecimal", "~> 3.1"

# Required only for the remote (Streamable HTTP) MCP server. stdio users can
# skip these (the http group is not installed unless you opt in with
# `bundle config set --local with http`).
group :http do
  gem "rack", "~> 3.0"
  gem "puma", "~> 6.0"
end
