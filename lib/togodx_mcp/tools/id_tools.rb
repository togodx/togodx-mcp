# frozen_string_literal: true

require_relative "../tool_helpers"

module TogodxMcp
  module Tools
    class ConvertIds < MCP::Tool
      tool_name "convert_ids"
      description "Convert identifiers to a TogoDX-compatible dataset using the TogoID /convert API."
      input_schema(
        properties: {
          ids: {
            anyOf: [
              { type: "string" },
              { type: "array", items: { type: "string" } },
            ],
            description: "Source IDs as array or comma-separated string.",
          },
          route: {
            type: "string",
            description: "Conversion route such as ncbigene,ensembl_gene or hgnc,uniprot",
          },
        },
        required: %w[ids route]
      )

      def self.call(ids:, route:, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        result = ctx[:togoid].convert(ids: ids, route: route)
        ToolHelpers.json_response(result)
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class LocateIds < MCP::Tool
      tool_name "locate_ids"
      description "Map user IDs to breakdown nodes for one attribute (Map your IDs)."
      input_schema(
        properties: {
          attribute: { type: "string" },
          dataset: { type: "string", description: "Target dataset such as ensembl_gene or uniprot" },
          queries: {
            type: "string",
            description: "JSON-stringified array of user-provided IDs in the target dataset, " \
                         "e.g. '[\"ID1\",\"ID2\"]'. " \
                         "Sent to the API as a JSON string so GET and POST share one key-value format.",
          },
          node: { type: "string", description: "Optional parent node for hierarchical attributes." },
        },
        required: %w[attribute dataset queries]
      )

      def self.call(attribute:, dataset:, queries:, node: nil, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        result = ctx[:togodx].locate(
          attribute,
          dataset: dataset,
          queries: queries,
          node: node
        )
        ToolHelpers.json_response(result)
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end
  end
end
