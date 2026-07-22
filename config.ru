# frozen_string_literal: true

# Rack entry point for the remote (Streamable HTTP) TogoDX MCP server.
#
#   bundle install --with http      # install rack + puma
#   bundle exec puma -p 9292 config.ru
#
# The MCP endpoint is served at "/". GET /health returns 200 for liveness.
# Set TOGODX_MCP_AUTH_TOKEN to require `Authorization: Bearer <token>`.

require_relative "lib/togodx_mcp"

unless TogodxMcp::Config.mcp_auth_token
  warn "[togodx-mcp] WARNING: TOGODX_MCP_AUTH_TOKEN is not set; the HTTP MCP " \
       "endpoint is UNAUTHENTICATED. Set it before exposing this server."
end

run TogodxMcp.rack_app
