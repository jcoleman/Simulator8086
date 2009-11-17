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
    @value = (@value & 0x00FF) + (value.to_unsigned_8_bits << 8)
  end
  
  def low=(value)
    @value = (@value & 0xFF00) + value.to_unsigned_8_bits
  end
	
	def value=(value)
		@value = value.to_unsigned_16_bits
	end
	
	def direct_value=(value)
		@value = value
	end
	
	def set_bit_at(bit_index, value)
		if value.zero?
			@value &= (0xFFFF7FFF >> (15 - bit_index))
		else
			@value |= (0x0001 << bit_index)
		end
	end
end

class SegmentRegister < Register
	attr_reader :displacement
	
	def initialize(name, value = 0)
    super(name, value)
		@displacement = (@value << 4)
  end
	
	def value=(value)
		super(value)
		# Cache the effective displacement when this register is used
		# for addressing segments
		@displacement = (@value << 4)
		return @value
	end
end