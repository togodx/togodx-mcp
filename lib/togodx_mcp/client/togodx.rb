# frozen_string_literal: true

require_relative "../config"
require_relative "../http_client"

module TogodxMcp
  module Client
    class Togodx
      def initialize(base_url: Config.togodx_base_url)
        @http = HttpClient.new(base_url: base_url)
      end

      def breakdown(attribute, node: nil, hierarchy: nil, order: nil)
        params = {}
        params["node"] = node if node
        params["hierarchy"] = "true" if hierarchy
        params["order"] = order if order
        @http.get("/breakdown/#{attribute}", params: params)
      end

      def suggest(attribute, term)
        @http.get("/suggest/#{attribute}", params: { "term" => term })
      end

      def locate(attribute, dataset:, queries:, node: nil)
        body = { "dataset" => dataset, "queries" => queries }
        body["node"] = node if node
        @http.post("/locate/#{attribute}", body)
      end

      def aggregate(dataset:, filters:, queries: nil)
        body = { "dataset" => dataset, "filters" => filters }
        body["queries"] = queries if queries
        @http.post("/aggregate", body)
      end

      def dataframe(dataset:, filters:, annotations: nil, queries: "[]")
        body = {
          "dataset" => dataset,
          "filters" => filters,
          "queries" => queries,
        }
        body["annotations"] = annotations if annotations
        @http.post("/dataframe", body)
      end
    end
  end
end
