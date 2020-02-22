require "test_helper"

class CircuitBreakerTest < Minitest::Spec
  class CustomError < StandardError
  end

  before :each do
    Rcb::States.clear
    Rcb::Configurations.clear
  end

  def test_configure
    Rcb.configure(:test) do |config|
      config.max_failure_count 1
      config.reset_timeout_msec 100
    end

    Rcb.configure(:test2) do |config|
      config.max_failure_count 2
      config.reset_timeout_msec 200
    end

    assert_equal Rcb.for(:test).config, Rcb::Config.new(:test, 1, 100)
    assert_equal Rcb.for(:test2).config, Rcb::Config.new(:test2, 2, 200)

    assert_equal Rcb.for(:test3).config, Rcb::Config.new(:test3, 0, 0)
    assert_equal Rcb.for(:test3, max_failure_count: 3).config, Rcb::Config.new(:test3, 3, 0)
    assert_equal Rcb.for(:test3, reset_timeout_msec: 300).config, Rcb::Config.new(:test3, 0, 300)
  end

  def test_circuit_breaker
    Rcb.configure('example.com') do |config|
      config.max_failure_count 1
      config.reset_timeout_msec 200
    end

    cb = Rcb.for('example.com')
    cb2 = Rcb.for('example.com')
    cb3 = Rcb.for('other.example.com')

    assert_equal cb.state, :close
    assert_equal cb2.state, :close
    assert_equal cb3.state, :close
    assert_equal cb.run! { 100 }, 100
    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :close
    assert_equal cb2.state, :close
    assert_equal cb3.state, :close
    assert_raises(CustomError) { cb.run! { raise CustomError } }

    assert_equal cb.state, :open
    assert_equal cb2.state, :open
    assert_equal cb3.state, :close
    assert_raises(Rcb::CircuitBreakerOpenError) { cb.run! { raise CustomError } }

    sleep 0.1

    assert_equal cb.state, :open
    assert_equal cb2.state, :open
    assert_equal cb3.state, :close
    assert_raises(Rcb::CircuitBreakerOpenError) { cb.run! { raise CustomError } }

    sleep 0.1

    assert_equal cb.state, :half_open
    assert_equal cb2.state, :half_open
    assert_equal cb3.state, :close
    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :open
    assert_equal cb2.state, :open
    assert_equal cb3.state, :close

    sleep 0.2

    assert_equal cb.state, :half_open
    assert_equal cb2.state, :half_open
    assert_equal cb3.state, :close
    assert_equal cb.run! { 100 }, 100
    assert_equal cb.state, :close
    assert_equal cb2.state, :close
    assert_equal cb3.state, :close
  end

end
