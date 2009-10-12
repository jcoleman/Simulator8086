class MemoryAccess
  attr_writer :ram
  attr_accessor :reference, :size
  
  def initialize(ram, reference, size, string = nil)
    @ram = ram
    @reference = reference
    @size = size
		@string = string
  end
  
  def value
    case @size
      when 8
        @ram.byte_at(@reference)
      when 16
        @ram.word_at(@reference)
    end
  end
  
  def value=(value)
    case @size
      when 8
        @ram.set_byte_at(@reference, value)
      when 16
        @ram.set_word_at(@reference, value)
    end 
  end
	
	def to_s
		if @string
			@string
		else
			"[#{@reference.to_hex_string(5)}]"
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
        @register.value
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
      16
    else
      8
    end
  end
	
	def to_s
		@register.name.to_s
	end
end


class ImmediateValue
  attr_reader :value, :size
  
  def initialize(value, size)
    @value = value
		@size = size
  end
	
	def to_s
		@value.to_hex_string(@size / 4)
	end
end