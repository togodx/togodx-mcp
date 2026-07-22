# frozen_string_literal: true

require "json"

module TogodxMcp
  # Minimal Rack middleware for the remote (Streamable HTTP) MCP server.
  #
  # - Answers GET /health with 200 for liveness checks (never authenticated).
  # - When a bearer token is configured, requires
  #   `Authorization: Bearer <token>` on every other request and rejects
  #   mismatches with 401. When no token is configured it lets requests through
  #   so local development still works, but the app prints a warning at boot.
  class RackAuth
    HEALTH_PATH = "/health"

    def initialize(app, token: Config.mcp_auth_token)
      @app = app
      @token = token
    end

    def call(env)
      return health_response if health_check?(env)
      return unauthorized unless authorized?(env)

      @app.call(env)
    end

    private

    def health_check?(env)
      env["REQUEST_METHOD"] == "GET" && env["PATH_INFO"] == HEALTH_PATH
    end

    def authorized?(env)
      return true if @token.nil? # no token configured -> open (dev only)

      header = env["HTTP_AUTHORIZATION"].to_s
      scheme, value = header.split(" ", 2)
      return false unless scheme&.casecmp?("Bearer") && value

      # Constant-time comparison to avoid leaking the token via timing.
      secure_compare(value.strip, @token)
    end

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      res = 0
      a.bytes.zip(b.bytes) { |x, y| res |= x ^ y }
      res.zero?
    end

    def health_response
      [200, { "Content-Type" => "application/json" }, [JSON.generate({ "status" => "ok" })]]
    end

    def unauthorized
      body = JSON.generate({ "error" => "unauthorized" })
      [401, { "Content-Type" => "application/json", "WWW-Authenticate" => "Bearer" }, [body]]
    end
  end
end
