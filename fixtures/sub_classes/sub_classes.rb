class SomeKlass
  class << self
    def some_class_method_name
      some_other_class_method_name
    end

    def some_other_class_method_name
      'Something'
    end

    def new
      if self == SomeKlass
        SomeSubKlass.new
      else
        super()
      end
    end
  end
end

class SomeSubKlass < SomeKlass
  def self.name
    'SomeSubKlass'
  end
end
