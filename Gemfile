# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.1"

# 1.x speaks the 2026-07-28 protocol revision (stateless core, server/discover)
# while still answering the legacy `initialize` handshake, so the server works
# for both modern and pre-2026-07-28 clients.
gem "mcp", "~> 1.1"

# Pulled in transitively (mcp -> json_schemer -> bigdecimal). Pin to the 3.1
# series: bigdecimal 4.1.2 uses `#elif __has_include(<stdckdint.h>)`, which
# older system compilers (GCC < 5) cannot parse, breaking `bundle install` on
# some deployment servers. json_schemer itself puts no bound on bigdecimal, so
# without this pin the 4.x series gets resolved.
gem "bigdecimal", "~> 3.1"

# Required only for the remote (Streamable HTTP) MCP server. stdio users can
# skip these (the http group is not installed unless you opt in with
# `bundle config set --local with http`).
group :http do
  gem "rack", "~> 3.0"
  gem "puma", "~> 6.0"
end
