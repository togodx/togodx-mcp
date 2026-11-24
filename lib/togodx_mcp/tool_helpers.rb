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
    #   - a bare condition { "dataset" => ..., "filters" => ... }, or an array of them
    #   - a JSON string of any of the above
    # Keys are stringified throughout: the MCP SDK hands tool arguments over
    # with symbol keys, while preset consumers read string keys.
    def normalize_preset(value)
      data = JSON.parse(value.is_a?(String) ? value : JSON.generate(value))
      data = data["preset"] || data[:preset] if data.is_a?(Hash) && (data["preset"] || data[:preset])
      data = [data] if data.is_a?(Hash) && (data["condition"] || data["dataset"])
      unless data.is_a?(Array)
        raise ArgumentError, "preset must be a preset array or a { \"preset\": [...] } object"
      end

      data
    rescue JSON::ParserError
      raise ArgumentError, "preset must be valid JSON"
    end

    # The condition objects of a preset, whether its entries are wrapped as
    # { "condition" => ..., "attributeSet" => ... } or are bare conditions.
    def preset_conditions(value)
      normalize_preset(value).each_with_index.map do |entry, i|
        condition = entry.is_a?(Hash) ? (entry["condition"] || entry) : nil
        unless condition.is_a?(Hash) && condition.key?("dataset")
          raise ArgumentError, "Preset entry #{i} must be a condition object with a dataset " \
                               "(or { \"condition\": {...} })"
        end

        condition
      end
    end

    # A list argument given as a JSON string (the documented form) or a native
    # array; nil and "" mean an empty list.
    def list_arg(value, name)
      return [] if value.nil? || value.to_s.strip.empty?

      data = value.is_a?(String) ? JSON.parse(value) : JSON.parse(JSON.generate(value))
      raise ArgumentError, "#{name} must be a JSON array" unless data.is_a?(Array)

      data
    rescue JSON::ParserError
      raise ArgumentError, "#{name} must be a JSON array"
    end

    DEFAULT_ID_LIMIT = 20

    # Cap the matching IDs returned; id_limit 0 returns every ID. count is
    # always the total and ids_truncated says whether IDs were cut.
    def limited_ids(ids, id_limit)
      ids = Array(ids)
      id_limit = id_limit.nil? ? DEFAULT_ID_LIMIT : Integer(id_limit)
      shown = id_limit.positive? ? ids.first(id_limit) : ids
      { "count" => ids.length, "sample_ids" => shown, "ids_truncated" => shown.length < ids.length }
    end

    # The web UI's result table: /dataframe only returns rows for the IDs given
    # in queries, so first resolve the matching IDs with /aggregate (filters
    # intersected with any user-supplied IDs) and feed them back as queries.
    def fetch_table(togodx, dataset:, filters:, annotations: nil, queries: nil)
      filters_json = JSON.generate(Array(filters))
      ids = Array(
        togodx.aggregate(dataset: dataset, filters: filters_json, queries: JSON.generate(Array(queries)))
      )
      rows = ids.empty? ? [] : togodx.dataframe(
        dataset: dataset,
        filters: filters_json,
        annotations: annotations ? JSON.generate(annotations) : nil,
        queries: JSON.generate(ids)
      )
      [ids, rows]
    end
  end
end
