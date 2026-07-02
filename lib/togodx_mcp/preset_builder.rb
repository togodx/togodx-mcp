# frozen_string_literal: true

require "json"

module TogodxMcp
  class PresetBuilder
    def initialize(catalog:)
      @catalog = catalog
    end

    def build(dataset:, filters:, annotations: nil, queries: nil)
      validate_dataset!(dataset)
      validate_filters!(filters)
      validate_annotations!(annotations) if annotations

      condition = {
        "dataset" => dataset,
        "filters" => normalize_filters(filters),
        "annotations" => if annotations && !annotations.empty?
                           normalize_annotations(annotations)
                         else
                           []
                         end,
        "queries" => Array(queries).map(&:to_s).reject(&:empty?),
      }

      [
        {
          "condition" => condition,
          "attributeSet" => @catalog.all_attribute_ids,
        },
      ]
    end

    def condition_from_preset(preset)
      entry = Array(preset).first
      raise ArgumentError, "Preset must contain one entry" unless entry

      entry.fetch("condition")
    end

    private

    def validate_dataset!(dataset)
      raise ArgumentError, "dataset is required" if dataset.to_s.empty?
    end

    def validate_filters!(filters)
      list = Array(filters)
      raise ArgumentError, "At least one filter is required" if list.empty?

      list.each do |filter|
        attribute = filter["attribute"] || filter[:attribute]
        nodes = filter["nodes"] || filter[:nodes]
        raise ArgumentError, "Filter attribute is required" if attribute.to_s.empty?
        raise ArgumentError, "Filter nodes are required for #{attribute}" if Array(nodes).empty?
        raise ArgumentError, "Unknown attribute: #{attribute}" unless @catalog.get(attribute)
      end
    end

    def validate_annotations!(annotations)
      Array(annotations).each do |annotation|
        attribute = annotation["attribute"] || annotation[:attribute]
        raise ArgumentError, "Annotation attribute is required" if attribute.to_s.empty?
        raise ArgumentError, "Unknown attribute: #{attribute}" unless @catalog.get(attribute)
      end
    end

    def normalize_filters(filters)
      Array(filters).map do |filter|
        {
          "attribute" => (filter["attribute"] || filter[:attribute]).to_s,
          "nodes" => Array(filter["nodes"] || filter[:nodes]).map(&:to_s),
        }
      end
    end

    def normalize_annotations(annotations)
      Array(annotations).map do |annotation|
        row = { "attribute" => (annotation["attribute"] || annotation[:attribute]).to_s }
        node = annotation["node"] || annotation[:node]
        row["node"] = node.to_s unless node.nil? || node.to_s.empty?
        row
      end
    end
  end
end
