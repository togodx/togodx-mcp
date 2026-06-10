# frozen_string_literal: true

require_relative "../tool_helpers"

module TogodxMcp
  module Tools
    class UsageGuide < MCP::Tool
      tool_name "togodx_usage_guide"
      description <<~DESC.strip
        Call this tool first every turn before other TogoDX tools.

        Workflow:
        1. Classify the user request: condition building, ID mapping, or result fetch.
        2. Use search_attributes to propose attribute candidates; confirm with the user.
        3. Resolve nodes with breakdown, suggest_nodes, or resolve_nodes. Never invent node IDs.
        4. Put narrowing criteria in filters and projection-only attributes in annotations.
        5. Convert unsupported IDs with convert_ids before putting them in queries.
        6. Build preset JSON with build_preset, preview with preview_aggregate, then get_dataframe.
        7. Export JSON with export_preset so the user can upload it in TogoDX UI.
      DESC

      input_schema(properties: {})

      GUIDE = <<~GUIDE
        # TogoDX MCP Usage Guide

        ## Goal
        Build explainable TogoDX/Human conditions as uploadable preset JSON and optionally fetch dataframe results.

        ## filters vs annotations
        - filters: conditions that narrow the result set (AND across filters, OR within nodes).
        - annotations: attributes shown in Projection without narrowing the set.

        ## Recommended flow
        1. search_attributes
        2. breakdown / suggest_nodes / resolve_nodes
        3. convert_ids (if user IDs are not TogoDX datasets)
        4. build_preset
        5. preview_aggregate
        6. get_dataframe
        7. export_preset

        ## Rules
        - Always ground node IDs in API responses.
        - Ask the user when multiple attributes or nodes are plausible.
        - Omit queries from preset JSON when no user ID list is provided.
        - attributeSet is fixed to all attributes from the catalog.
      GUIDE

      def self.call(server_context: nil)
        ToolHelpers.text_response(GUIDE)
      end
    end
  end
end
