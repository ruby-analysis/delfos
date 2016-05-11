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
            request.basic_auth(Delfos.neo4j_username, Delfos.neo4j_password)
            request.content_type = 'application/json'

            request.body = <<-BODY.gsub(/^\s+/, "").chomp
              {"statements": [ { "statement": #{query.inspect} }]}
            BODY
          end
        end

        def uri
          @uri ||= URI.parse "#{Delfos.neo4j_host}/db/data/transaction/commit"
        end
      end
    end
  end
end



