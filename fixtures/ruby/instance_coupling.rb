# frozen_string_literal: true
class EfferentCoupling
  def instance_coupling(some_parameter)
    some_parameter.this_message
    some_parameter.that_message
    some_parameter.tons_more
  end

  def more_instance_coupling(some_parameter, another_parameter)
    some_parameter.this_message
    some_parameter.another_message
    some_parameter.yet_more
    some_parameter.here_we_go

    another_parameter.message
    another_parameter.second_message
  end
end
