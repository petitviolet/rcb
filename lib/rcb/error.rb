module Rcb
  class CircuitBreakerOpenError < RuntimeError
    def initialize(since)
      super(msg = "CircuitBreaker is open since #{since}")
    end
  end
end