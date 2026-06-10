# frozen_string_literal: true

require_relative "../tool_helpers"

module TogodxMcp
  module Tools
    class Breakdown < MCP::Tool
      tool_name "breakdown"
      description "Get breakdown nodes for a TogoDX attribute. Use node to drill down the hierarchy."
      input_schema(
        properties: {
          attribute: { type: "string" },
          node: { type: "string", description: "Parent node ID. Omit for top-level nodes." },
          hierarchy: { type: "boolean", description: "Return parents and children for DAG view." },
          order: { type: "string", description: "id_asc, numerical_desc, alphabetical_asc, etc." },
        },
        required: ["attribute"]
      )

      def self.call(attribute:, node: nil, hierarchy: nil, order: nil, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        result = ctx[:togodx].breakdown(attribute, node: node, hierarchy: hierarchy, order: order)
        ToolHelpers.json_response(result)
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class SuggestNodes < MCP::Tool
      tool_name "suggest_nodes"
      description "Keyword search for classification attribute nodes. term must be at least 3 characters."
      input_schema(
        properties: {
          attribute: { type: "string" },
          term: { type: "string", description: "Search term with at least 3 characters." },
        },
        required: %w[attribute term]
      )

      def self.call(attribute:, term:, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        raise ArgumentError, "term must be at least 3 characters" if term.to_s.length < 3

        result = ctx[:togodx].suggest(attribute, term)
        ToolHelpers.json_response(result)
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class ResolveNodes < MCP::Tool
      tool_name "resolve_nodes"
      description "Resolve natural-language terms to TogoDX node IDs using suggest and breakdown label matching."
      input_schema(
        properties: {
          attribute: { type: "string" },
          terms: {
            type: "array",
            items: { type: "string" },
            description: "Terms such as Lung, intestine, plasma membrane",
          },
        },
        required: %w[attribute terms]
      )

      def self.call(attribute:, terms:, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        resolver = NodeResolver.new(togodx: ctx[:togodx], catalog: ctx[:catalog])
        ToolHelpers.json_response({ "results" => resolver.resolve(attribute, terms) })
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end
  end
end
