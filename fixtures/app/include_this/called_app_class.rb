require_relative "../exclude_this/exclude_this"

module IncludeThis
  class CalledAppClass
    def some_called_method
      ExcludeThis.new.another_method
    end

    def next_method
      penultimate
    end

    def penultimate
      final_method
    end

    def final_method
    end
  end
end
