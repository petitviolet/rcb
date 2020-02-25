# Rcb - Ruby Circuit Breaker

[![rcb](https://badge.fury.io/rb/rcb.svg)](https://badge.fury.io/rb/rcb)
[![Actions Status](https://github.com/petitviolet/rcb/workflows/test/badge.svg)](https://github.com/petitviolet/rcb/actions)

[Circuit Breaker](https://martinfowler.com/bliki/CircuitBreaker.html) implementation for/by Ruby.  
CircuitBreaker is a great pattern to build robust system consists of bunch of microservices.

- Close
    - An operational state
- Open
    - A not operational state
- Half Open
    - On the way of it's state to Close from Open.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rcb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rcb

## Usage

### Import

To use rcb, insert this line:

```ruby
require 'rcb'
```

### Configuration

Add configuration with specifying `tag` like:

```ruby
Rcb.configure('fooo.com') do |config|
    config.open_condition.max_failure_count 1
    config.open_condition.window_msec 1000
    config.reset_timeout_msec 100
end

Rcb.configure('hoge.com') do |config|
    config.open_condition.max_failure_count 3
    config.open_condition.window_msec 3000
    config.reset_timeout_msec 300
end
```

These configurations are for both 'fooo.com' and 'hoge.com'.

- `open_condition`: a condition to decide whether trip to open from close
    - `max_failure_count`: a threshold for execution failures. 
        - if the breaker reaches the given `max_failure_count`, enters Open state from Close 
    - `window_msec`: a window time(milliseconds) for failures
        - if the breaker catched failures more than `window_msec` before, they are discarded
- `reset_timeout_msec`: milliseconds to wait for next try
    - after the given `reset_timeout_msec`, the circuit breaker enters a Half-Open state from Open

### Apply circuit breaker to executions

Pass a block to a method `Rcb::Instance#run!` to apply circuit-breaker to a execution.

```ruby
Rcb.for('example.com').run! do # pass a block
    if rand(2) == 0
        raise 'fail!'
    else
        true
    end
end
```

You can see more example in [tests](./test).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/petitviolet/rcb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/petitviolet/rcb/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rcb project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/petitviolet/rcb/blob/master/CODE_OF_CONDUCT.md).
