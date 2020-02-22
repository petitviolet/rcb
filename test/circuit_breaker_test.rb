require "test_helper"

class CircuitBreakerTest < Minitest::Spec
  class CustomError < StandardError
  end

  before :each do
    Rcb::States.clear
    Rcb::Configurations.clear
  end

  def test_circuit_breaker
    cb = Rcb.for(:test, max_failure_count: 1, reset_timeout_msec: 200)
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
