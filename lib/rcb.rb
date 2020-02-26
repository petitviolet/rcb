require_relative "./rcb/instance"
require_relative "./rcb/configuration"

module Rcb
  module ClassMethods
    def for(tag, state_store: nil, open_condition: nil, reset_timeout_msec: nil)
      config = Rcb::Configurations.for(tag,
                                       open_condition: open_condition,
                                       reset_timeout_msec: reset_timeout_msec)
      Instance.new(config, state_store: state_store)
    end
  end

  extend ClassMethods
end
