# frozen_string_literal: true

require 'logger'
require 'rstructural'

module Rcb
  OpenCondition = Rstruct.new(:max_failure_count, :window_msec) do
    self::DEFAULT = new(3, 1000).freeze
  end

  Config = Rstruct.new(:tag, :open_condition, :reset_timeout_msec) do
    self::RESET_TIMEOUT_MSEC = 1000.freeze

    @logger = Logger.new($stderr)

    def self.create(tag, open_condition: nil, reset_timeout_msec: nil)
      raise 'Rcb tag must not be nil' if tag.nil?

      if open_condition.nil? && reset_timeout_msec.nil?
        @logger.warn("Rcb for '#{tag}' is not configured!")
      end

      Config.new(
        tag.to_s.to_sym,
        open_condition || OpenCondition::DEFAULT,
        reset_timeout_msec || Config::RESET_TIMEOUT_MSEC
      )
    end
  end

  module DSL
    class OpenConditionBuilder
      def initialize
        @max_failure_count = nil
        @window_msec = nil
      end

      def max_failure_count(count)
        @max_failure_count = count
      end

      def window_msec(msec)
        @window_msec = msec
      end

      def build
        Rcb::OpenCondition.new(@max_failure_count, @window_msec)
      end
    end

    class ConfigBuilder
      def initialize(tag)
        @tag = tag
        @open_condition_builder = OpenConditionBuilder.new
        @reset_timeout_msec = nil
      end

      def open_condition(hash = nil)
        if hash
          @open_condition_builder.max_failure_count hash[:max_failure_count]
          @open_condition_builder.window_msec hash[:window_msec]
        else
          @open_condition_builder
        end
      end

      def reset_timeout_msec(msec)
        @reset_timeout_msec = msec
      end

      def build
        Rcb::Config.create(
          @tag,
          open_condition: @open_condition_builder.build,
          reset_timeout_msec: @reset_timeout_msec
        ).freeze
      end
    end
  end

  def Rcb.configure(tag, &block)
    c = DSL::ConfigBuilder.new(tag.to_s.to_sym)
          .tap { |cb| block.call(cb) }
          .build

    Configurations.add(c)
  end

  module Configurations
    @configs = {}

    def self.for(tag, open_condition: nil, reset_timeout_msec: nil)
      @configs[tag.to_s.to_sym] || Config.create(tag,
                                                 open_condition: open_condition,
                                                 reset_timeout_msec: reset_timeout_msec)
    end

    def self.add(config)
      # return if @configs.include?(config.tag)
      # overwrite
      @configs[config.tag] = config
    end

    def self.clear
      @configs = {}
    end
  end

end
