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

    # Normalize the many shapes a preset can arrive in into the canonical
    # [{ "condition" => ..., "attributeSet" => ... }, ...] array. Accepts:
    #   - the bare array itself
    #   - the { "preset" => [...] } object returned by build_preset
    #   - a single { "condition" => ..., "attributeSet" => ... } entry
    #   - a JSON string of any of the above
    def normalize_preset(value)
      data = value.is_a?(String) ? JSON.parse(value) : value
      data = data["preset"] || data[:preset] if data.is_a?(Hash) && (data["preset"] || data[:preset])
      data = [data] if data.is_a?(Hash) && (data["condition"] || data[:condition])
      unless data.is_a?(Array)
        raise ArgumentError, "preset must be a preset array or a { \"preset\": [...] } object"
      end

      data
    rescue JSON::ParserError
      raise ArgumentError, "preset must be valid JSON"
    end
  end
end
