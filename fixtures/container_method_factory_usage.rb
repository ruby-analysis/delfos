$:.unshift File.expand_path("../lib/delfos", File.dirname(__FILE__))
require "delfos"
require "method_trace/code_location"
require "method_trace/code_location/container_method_factory"

KLASS = Delfos::MethodTrace::CodeLocation::ContainerMethodFactory

def container_method
  KLASS.create(stack_offset: 4)
end

CONTAINER_METHOD_CONSTANT = container_method
