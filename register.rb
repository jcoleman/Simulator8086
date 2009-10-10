class Register
  attr_accessor :value
  
  def initialize(name, value = 0)
    @name = name
		@value = value
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
end