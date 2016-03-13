if BasicObject.respond_to? :_delfos_setup_method_call_logging!
  BasicObject.instance_eval do 
    undef _delfos_setup_method_call_logging
    undef _delfos_method_has_been_added?
    undef _delfos_added_methods
    undef _delfos_record_method_adding
  end
end
