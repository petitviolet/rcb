require "test_helper"

class CircuitBreakerTest < Minitest::Test
  class CustomError < StandardError
  end

  def test_circuit_breaker
    cb = Rcb.build(:test, max_failure_counts: 1, reset_timeout_msec: 200)
    cb2 = Rcb.build(:test, max_failure_counts: 3, reset_timeout_msec: 500)
    assert_equal cb.state, :close
    assert_equal cb.run! { 100 }, 100
    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :close
    assert_raises(CustomError) { cb.run! { raise CustomError } }

    assert_equal cb.state, :open
    assert_raises(Rcb::CircuitBreakerOpenError) { cb.run! { raise CustomError } }

    sleep 0.1

    assert_equal cb.state, :open
    assert_raises(Rcb::CircuitBreakerOpenError) { cb.run! { raise CustomError } }

    sleep 0.1

    assert_equal cb.state, :half_open
    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :open

    sleep 0.2

    assert_equal cb.state, :half_open
    assert_equal cb.run! { 100 }, 100
    assert_equal cb.state, :close
  end
end
