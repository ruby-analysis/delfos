# This file is both a fixture and part of the spec definition:
#
# The ContainerMethodFactory uses binding.of_caller
# So we call it from within a directory in Delfos.application_directories
# i.e. 'fixtures'
#
# That is: if we called it from our specs, it wouldn't get picked up.
# OR if we analyse our test suite we enter the seventh level of hell.
#
# We also need to have access to the test results, so we assign them to
# constants in this file to check the values from our specs
#
# And to prevent polluting the global namespace everything sits under
# DelfoSpecs
#
# Sorry for the (probably unavoidable) complexity!
$:.unshift File.expand_path("../lib/delfos", File.dirname(__FILE__))

require "delfos/method_trace/code_location/container_method_factory"

module DelfosSpecs

  # >>>>>>>>>>>>>>
  # Fixtures start
  class SomeClass

    LINE_DEFINITION_RESULT = __LINE__ + 1
    def self.container_method(offset)
      CLASS_UNDER_TEST.create(stack_offset: offset)
    end
  end

  class SubClass < SomeClass

    LINE_DEFINITION_RESULT = __LINE__ + 1
    def self.container_method(offset)
      super(offset)
    end
  end
  # Fixtures finish
  # <<<<<<<<<<<<<<<<




  # >>>>>>>>>>>>>>
  # Spec setup start
  CLASS_UNDER_TEST         = ::Delfos::MethodTrace::CodeLocation::ContainerMethodFactory
  OFFSET = 4 # methods called are .create, #create, #file, #eval_in_caller
  # Spec setup finish
  # <<<<<<<<<<<<<<<<




  # >>>>>>>>>>>>>>
  # Spec results start
  NORMAL_CLASS_TEST_RESULT = SomeClass.container_method(OFFSET)
  SUB_CLASS_TEST_RESULT    = SubClass .container_method(OFFSET)
  # Spec results finish
  # <<<<<<<<<<<<<<<<
end

