# frozen_string_literal: true

require "json"

module TogodxMcp
  module ToolHelpers
    module_function

    def json_response(payload)
      MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(payload) }])
    end

    def text_response(text)
      MCP::Tool::Response.new([{ type: "text", text: text }])
    end

    def error_response(error)
      message = error.is_a?(Exception) ? "#{error.class}: #{error.message}" : error.to_s
      json_response({ "error" => message })
    end

    def context!(server_context)
      server_context || raise(ArgumentError, "server_context is required")
    end

    def parse_json_array(value, name)
      return value if value.is_a?(Array)

      JSON.parse(value.to_s)
    rescue JSON::ParserError
      raise ArgumentError, "#{name} must be a JSON array"
    end

    def parse_json_object(value, name)
      return value if value.is_a?(Hash)

      JSON.parse(value.to_s)
    rescue JSON::ParserError
      raise ArgumentError, "#{name} must be a JSON object"
    end
  end
end
