# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module TogodxMcp
  class HttpClient
    class Error < StandardError
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        super(message)
        @status = status
        @body = body
      end
    end

    def initialize(base_url:, open_timeout: 10, read_timeout: 60)
      @base_url = base_url.chomp("/")
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def get(path, params: {})
      request(:get, path, params: params)
    end

    def post(path, body)
      request(:post, path, json: body)
    end

    private

    def request(method, path, params: nil, json: nil)
      uri = build_uri(path, params)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout

      req = method == :get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)
      req["Accept"] = "application/json"
      if json
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(json)
      end

      response = http.request(req)
      parse_response(response)
    end

    def build_uri(path, params)
      path = "/#{path}" unless path.start_with?("/")
      uri = URI.parse("#{@base_url}#{path}")
      unless params.nil? || params.empty?
        uri.query = URI.encode_www_form(params.compact)
      end
      uri
    end

    def parse_response(response)
      body = response.body.to_s
      parsed = body.empty? ? nil : JSON.parse(body)

      return parsed if response.is_a?(Net::HTTPSuccess)

      message = if parsed.is_a?(Hash) && parsed["errors"]
                  Array(parsed["errors"]).join(", ")
                else
                  "HTTP #{response.code}"
                end
      raise Error.new(message, status: response.code.to_i, body: body)
    rescue JSON::ParserError
      raise Error.new("HTTP #{response.code}: invalid JSON", status: response.code.to_i, body: body) unless response.is_a?(Net::HTTPSuccess)

      body
    end
  end
end
