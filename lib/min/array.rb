module Min
  class Array < Min::Object
    attr_reader :array
    
    def initialize(array=[])
      @array = array
    end
    
    min_def :<< do |context, value|
      @array << value
    end

    min_def :[] do |context, index|
      @array[index.value]
    end
    
    min_def :size do |context|
      Number.new(@array.size)
    end
  end
end