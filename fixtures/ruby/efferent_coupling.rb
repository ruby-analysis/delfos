# frozen_string_literal: true
require_relative "this"

class EfferentCoupling
  def lots_of_coupling
    This.send_message
    That.send_message
    SomeOther.send_message
    SomeOther.send_message
    SomeOther.send_message
    SoMuchCoupling.found_in_here
    HereIsSomeMore.for_good_measure
  end
end
