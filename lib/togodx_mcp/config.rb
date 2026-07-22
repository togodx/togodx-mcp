# frozen_string_literal: true

module TogodxMcp
  module Config
    module_function

    def togodx_base_url
      ENV.fetch("TOGODX_BASE_URL", "https://togodx.dbcls.jp/human")
    end

    def togodx_config_url
      ENV.fetch(
        "TOGODX_CONFIG_URL",
        "https://raw.githubusercontent.com/togodx/togodx-config-human/develop/config/attributes.dx-server.json"
      )
    end

    def togoid_base_url
      ENV.fetch("TOGOID_BASE_URL", "https://api.togoid.dbcls.jp")
    end

    def togodx_ui_url
      ENV.fetch("TOGODX_UI_URL", "https://togodx.dbcls.jp/human")
    end

    # --- Streamable HTTP transport (remote MCP) settings ---

    # Bearer token required on every HTTP MCP request. When unset, the HTTP
    # transport runs unauthenticated (only acceptable for local/dev use).
    def mcp_auth_token
      token = ENV["TOGODX_MCP_AUTH_TOKEN"].to_s
      token.empty? ? nil : token
    end

    # Run the Streamable HTTP transport in stateless mode (no per-session SSE
    # state); useful behind load balancers or on serverless platforms.
    def mcp_stateless?
      %w[1 true yes].include?(ENV["TOGODX_MCP_STATELESS"].to_s.downcase)
    end

    # Reply to POSTs with a plain application/json body instead of an SSE
    # (text/event-stream) stream. Enable for clients that do not read SSE.
    def mcp_enable_json_response?
      %w[1 true yes].include?(ENV["TOGODX_MCP_JSON_RESPONSE"].to_s.downcase)
    end
  end
end
