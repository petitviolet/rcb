require 'rstructural'
require_relative './result'
require_relative './error'

module Rcb::State
  extend ADT

  Close = data :failure_times do
    def self.create
      new([])
    end

    def run(config, now: Time.now.utc, &block)
      case try_call(&block)
      in Either::Right[result]
        Rcb::Result::Ok.new(self, result)
      in Either::Left[e]
        old_limit = now - (config.open_condition.window_msec / 1000.0)
        refreshed_failure_times = failure_times.filter { |ft| old_limit <= ft } + [now]
        if refreshed_failure_times.size < config.open_condition.max_failure_count
          Rcb::Result::Ng.new(Close.new(refreshed_failure_times), e)
        else
          Rcb::Result::Ng.new(Open.create, e)
        end
      end
    end
  end

  Open = data :since do
    def self.create
      new(Time.now.utc)
    end

    def run(config, now: Time.now.utc, &block)
      if half_open?(now, config.reset_timeout_msec)
        HalfOpen.run(&block)
      else
        Rcb::Result::Ng.new(self, Rcb::CircuitBreakerOpenError.new(config.tag, since))
      end
    end

    def half_open?(now = Time.now.utc, reset_timeout_msec)
      ((now - since) * 1000) >= reset_timeout_msec
    end
  end

  HalfOpen = const do
    # only executed from Open#run
    def run(&block)
      case try_call(&block)
      in Either::Right[result]
        Rcb::Result::Ok.new(Close.create, result)
      in Either::Left[e]
        Rcb::Result::Ng.new(Open.create, e)
      end
    end
  end

  interface do
    def show_state(config)
      case self
      in Open if self.half_open?(config.reset_timeout_msec)
        :half_open
      in Open
        :open
      in Close
        :close
      end
    end

    private

    def try_call(&block)
      result = block.call
      Either.right(result)
    rescue => e
      Either.left(e)
    end
  end
end

