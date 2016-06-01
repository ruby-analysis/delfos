class SomeKlass
  class << self
    def inspect
      name
    end

    def name
      'SomeKlass'
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
