# frozen_string_literal: true
require "net/http"

module Delfos
  module Neo4j
    module QueryExecution
      HTTP_ERRORS = [
        EOFError,
        Errno::ECONNRESET,
        Errno::ECONNREFUSED,
        Errno::EINVAL,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError,
        Timeout::Error,
      ].freeze

      class InvalidQuery < IOError
        def initialize(errors, query, params)
          message = errors.map do |e|
            e.select { |k, _| %w(code message).include?(k) }
          end.join("\n")


          super [message, { query: query.to_s}, {params: params.to_s }].join("\n\n")
        end
      end

      class ConnectionError < IOError
      end
    end
  end
end
