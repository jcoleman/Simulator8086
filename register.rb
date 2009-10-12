class Register
  attr_reader :value, :name
	
  def initialize(name, value = 0)
    @name = name
		@value = value.to_fixed_size(16)
  end
  
  def high
    @value >> 8
  end
  
  def low
    @value & 0x00FF
  end
  
  def high=(value)
    @value = (@value & 0x00FF) + (value << 8)
  end
  
  def low=(value)
    @value = (@value & 0xFF00) + value
  end
	
	def value=(value)
		@value = value.to_fixed_size(16)
	end
	
	def set_bit_at(bit_index, value)
		if value.zero?
			@value &= (0xFFFE << bit_index)
		else
			@value |= (0x0001 << bit_index)
		end
	end
end