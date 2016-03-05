class BasicObject
  def self._delfos_setup_method_call_logging(name, private_method, class_method:)
    return if private_methods.map(&:to_s).include? name.to_s
    original_method = class_method ? singleton_method(name) : instance_method(name)
    return if ::Delfos::MethodLogging.exclude_from_logging?(original_method)

    method_defining_method = class_method ? method(:define_singleton_method) : method(:define_method)

    method_defining_method.call(name) do |*args, **keyword_args, &block|
      ::Delfos::MethodLogging.log(self,
                                  args, keyword_args, block,
                                  class_method, caller.dup, binding.dup,
                                  original_method
                                 )
      method_to_call = class_method ? original_method : original_method.bind(self)

      if keyword_args.empty?
        method_to_call.call(*args, &block)
      else
        method_to_call.call(*args, **keyword_args, &block)
      end
    end
  end

  def self.method_added(name)
    return if name.to_s == __method__.to_s

    _delfos_setup_method_call_logging(name, private_instance_methods, class_method: false)
  end

  def self.singleton_method_added(name)
    return if name.to_s == __method__.to_s

    _delfos_setup_method_call_logging(name, private_class_methods, class_method: true)
  end
end

