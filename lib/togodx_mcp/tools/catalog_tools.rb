# frozen_string_literal: true

require_relative "../tool_helpers"

module TogodxMcp
  module Tools
    class ListCategories < MCP::Tool
      tool_name "list_categories"
      description "List TogoDX/Human categories and their attribute IDs."
      input_schema(properties: {})

      def self.call(server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        ToolHelpers.json_response(ctx[:catalog].list_categories)
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class GetAttribute < MCP::Tool
      tool_name "get_attribute"
      description "Get metadata for one TogoDX attribute."
      input_schema(
        properties: {
          attribute: { type: "string", description: "Attribute ID, e.g. gene_specific_expression_in_tissues_hpa" },
        },
        required: ["attribute"]
      )

      def self.call(attribute:, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        meta = ctx[:catalog].get(attribute)
        raise ArgumentError, "Unknown attribute: #{attribute}" unless meta

        ToolHelpers.json_response(meta.merge("attribute" => attribute))
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end

    class SearchAttributes < MCP::Tool
      tool_name "search_attributes"
      description "Search TogoDX attributes by keywords in label, description, or attribute ID."
      input_schema(
        properties: {
          keywords: {
            type: "array",
            items: { type: "string" },
            description: "Keywords such as tissue, membrane, interaction",
          },
          category: {
            type: "string",
            description: "Optional category id: gene, protein, structure, interaction, compound, glycan, disease, variant",
          },
        },
        required: ["keywords"]
      )

      def self.call(keywords:, category: nil, server_context: nil)
        ctx = ToolHelpers.context!(server_context)
        results = ctx[:catalog].search(keywords, category: category)
        ToolHelpers.json_response({ "results" => results })
      rescue StandardError => e
        ToolHelpers.error_response(e)
      end
    end
  end
end
