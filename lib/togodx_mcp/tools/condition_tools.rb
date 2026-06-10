# frozen_string_literal: true

require "json"
require "tempfile"

require_relative "../config"
require_relative "../tool_helpers"

module TogodxMcp
  module Tools
    class PreviewAggregate < MCP::Tool
      tool_name "preview_aggregate"
      description "Preview how many entries match filters using the /aggregate API."
      input_schema(
        properties: {
          dataset: { type: "string" },
          filters: {
            type: "array",
            items: {
              type: "object",
              properties: {
                attribute: { type: "string" },
                nodes: { type: "array", items: { type: "string" } },
              },
              required: %w[attribute nodes],
            },
          },
        },
        required: %w[dataset filters]
      )

      def self.call(dataset:, filters:, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        ids = ctx[:togodx].aggregate(dataset: dataset, filters: filters)
        ToolHelpers.json_response(
          {
            "count" => Array(ids).length,
            "sample_ids" => Array(ids).first(20),
          }
        )
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class BuildPreset < MCP::Tool
      tool_name "build_preset"
      description "Build a TogoDX uploadable preset JSON array from structured condition fields."
      input_schema(
        properties: {
          dataset: { type: "string" },
          filters: {
            type: "array",
            items: {
              type: "object",
              properties: {
                attribute: { type: "string" },
                nodes: { type: "array", items: { type: "string" } },
              },
              required: %w[attribute nodes],
            },
          },
          annotations: {
            type: "array",
            items: {
              type: "object",
              properties: {
                attribute: { type: "string" },
                node: { type: "string" },
              },
              required: ["attribute"],
            },
          },
          queries: {
            type: "array",
            items: { type: "string" },
            description: "Optional user ID list. Omit or leave empty to exclude queries from JSON.",
          },
        },
        required: %w[dataset filters]
      )

      def self.call(dataset:, filters:, annotations: nil, queries: nil, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        builder = PresetBuilder.new(catalog: ctx[:catalog])
        preset = builder.build(
          dataset: dataset,
          filters: filters,
          annotations: annotations,
          queries: queries
        )
        ToolHelpers.json_response({ "preset" => preset })
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class GetDataframe < MCP::Tool
      tool_name "get_dataframe"
      description "Fetch the result table from /dataframe for a built condition."
      input_schema(
        properties: {
          dataset: { type: "string" },
          filters: {
            type: "array",
            items: {
              type: "object",
              properties: {
                attribute: { type: "string" },
                nodes: { type: "array", items: { type: "string" } },
              },
              required: %w[attribute nodes],
            },
          },
          annotations: {
            type: "array",
            items: {
              type: "object",
              properties: {
                attribute: { type: "string" },
                node: { type: "string" },
              },
              required: ["attribute"],
            },
          },
          queries: {
            type: "array",
            items: { type: "string" },
            description: "User ID list. Use an empty array when not mapping IDs.",
          },
        },
        required: %w[dataset filters]
      )

      def self.call(dataset:, filters:, annotations: nil, queries: [], server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        rows = ctx[:togodx].dataframe(
          dataset: dataset,
          filters: filters,
          annotations: annotations,
          queries: queries || []
        )
        ToolHelpers.json_response(
          {
            "row_count" => Array(rows).length,
            "rows" => rows,
          }
        )
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class ExportPreset < MCP::Tool
      tool_name "export_preset"
      description "Write preset JSON to a file and return upload instructions for the TogoDX UI."
      input_schema(
        properties: {
          preset: {
            description: "Preset array from build_preset, or a JSON string of that array.",
            type: "array",
          },
          filename: {
            type: "string",
            description: "Optional output filename. Defaults to togodx_preset.json in the temp directory.",
          },
        },
        required: ["preset"]
      )

      def self.call(preset:, filename: nil, server_context: nil)
        ToolHelpers.context!(server_context)
        preset_data = preset.is_a?(String) ? JSON.parse(preset) : preset
        raise ArgumentError, "preset must be a JSON array" unless preset_data.is_a?(Array)

        path = filename.to_s.empty? ? File.join(Dir.tmpdir, "togodx_preset.json") : filename
        File.write(path, JSON.pretty_generate(preset_data))

        condition = preset_data.first&.fetch("condition", {})
        ToolHelpers.json_response(
          {
            "file_path" => path,
            "preset_json" => preset_data,
            "upload_instructions" => "Open #{Config.togodx_ui_url} and upload this JSON via the Conditions JSON upload feature.",
            "summary" => {
              "dataset" => condition["dataset"],
              "filter_count" => Array(condition["filters"]).length,
              "annotation_count" => Array(condition["annotations"]).length,
              "query_count" => Array(condition["queries"]).length,
            },
          }
        )
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end
  end
end
