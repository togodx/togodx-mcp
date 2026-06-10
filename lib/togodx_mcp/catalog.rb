# frozen_string_literal: true

require "json"
require "uri"

require_relative "config"
require_relative "http_client"

module TogodxMcp
  class Catalog
    attr_reader :categories, :attributes

    def self.load(url: Config.togodx_config_url)
      uri = URI.parse(url)
      http = HttpClient.new(base_url: "#{uri.scheme}://#{uri.host}")
      data = http.get(uri.request_uri)
      new(data)
    end

    def initialize(data)
      @categories = data.fetch("categories")
      @attributes = data.fetch("attributes")
      @attribute_index = @attributes.transform_keys(&:to_s)
      @all_attribute_ids = @categories.flat_map { |category| category.fetch("attributes") }.uniq
    end

    def all_attribute_ids
      @all_attribute_ids
    end

    def get(attribute_id)
      @attribute_index[attribute_id.to_s]
    end

    def list_categories
      @categories.map do |category|
        {
          "id" => category["id"],
          "label" => category["label"],
          "attributes" => category["attributes"],
        }
      end
    end

    def search(keywords, category: nil)
      terms = Array(keywords).flat_map { |keyword| keyword.to_s.downcase.split(/\s+/) }.reject(&:empty?)
      return [] if terms.empty?

      candidates = @attribute_index.map do |attribute_id, meta|
        next if category && !category_for(attribute_id)&.dig("id") == category.to_s

        score = score_attribute(attribute_id, meta, terms)
        next unless score.positive?

        {
          "attribute" => attribute_id,
          "label" => meta["label"],
          "description" => meta["description"],
          "dataset" => meta["dataset"],
          "datamodel" => meta["datamodel"],
          "category" => category_for(attribute_id)&.dig("id"),
          "score" => score,
        }
      end.compact

      candidates.sort_by { |row| -row["score"] }
    end

    private

    def category_for(attribute_id)
      @categories.find { |category| category["attributes"].include?(attribute_id) }
    end

    def score_attribute(attribute_id, meta, terms)
      haystack = [
        attribute_id,
        meta["label"],
        meta["description"],
        meta["dataset"],
      ].join(" ").downcase

      terms.sum do |term|
        if haystack.include?(term)
          haystack.start_with?(term) || attribute_id.include?(term) ? 3 : 1
        else
          0
        end
      end
    end
  end
end
