# frozen_string_literal: true

require_relative "../tool_helpers"

module TogodxMcp
  module Tools
    class UsageGuide < MCP::Tool
      tool_name "togodx_usage_guide"
      description <<~DESC.strip
        Call this tool first every turn before other TogoDX tools.

        TogoDX/Human is a one-stop way to explore and extract human life-science
        information (gene expression, localization, interactions, compounds,
        disease, variants, and more) from natural language, then share the view
        with people through the web UI or hand the results back to the LLM to
        interpret.

        Workflow:
        1. Classify the request: exploration/extraction, ID mapping, or result fetch.
        2. Use search_attributes to propose attribute candidates; confirm with the user.
        3. Ground node IDs with breakdown, suggest_nodes, or resolve_nodes. Never invent IDs.
        4. Put narrowing criteria in filters and projection-only attributes in annotations.
        5. Convert or map user-provided IDs with convert_ids / locate_ids.
        6. Build the preset with build_preset, then preview_aggregate to check the count.
        7. run_preset to fetch the final result table (same as the web UI) for interpretation.
        8. Always also call build_share_link and give the user the URL so they can open the
           same view in the web UI; offer export_preset when they want an uploadable file.
      DESC

      input_schema(properties: {})

      GUIDE = <<~GUIDE
        # TogoDX MCP Usage Guide

        ## What this server does
        Explore and extract human life-science information in TogoDX/Human directly
        from natural language, in one stop. Coverage spans 8 categories (gene,
        protein, structure, interaction, compound, glycan, disease, variant) and
        their attributes: gene expression, subcellular localization, molecular
        interactions, drug/compound data, disease and variant associations, and more.

        The result can be used three ways:
        - Return the result table to the LLM so it can interpret/summarize for the user.
        - build_share_link: a URL that opens the same view in the web UI to share with people.
        - export_preset: a JSON file the user can upload to the web UI (Conditions JSON).

        ## filters vs annotations
        - filters: conditions that narrow the result set (AND across filters, OR within nodes).
        - annotations: attributes shown as Projection columns without narrowing the set.

        ## Choosing dataset
        - dataset is the primary-key dataset the result rows are keyed on (one per condition),
          e.g. uniprot for a list of proteins or ensembl_gene for a list of genes.
        - Pick it by what the user wants listed. Each attribute reports its own dataset in the
          search_attributes / get_attribute output; use that as the hint.
        - filters and annotations may mix attributes from other datasets; TogoDX bridges them,
          so the condition dataset need not match every attribute's dataset.

        ## Tools
        Discovery
        - list_categories: list categories and their attribute IDs.
        - get_attribute: metadata for one attribute.
        - search_attributes: find attributes by keyword.

        Grounding node IDs (never invent them)
        - breakdown: list an attribute's nodes; drill down the hierarchy with node.
        - suggest_nodes: keyword search within a classification attribute (term >= 3 chars).
        - resolve_nodes: map natural-language terms (e.g. "Lung") to node IDs.

        User-provided IDs
        - convert_ids: convert external IDs to a TogoDX dataset via TogoID.
        - locate_ids: map user IDs onto an attribute's nodes.

        Condition building, results, and sharing
        - build_preset: assemble the preset JSON (filters/annotations/queries as NATIVE arrays).
        - preview_aggregate: quick match count for a condition.
        - run_preset: run a preset end-to-end (aggregate matched IDs -> dataframe) and
          return the final result table, same as the web UI. Use this to get results
          for the LLM to interpret.
        - get_dataframe: fetch the result table for a raw dataset/filters condition.
        - build_share_link: build a URL that opens the conditions in the web UI.
        - export_preset: write the preset JSON to a file with upload instructions.

        ## Recommended flow
        1. search_attributes (confirm candidates with the user)
        2. breakdown / suggest_nodes / resolve_nodes to ground node IDs
        3. convert_ids / locate_ids if the user brings their own IDs
        4. build_preset
        5. preview_aggregate (sanity-check the count)
        6. run_preset to get the final result table for the LLM to interpret
        7. Always also call build_share_link and present the URL so the user can open the
           same conditions in the web UI; offer export_preset for an uploadable JSON file

        ## Value formats (important)
        - build_preset takes filters/annotations/queries as NATIVE JSON arrays/objects.
        - preview_aggregate, get_dataframe, locate_ids take filters/annotations/queries
          as JSON-STRINGIFIED strings, e.g. filters = [{"attribute":"...","nodes":["..."]}]
          serialized to a string. This keeps one key-value format for GET and POST.
        - preview_aggregate (and run_preset internally) require a dataset plus at least
          one non-empty array of filters or queries.

        ## Rules
        - Always ground node IDs in API responses; never invent them.
        - Ask the user when multiple attributes or nodes are plausible.
        - Whenever a preset is ready, present a build_share_link URL to the user so they can
          open and verify the same view in the TogoDX/Human web UI, in addition to any
          results you fetched. Fetching results and pointing to the web UI are complementary.
        - Omit queries from the preset when no user ID list is provided.
        - attributeSet is fixed to all attributes from the catalog.
      GUIDE

      def self.call(server_context: nil)
        ToolHelpers.text_response(GUIDE)
      end
    end
  end
end
