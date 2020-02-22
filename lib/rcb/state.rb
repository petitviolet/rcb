require 'rstructural'
require_relative './result'
require_relative './error'

module Rcb::State
  extend ADT

  Close = data :failure_count do
    def self.create(failure_count = 0)
      new(failure_count)
    end

    def run(config, &block)
      case try_call(&block)
      in Either::Right[result]
        Rcb::Result::Ok.new(self, result)
      in Either::Left[e]
        if config.max_failure_count > failure_count
          Rcb::Result::Ng.new(Close.create(failure_count + 1), e)
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
    def state(config)
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

