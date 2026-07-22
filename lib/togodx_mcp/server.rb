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
      ground every node ID in API responses (never invent IDs), then:
      - run_preset to fetch the final result table (same as the web UI) for the
        LLM to interpret, and
      - always also give the user a build_share_link URL (and export_preset when
        they want a file) so they can open and verify the same conditions in the
        TogoDX/Human web UI. Returning results and guiding to the web UI are
        complementary, not either/or.
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

    # Rack app for the Streamable HTTP transport. The MCP server (and its
    # catalog + downstream clients) is built once here and reused across
    # requests, so mount the returned app in a long-running Rack server.
    def self.rack_app(stateless: Config.mcp_stateless?, enable_json_response: Config.mcp_enable_json_response?)
      MCP::Server::Transports::StreamableHTTPTransport.new(
        build,
        stateless: stateless,
        enable_json_response: enable_json_response
      )
    end
  end
end
