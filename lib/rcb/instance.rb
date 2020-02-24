require 'rstructural'
require_relative './state'
require_relative './configuration'
require_relative './error'

module Rcb
  class Instance
    attr_reader :config

    # @param config [Rcb::Config]
    def initialize(config)
      @config = config
    end

    def run!(&block)
      result =
        case States.of(config.tag)
        in State::Close => s
          s.run(config, &block)
        in State::Open => s
          s.run(config, &block)
        in s
          raise "Unknown state: #{s}"
        end

      case result
      in Result::Ok[state, result]
        States.update(config.tag, state)
        return result
      in Result::Ng[state, error]
        States.update(config.tag, state)
        raise error
      end
    end

    def state
      States.show(config)
    end

  end

  private

    class States
      @states = {}

      def self.show(config)
        self.of(config.tag).state(config)
      end

      def self.of(tag)
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
