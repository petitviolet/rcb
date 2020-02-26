require "test_helper"

class CircuitBreakerTest < Minitest::Spec
  class CustomError < StandardError
  end

  before :each do
    Rcb::StateStore.clear
    Rcb::Configurations.clear
  end

  def test_configure
    Rcb.configure(:test) do |config|
      config.open_condition.max_failure_count 1
      config.open_condition.window_msec 300
      config.reset_timeout_msec 100
    end

    Rcb.configure(:test2) do |config|
      config.open_condition.max_failure_count 2
      config.open_condition.window_msec 600
      config.reset_timeout_msec 200
    end

    assert_equal Rcb.for(:test).config, Rcb::Config.new(:test, Rcb::OpenCondition.new(1, 300), 100)
    assert_equal Rcb.for(:test2).config, Rcb::Config.new(:test2, Rcb::OpenCondition.new(2, 600), 200)

    assert_equal Rcb.for(:test3).config, Rcb::Config.new(:test3, Rcb::OpenCondition::DEFAULT, 1000)
    assert_equal Rcb.for(:test3, open_condition: Rcb::OpenCondition.new(3, 900)).config,
                 Rcb::Config.new(:test3, Rcb::OpenCondition.new(3, 900), 1000)

    assert_equal Rcb.for(:test3, reset_timeout_msec: 300).config,
                 Rcb::Config.new(:test3, Rcb::OpenCondition::DEFAULT, 300)
  end

  def test_circuit_breaker_open_condition_max_failure_count
    Rcb.configure('example.com') do |config|
      config.open_condition(max_failure_count: 3, window_msec: 1000)
      config.reset_timeout_msec 2000
    end

    cb = Rcb.for('example.com')
    assert_equal cb.run! { 100 }, 100
    assert_equal cb.state, :close

    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :close

    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :close

    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :open
  end

  def test_circuit_breaker_open_condition_window_msec
    Rcb.configure('example.com') do |config|
      config.open_condition(max_failure_count: 2, window_msec: 100)
      config.reset_timeout_msec 2000
    end

    cb = Rcb.for('example.com')
    assert_equal cb.run! { 100 }, 100
    assert_equal cb.state, :close

    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :close

    sleep 0.1

    assert_equal cb.state, :close
    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :close

    sleep 0.1

    assert_equal cb.state, :close
    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :close
  end

  def test_circuit_breaker_reset_timeout
    Rcb.configure('example.com') do |config|
      config.open_condition(max_failure_count: 1, window_msec: 1000)
      config.reset_timeout_msec 200
    end
    cb = Rcb.for('example.com')
    assert_equal cb.run! { 100 }, 100
    assert_raises(CustomError) { cb.run! { raise CustomError } }
    assert_equal cb.state, :open
    sleep 0.1
    assert_equal cb.state, :open
    sleep 0.1
    assert_equal cb.state, :half_open
  end

  def test_multiple_circuit_breakers
    Rcb.configure('example.com') do |config|
      config.open_condition(max_failure_count: 1, window_msec: 1000)
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
