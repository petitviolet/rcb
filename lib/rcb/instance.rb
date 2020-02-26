require 'rstructural'
require_relative './state'
require_relative './state_store'
require_relative './configuration'
require_relative './error'

module Rcb
  class Instance
    attr_reader :config

    # @param config [Rcb::Config]
    def initialize(config, state_store: Rcb::StateStore::InMemory)
      @config = config
      @state_store = state_store
    end

    def run!(&block)
      result =
        case @state_store.get(config.tag)
        in State::Close => s
          s.run(config, &block)
        in State::Open => s
          s.run(config, &block)
        in s
          raise "Unknown state: #{s}"
        end

      case result
      in Result::Ok[state, result]
        @state_store.update(config.tag, state)
        return result
      in Result::Ng[state, error]
        @state_store.update(config.tag, state)
        raise error
      end
    end

    def state
      @state_store.get(config.tag).show_state(config)
    end
  end

end
