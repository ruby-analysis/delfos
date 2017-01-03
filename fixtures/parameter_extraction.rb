module DelfosSpecs
  class SomeOtherConstant
  end

  ANOTHER_CONSTANT = 1

  class ParameterExtractionExample
    def with_required_args(a, b)
    end

    def with_optional_args(a=nil,
                           b=2,
                           c="some_string")
    end

    def with_optional_args_with_constant_defaults(
      a=SomeOtherConstant,
      b=File,
      c=ANOTHER_CONSTANT,
      d=SomeOtherConstant.new("asdf"),
      e=SomeOtherConstant.new(ANOTHER_CONSTANT),
      f=SomeOtherConstant.new(SomeOtherConstant.new(ANOTHER_CONSTANT))
    )
    end

    def with_block(&some_block)
    end

    def with_keyword_args(asdf: 1,
                          qwer: {},
                          some_call: a_method_call
                         )
    end

    def with_required_keyword_args(jkl:,
                                   iop:)
    end

    def with_optional_and_required_args(a,
                                        b,c=1,
                                        d=2)
    end

    def with_optional_and_required_keyword_args(a:1,
                                                b:2,c:,d:)
    end

    def with_rest_args(*args)
    end

    def with_rest_keyword_args(**kw_args)
    end

    def with_rest_args_and_keyword_args(*args,
                                        **kw_args)
    end

    def with_everything(a,b,
                        c=nil,
                        d=1,
                        *args,
                        asdf: 1, qwer: 2,
                        a_constant: SomeOtherConstant, 
                        another_constant: ANOTHER_CONSTANT,
                        yuio:, uiop:,
                        **kw_args,
                        &some_block)
    end
  end
end
