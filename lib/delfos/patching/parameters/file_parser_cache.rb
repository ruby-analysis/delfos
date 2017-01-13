# frozen_string_literal: true
require "Forwardable" unless defined? Forwardable

module Delfos
  module Patching
    module Parameters
      class FileParserCache
        class << self
          extend Forwardable

          def_delegators :instance, :for

          def reset!
            @instance = nil
          end

          def instance
            @instance ||= new
          end
        end

        def initialize
          @cached_sexpressions = {}
        end

        def for(filename, &block)
          get(filename) || set(filename, yield)
        end

        def set(filename, contents)
          @cached_sexpressions[filename] = contents
        end

        def get(filename)
          @cached_sexpressions[filename]
        end
      end
    end
  end
end
