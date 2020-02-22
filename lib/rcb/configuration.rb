require 'logger'

module Rcb
  Config = Struct.new(:tag, :max_failure_count, :reset_timeout_msec)do
    MAX_FAILURE_COUNT = 0.freeze
    RESET_TIMEOUT_MSEC = 0.freeze

    @logger = Logger.new($stderr)

    def self.create(tag, max_failure_count: nil, reset_timeout_msec: nil)
      raise 'Rcb tag must not be nil' if tag.nil?

      if max_failure_count.nil? && reset_timeout_msec.nil?
        @logger.warn("Rcb for '#{tag}' is not configured!")
      end

      Config.new(
        tag.to_s.to_sym,
        max_failure_count || MAX_FAILURE_COUNT,
        reset_timeout_msec || RESET_TIMEOUT_MSEC
      )
    end
  end

  class ConfigBuilder
    def initialize(tag)
      @tag = tag
      @max_failure_count = nil
      @reset_timeout_msec = nil
    end

    def max_failure_count(num)
      @max_failure_count = num
    end

    def reset_timeout_msec(msec)
      @reset_timeout_msec = msec
    end

    def build
      Config.create(
        @tag,
        max_failure_count:@max_failure_count,
        reset_timeout_msec: @reset_timeout_msec
      ).freeze
    end
  end

  def Rcb.configure(tag, &block)
    c = ConfigBuilder.new(tag.to_s.to_sym)
          .tap { |cb| block.call(cb) }
          .build

    Configurations.add(c)
  end

  module Configurations
    @configs = {}

    def self.for(tag, max_failure_count: nil, reset_timeout_msec: nil)
      @configs[tag.to_s.to_sym] || Config.create(tag,
                                                 max_failure_count: max_failure_count,
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