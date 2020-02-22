require_relative "./rcb/instance"
require_relative "./rcb/configuration"

module Rcb
  module ClassMethods
    def for(tag, max_failure_count: nil, reset_timeout_msec: nil)
      config = Rcb::Configurations.for(tag,
                                       max_failure_count: max_failure_count,
                                       reset_timeout_msec: reset_timeout_msec)
      Instance.new(config)
    end
  end

  extend ClassMethods
end
