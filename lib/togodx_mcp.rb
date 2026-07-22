# frozen_string_literal: true

require_relative "togodx_mcp/version"
require_relative "togodx_mcp/config"
require_relative "togodx_mcp/http_client"
require_relative "togodx_mcp/catalog"
require_relative "togodx_mcp/client/togodx"
require_relative "togodx_mcp/client/togoid"
require_relative "togodx_mcp/node_resolver"
require_relative "togodx_mcp/preset_builder"
require_relative "togodx_mcp/tool_helpers"
require_relative "togodx_mcp/server"

module TogodxMcp
  module_function

  def run
    Server.run_stdio
  end

  # Build the Rack app for the remote (Streamable HTTP) MCP server, wrapped in
  # the token-auth + /health middleware. Mount this in config.ru.
  def rack_app
    require_relative "togodx_mcp/rack_auth"
    RackAuth.new(Server.rack_app)
  end
end
