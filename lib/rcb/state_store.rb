require_relative './state'
require_relative './configuration'

module Rcb
  class StateStore
    @states = {}

    def self.get(tag)
      @states[tag.to_sym] ||= State::Close.create
    end

    def self.update(tag, state)
      @states[tag] = state
    end

    def self.clear
      @states = {}
    end
  end
end
