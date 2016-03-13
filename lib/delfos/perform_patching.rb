class BasicObject
  def self._delfos_setup_method_call_logging(name, private_methods, class_method:)
    return if _delfos_method_has_been_added?(name, class_method: class_method)
    return if private_methods.include? name.to_sym
    original_method = class_method ? singleton_method(name) : instance_method(name)
    return if ::Delfos::MethodLogging.exclude_from_logging?(original_method)
    _delfos_record_method_adding(original_method, class_method: class_method)

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

  def self._delfos_method_has_been_added?(name, class_method:)
    return false unless _delfos_added_methods[self]

    type = class_method ? "class_method" : "instance_method"
    _delfos_added_methods[self]["#{type}_#{name}"]
  end

  def self._delfos_added_methods
    @@_delfos_added_methods ||= {}
  end

  def self._delfos_record_method_adding(meth, class_method: )
    return true if _delfos_method_has_been_added?(meth, class_method: class_method)

    type = class_method ? "class_method" : "instance_method"
    _delfos_added_methods[self] ||= {}
    _delfos_added_methods[self]["#{type}_#{meth.name}"] = meth.source_location
  end

  def self.method_added(name)
    return if name == __method__

    _delfos_setup_method_call_logging(name, private_instance_methods, class_method: false)
  end

  def self.singleton_method_added(name)
    return if name == __method__

    _delfos_setup_method_call_logging(name, private_methods, class_method: true)
  rescue ::Exception => e
    byebug
    nil
  end
end

