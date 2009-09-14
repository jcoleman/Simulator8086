class MemoryAccess
  attr_writer :ram
  attr_accessor :reference, :size
  
  def initialize(ram, reference, size)
    @ram = ram
    @reference = reference
    @size = size
  end
  
  def value
    case @size
      when 1
        @ram.get_byte(@reference)
      when 2
        @ram.get_word(@reference)
    end
  end
  
  def value=(value)
    case @size
      when 1
        @ram.set_byte(@reference, value)
      when 2
        @ram.set_word(@reference, value)
    end 
  end
end


class RegisterAccess
  attr_accessor :register, :section
  
  def initialize(register, section = nil)
    @register = register
    @section = section
  end
  
  def value
    case @section
      when nil
        @register
      when :high
        @register.high
      when :low
        @register.low
    end
  end
  
  def value=(value)
    case @section
      when nil
        @register.value = value
      when :high
        @register.high = value
      when :low
        @register.low = value
    end
  end
  
  def size
    unless @section
      2
    else
      1
    end
  end
end


class ImmediateValue
  attr_reader :value
  
  def intialize(value)
    @value = value
  end
end