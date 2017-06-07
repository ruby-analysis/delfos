require "binding_of_caller"
require "delfos/method_logging"
require "delfos/method_logging/code_location"

class Pathname
  def is_inside?(path)
    return self.expand_path.fnmatch?(File.expand_path(File.join(path,'**')))
  end
end

module Delfos
  class MethodTrace
    class << self

      def trace(app_dirs)

        TracePoint.new(:call) do |tp|
          app_dirs.each do |dir|
            if Pathname(tp.path).is_inside?(dir)
              show_caller = ->(s, label=nil) {
                binding.of_caller(4).eval(s)
              }

              call_site = ::Delfos::MethodLogging::CodeLocation.new(
                object: show_caller.('self.is_a?(Module) ? self : self.class', '  class'),
                method_name: show_caller.("__method__"),
                file: show_caller.("__FILE__"),
                line_number: show_caller.("__LINE__"),
              )

              called_code = ::Delfos::MethodLogging::CodeLocation.new(
                object: tp.self,
                method_name: tp.method_id,
                file: tp.path,
                line_number: tp.lineno,
              )

              ::Delfos::MethodLogging.log(call_site, called_code) if show_caller.("__method__")
            end
          end
        end.enable

      end

    end
  end
end
