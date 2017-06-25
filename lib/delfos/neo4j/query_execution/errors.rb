# frozen_string_literal: true

require "net/http"

module Delfos
  module Neo4j
    module QueryExecution
      class ConnectionError < IOError
      end

      HTTP_ERRORS = [
        EOFError,
        Errno::EAGAIN,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::EINVAL,
        Errno::ENETDOWN,
        Errno::ENETUNREACH,
        Errno::ETIMEDOUT,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError,
        Net::ReadTimeout,
        SocketError,
        Timeout::Error,
        ConnectionError,
      ].freeze

      class InvalidQuery < IOError
        def initialize(errors, query, params)
          message = errors.map do |e|
            e.select { |k, _| %w(code message).include?(k) }
          end.join("\n")

          super [message, { query: query.to_s }, { params: params.to_s }].join("\n\n")
        end
      end
    end
  end
end
