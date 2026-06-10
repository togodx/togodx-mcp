# frozen_string_literal: true

module TogodxMcp
  class NodeResolver
    def initialize(togodx:, catalog:)
      @togodx = togodx
      @catalog = catalog
    end

    def resolve(attribute, terms)
      meta = @catalog.get(attribute)
      raise ArgumentError, "Unknown attribute: #{attribute}" unless meta

      Array(terms).map do |term|
        resolve_term(attribute, meta, term.to_s)
      end
    end

    private

    def resolve_term(attribute, meta, term)
      matches = []
      errors = []

      if meta["datamodel"] == "classification" && term.length >= 3
        begin
          suggest = @togodx.suggest(attribute, term)
          matches.concat(Array(suggest["results"]).map { |row| match_row(row, source: "suggest") })
        rescue HttpClient::Error => e
          errors << "suggest: #{e.message}"
        end
      end

      begin
        breakdown_matches = match_in_breakdown(attribute, term)
        matches.concat(breakdown_matches)
      rescue HttpClient::Error => e
        errors << "breakdown: #{e.message}"
      end

      deduped = matches.uniq { |row| row["node"] }
      {
        "term" => term,
        "matches" => deduped,
        "errors" => errors,
        "recommended" => deduped.first,
      }
    end

    def match_in_breakdown(attribute, term, node: nil, depth: 0)
      return [] if depth > 4

      rows = @togodx.breakdown(attribute, node: node)
      rows = Array(rows)
      normalized = term.downcase
      direct = rows.filter_map do |row|
        label = row["label"].to_s
        node_id = row["node"].to_s
        next unless label.downcase.include?(normalized) || node_id.downcase == normalized

        match_row(row, source: "breakdown")
      end

      return direct if direct.any?

      rows.flat_map do |row|
        next [] if row["tip"]

        match_in_breakdown(attribute, term, node: row["node"], depth: depth + 1)
      end
    end

    def match_row(row, source:)
      {
        "node" => row["node"],
        "label" => row["label"],
        "source" => source,
      }
    end
  end
end
