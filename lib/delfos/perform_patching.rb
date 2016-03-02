      require "byebug"
class BasicObject
  def self._delfos_setup_method_call_logging(name, class_method: false)
    return if private_instance_methods.include? name
    original_method = class_method ? singleton_method(name) : instance_method(name)
    return if ::Delfos::MethodLogging.exclude_from_logging?(original_method)

    method_defining_method = class_method ? method(:define_singleton_method) : method(:define_method)

    method_defining_method.call(name) do |*args, **keyword_args, &block|
      ::Delfos::MethodLogging.log(self, name, args, keyword_args, block, class_method, caller.dup, binding.dup,
                                  original_method
                                 )

      if class_method
        if keyword_args.empty?
          original_method.call(*args, &block)
        else
          original_method.call(*args, **keyword_args, &block)
        end
      else
        bound_method = original_method.bind(self)

        if keyword_args.empty?
          bound_method.call(*args, &block)
        else
          bound_method.call(*args, **keyword_args, &block)
        end
      end
    end
  end

  INSTANCE_METHOD_IGNORE_LIST = %w(
    method_added
    respond_to?
    initialize
    super
  )

  def self.method_added(name)
    return if INSTANCE_METHOD_IGNORE_LIST.include? name.to_s

    m = self.instance_method(name)
    return if ::Delfos::MethodLogging.exclude_from_logging?(m)

    return if method_has_been_added?(name)

    record_method_adding(name)

    _delfos_setup_method_call_logging(name, class_method: false)
  end

  def self.method_has_been_added? name
    return unless defined? @@added_methods
    return unless @@added_methods[self]
    @@added_methods[self][name]
  end

  def self.record_method_adding(name)
    #puts "recording method addition for #{self} #{name}"
    @@added_methods ||= {}
    @@added_methods[self] ||= {}
    @@added_methods[self][name]=true
  end

  def self.singleton_method_added(name)
    return if name.to_s == "singleton_method_added"
    return if method_has_been_added?(name)


    record_method_adding(name)

    _delfos_setup_method_call_logging(name, class_method: true)
  end


end

