require 'rstructural'

module Rcb::Result
  extend ADT

  Ok = data :new_state, :result
  Ng = data :new_state, :error
end

