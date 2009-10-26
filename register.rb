#
#  register.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/06/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

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
		@value = value.to_unsigned_16_bits
	end
	
	def direct_value=(value)
		@value = value
	end
	
	def set_bit_at(bit_index, value)
		if value.zero?
			@value &= (0xFFFE << bit_index)
		else
			@value |= (0x0001 << bit_index)
		end
	end
end