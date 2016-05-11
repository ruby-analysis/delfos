# frozen_string_literal: true
require "delfos"
require "json"
require "net/http"
require "uri"

module Delfos
  module Neo4j
    module QueryExecution
      class << self
        def execute(query, url=nil)
          result = response_for(query)
          result = JSON.parse result.body
          result["results"].first["data"].map{|r| r["row"]}
        end

        private

        def response_for(query)
          request = request_for(query)
          http = Net::HTTP.new(uri.host, uri.port)

          http.request(request)
        end

        def request_for(query)
          Net::HTTP::Post.new(uri.request_uri).tap do |request|
            request.basic_auth(username, password)
            request.content_type = 'application/json'

            request.body = <<-BODY.gsub(/^\s+/, "").chomp
              {"statements": [ { "statement": #{query.inspect} }]}
            BODY
          end
        end

        def uri
          @uri ||= URI.parse "#{server_url}/db/data/transaction/commit"
        end

        def server_url
          _, server_url, _ = Delfos.neo4j_config

          server_url
        end

        def username
          @username ||= options[:basic_auth][:username]
        end

        def password
          @password ||= options[:basic_auth][:password]
        end

        def options
          @options ||= Delfos.neo4j_config.last
        end
      end
    end
  end
end



