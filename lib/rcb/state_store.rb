require_relative './state'
require_relative './configuration'

module Rcb
  module StateStore
    class InMemory
      @states = {}

      def self.get(tag)
        @states[tag.to_sym]
      end

      def self.update(tag, state)
        @states[tag] = state
      end

      def self.clear
        @states = {}
      end
    end
  end
end
