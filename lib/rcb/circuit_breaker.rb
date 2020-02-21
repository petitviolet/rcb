require 'byebug'
require 'rstructural'

module Rcb

  class CircuitBreakerOpenError < RuntimeError
    def initialize(since)
      super(msg = "CircuitBreaker is open since #{since}")
    end
  end

  module Result
    extend ADT

    Ok = data :new_state, :result
    Ng = data :new_state, :error
  end

  module State
    extend ADT

    Close = data :failure_count do
      def self.create(failure_count = 0)
        new(failure_count)
      end

      def run(max_failure_count, &block)
        case try_call(&block)
        in Either::Right[result]
          Result::Ok.new(self, result)
        in Either::Left[e]
          if max_failure_count > failure_count
            Result::Ng.new(Close.create(failure_count + 1), e)
          else
            Result::Ng.new(Open.create, e)
          end
        end
      end
    end

    Open = data :since do
      def self.create
        new(Time.now.utc)
      end

      def run(reset_timeout_msec, now: Time.now.utc, &block)
        if half_open?(now, reset_timeout_msec)
          HalfOpen.run(&block)
        else
          Result::Ng.new(self, CircuitBreakerOpenError.new(since))
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
          Result::Ok.new(Close.create, result)
        in Either::Left[e]
          Result::Ng.new(Open.create, e)
        end
      end
    end

    interface do
      def state(reset_timeout)
        case self
        in Open if self.half_open?(reset_timeout)
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

  def Rcb.build(tag, max_failure_counts:, reset_timeout_msec:)
    Instance.new(
      tag,
      max_failure_counts: max_failure_counts,
      reset_timeout_msec: reset_timeout_msec,
    )
  end

  class Instance
    def initialize(tag, max_failure_counts:, reset_timeout_msec:)
      @tag = tag.to_sym
      @state = State::Close.create
      @max_failure_counts = max_failure_counts
      @reset_timeout_msec = reset_timeout_msec
    end

    def run!(timeout: nil, &block)
      result =
        case @state
        in State::Close
          @state.run(@max_failure_counts, &block)
        in State::Open
          @state.run(@reset_timeout_msec, &block)
        else
          raise "Unknown state: #{@state}"
        end

      case result
      in Result::Ok[state, result]
        @state = state
        return result
      in Result::Ng[state, error]
        @state = state
        raise error
      end
    end

    def state
      @state.state(@reset_timeout_msec)
    end
  end

end