require 'rstructural'

module Rcb
  module Result
    extend ADT

    Ok = data :new_state, :result
    Ng = data :new_state, :error
  end
end
