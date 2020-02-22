require 'logger'

module Rcb
  Config = Struct.new(:tag, :max_failure_count, :reset_timeout_msec)do
    MAX_FAILURE_COUNT = 0.freeze
    RESET_TIMEOUT_MSEC = 0.freeze

    @logger = Logger.new($stderr)

    def self.create(tag, max_failure_count: nil, reset_timeout_msec: nil)
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

  def Rcb.configure(&block)
    c = Config.new.tap do |c|
      block.call(c)
      c.tag = c.tag.to_s.to_sym
    end.freeze

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