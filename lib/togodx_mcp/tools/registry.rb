# frozen_string_literal: true

require_relative "guide"
require_relative "catalog_tools"
require_relative "node_tools"
require_relative "id_tools"
require_relative "condition_tools"

module TogodxMcp
  module Tools
    module Registry
      module_function

      def all
        [
          UsageGuide,
          ListCategories,
          GetAttribute,
          SearchAttributes,
          Breakdown,
          SuggestNodes,
          ResolveNodes,
          ConvertIds,
          LocateIds,
          PreviewAggregate,
          BuildPreset,
          GetDataframe,
          ExportPreset,
          BuildShareLink,
          RunPreset,
        ]
      end
    end
  end
end
