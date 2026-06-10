# frozen_string_literal: true

require_relative "../config"
require_relative "../http_client"

module TogodxMcp
  module Client
    class Togoid
      def initialize(base_url: Config.togoid_base_url)
        @http = HttpClient.new(base_url: base_url)
      end

      def convert(ids:, route:)
        id_list = Array(ids).flat_map { |id| id.to_s.split(/[,\s]+/) }.reject(&:empty?)
        @http.get(
          "/convert",
          params: {
            "ids" => id_list.join(","),
            "route" => route,
            "format" => "json",
          }
        )
      end
    end
  end
end
