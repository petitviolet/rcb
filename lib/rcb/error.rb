module Rcb
  class CircuitBreakerOpenError < RuntimeError
    def initialize(tag, since)
      super(msg = "CircuitBreaker for '#{tag}' is open since #{since}")
    end
  end
end