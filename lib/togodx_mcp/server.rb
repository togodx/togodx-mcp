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

      A one-stop way to explore and extract human life-science information in
      TogoDX/Human (gene expression, localization, interactions, compounds,
      disease, variants, and more) from natural language. Search attributes and
      ground every node ID in API responses (never invent IDs), then either:
      - run_preset to fetch the final result table (same as the web UI) for the
        LLM to interpret, or
      - build_share_link / export_preset so a human can open or upload the same
        conditions in the TogoDX/Human web UI.
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
