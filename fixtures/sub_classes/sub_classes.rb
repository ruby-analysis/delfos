class SomeKlass
  class << self
    def something
      something_else
    end

    def something_else
      'something else'
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
  def self.something
    'some sub class class method call'
  end
end
