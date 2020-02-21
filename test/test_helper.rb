$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rcb"
require_relative "../lib/rcb/circuit_breaker"

require "minitest/autorun"
