# frozen_string_literal: true

require "json"
require "tempfile"
require "erb"

require_relative "../config"
require_relative "../tool_helpers"

module TogodxMcp
  module Tools
    class PreviewAggregate < MCP::Tool
      tool_name "preview_aggregate"
      description "Preview how many entries match a condition using the /aggregate API."
      input_schema(
        properties: {
          dataset: {
            type: "string",
            description: "Primary-key dataset the result rows are keyed on, e.g. uniprot " \
                         "(proteins) or ensembl_gene (genes). Each attribute reports its dataset " \
                         "via search_attributes; filters may mix attributes from other datasets.",
          },
          filters: {
            type: "string",
            description: "JSON-stringified array of filter objects, " \
                         "e.g. '[{\"attribute\":\"...\",\"nodes\":[\"...\"]}]'. " \
                         "Provide filters and/or queries; at least one must be a non-empty array. " \
                         "Sent to the API as a JSON string so GET and POST share one key-value format.",
          },
          queries: {
            type: "string",
            description: "JSON-stringified array of user IDs, e.g. '[\"ID1\",\"ID2\"]'. " \
                         "Provide filters and/or queries; at least one must be a non-empty array.",
          },
        },
        required: %w[dataset]
      )

      def self.call(dataset:, filters: nil, queries: nil, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        raise ArgumentError, "dataset is required" if dataset.to_s.empty?

        filters_json = filters.to_s.empty? ? "[]" : filters
        queries_json = queries.to_s.empty? ? "[]" : queries
        if Array(JSON.parse(filters_json)).empty? && Array(JSON.parse(queries_json)).empty?
          raise ArgumentError, "At least one of filters or queries must be a non-empty array"
        end

        ids = ctx[:togodx].aggregate(dataset: dataset, filters: filters_json, queries: queries_json)
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
          dataset: {
            type: "string",
            description: "Primary-key dataset the result rows are keyed on, e.g. uniprot " \
                         "(proteins) or ensembl_gene (genes). Each attribute reports its dataset " \
                         "via search_attributes; filters may mix attributes from other datasets.",
          },
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
            description: "Optional user ID list. Always kept in the JSON as [] when empty.",
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
          dataset: {
            type: "string",
            description: "Primary-key dataset the result rows are keyed on, e.g. uniprot " \
                         "(proteins) or ensembl_gene (genes). Each attribute reports its dataset " \
                         "via search_attributes; filters may mix attributes from other datasets.",
          },
          filters: {
            type: "string",
            description: "JSON-stringified array of filter objects, " \
                         "e.g. '[{\"attribute\":\"...\",\"nodes\":[\"...\"]}]'. " \
                         "Sent to the API as a JSON string so GET and POST share one key-value format.",
          },
          annotations: {
            type: "string",
            description: "JSON-stringified array of annotation objects, " \
                         "e.g. '[{\"attribute\":\"...\",\"node\":\"...\"}]'. Omit or pass '[]' when none.",
          },
          queries: {
            type: "string",
            description: "JSON-stringified array of user IDs, " \
                         "e.g. '[\"ID1\",\"ID2\"]'. Pass '[]' when not mapping IDs.",
          },
        },
        required: %w[dataset filters]
      )

      def self.call(dataset:, filters:, annotations: nil, queries: "[]", server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        rows = ctx[:togodx].dataframe(
          dataset: dataset,
          filters: filters,
          annotations: annotations,
          queries: queries || "[]"
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
            description: "Preset from build_preset: its `preset` array, the whole { \"preset\": [...] } object, or a JSON string of either.",
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
        preset_data = ToolHelpers.normalize_preset(preset)

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

    class BuildShareLink < MCP::Tool
      tool_name "build_share_link"
      description "Build a shareable TogoDX/Human URL that opens the web UI with the given " \
                  "preset conditions pre-applied. Show the returned link in chat so the user " \
                  "can click through and verify the conditions in the UI."
      input_schema(
        properties: {
          preset: {
            description: "Preset from build_preset: its `preset` array, the whole { \"preset\": [...] } object, or a JSON string of either.",
            type: "array",
          },
        },
        required: ["preset"]
      )

      def self.call(preset:, server_context: nil)
        ToolHelpers.context!(server_context)
        # Normalize to the canonical preset array (unwrapping build_preset's
        # { "preset" => [...] } shape) so conditions= always holds the bare array.
        conditions_json = JSON.generate(ToolHelpers.normalize_preset(preset))
        base = Config.togodx_ui_url.chomp("/")
        # URL-encode the JSON so the UI can restore it via decodeURIComponent on a GET request.
        url = "#{base}/?conditions=#{ERB::Util.url_encode(conditions_json)}"

        ToolHelpers.json_response(
          {
            "url" => url,
            "conditions_json" => conditions_json,
            "instructions" => "Present this link to the user. Opening it loads the conditions " \
                              "directly into the TogoDX/Human UI for verification.",
          }
        )
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class RunPreset < MCP::Tool
      tool_name "run_preset"
      description "Run a preset end-to-end and return the final result table (same as the web UI). " \
                  "Aggregates matching IDs from the preset's dataset/filters/queries via /aggregate, " \
                  "then feeds those IDs back as queries to /dataframe together with the annotations."
      input_schema(
        properties: {
          preset: {
            description: "Preset from build_preset: its `preset` array, the whole { \"preset\": [...] } object, or a JSON string of either.",
            type: "array",
          },
        },
        required: ["preset"]
      )

      def self.call(preset:, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        preset_data = ToolHelpers.normalize_preset(preset)

        condition = PresetBuilder.new(catalog: ctx[:catalog]).condition_from_preset(preset_data)
        dataset = condition["dataset"]
        filters = condition["filters"] || []
        annotations = condition["annotations"]
        input_queries = condition["queries"] || []

        # Match the /aggregate requirement: dataset is required and at least one of
        # filters or queries must be a non-empty array.
        raise ArgumentError, "dataset is required" if dataset.to_s.empty?
        if Array(filters).empty? && Array(input_queries).empty?
          raise ArgumentError, "The preset must have a non-empty filters or queries array"
        end

        togodx = ctx[:togodx]
        filters_json = JSON.generate(filters)

        # Step 1: aggregate matching IDs (filters intersected with any user-supplied queries).
        ids = Array(
          togodx.aggregate(
            dataset: dataset,
            filters: filters_json,
            queries: JSON.generate(input_queries)
          )
        )

        # Step 2: feed the matched IDs back as queries to fetch the final dataframe rows.
        rows = togodx.dataframe(
          dataset: dataset,
          filters: filters_json,
          annotations: annotations ? JSON.generate(annotations) : nil,
          queries: JSON.generate(ids)
        )

        ToolHelpers.json_response(
          {
            "dataset" => dataset,
            "id_count" => ids.length,
            "row_count" => Array(rows).length,
            "rows" => rows,
          }
        )
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end
  end
end
