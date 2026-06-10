# frozen_string_literal: true

require "mcp"

require_relative "catalog"
require_relative "client/togodx"
require_relative "client/togoid"
require_relative "tools/registry"

module TogodxMcp
  class Server
    INSTRUCTIONS = <<~TEXT.strip
      TogoDX/Human MCP server. Start with togodx_usage_guide.
      Build uploadable preset JSON from natural-language exploration requests,
      ground every node ID in API responses, and use export_preset for UI verification.
    TEXT

    def self.build
      catalog = Catalog.load
      server_context = {
        catalog: catalog,
        togodx: Client::Togodx.new,
        togoid: Client::Togoid.new,
      }

      MCP::Server.new(
        name: "togodx-mcp",
        version: VERSION,
        instructions: INSTRUCTIONS,
        tools: Tools::Registry.all,
        server_context: server_context,
      )
    end

    def self.run_stdio
      transport = MCP::Server::Transports::StdioTransport.new(build)
      transport.open
    end
  end
end
