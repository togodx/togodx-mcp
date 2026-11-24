# frozen_string_literal: true

module TogodxMcp
  class NodeResolver
    # TogoDX/Human is about humans, but ontologies such as Mondo also carry
    # veterinary terms (e.g. "canine gastrointestinal stromal tumor, ... dog"),
    # so those labels rank below human ones.
    NON_HUMAN_PATTERN = /\b(non-human|animal|canine|feline|bovine|equine|porcine|ovine|caprine|avian|murine|
                           dog|cat|horse|cattle|pig|sheep|goat|chicken|mouse|rat)\b/ix

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

      # Walking the breakdown tree is slow on large ontologies (Mondo timed
      # out), so only fall back to it when suggest found nothing.
      if matches.empty?
        begin
          matches.concat(match_in_breakdown(attribute, term))
        rescue HttpClient::Error => e
          errors << "breakdown: #{e.message}"
        end
      end

      deduped = rank(matches.uniq { |row| row["node"] }, term)
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

    # Best match first: exact label/ID, then prefix, then whole-word, then
    # substring; non-human labels after human ones (unless the term asks for
    # them); shorter labels first.
    # sort_by is not stable, so the original position breaks ties.
    def rank(rows, term)
      normalized = term.downcase.strip
      word = /\b#{Regexp.escape(normalized)}\b/
      # A term that itself names an animal (e.g. "canine GIST") wants those labels.
      penalize_non_human = !normalized.match?(NON_HUMAN_PATTERN)
      rows.each_with_index.sort_by do |row, i|
        label = row["label"].to_s.downcase.strip
        match =
          if label == normalized || row["node"].to_s.downcase == normalized then 0
          elsif label.start_with?(normalized) then 1
          elsif label.match?(word) then 2
          else 3
          end
        non_human = penalize_non_human && label.match?(NON_HUMAN_PATTERN) ? 1 : 0
        [non_human, match, label.length, i]
      end.map(&:first)
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
