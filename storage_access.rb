#
#  memory_access.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/09/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

class MemoryAccess
  attr_writer :ram
  attr_accessor :reference, :size
  
  def initialize(ram, segment, offset, size, string = nil)
    @ram = ram
    @offset, @segment = offset, segment
    @size = size
		@string = string
  end
  
  def value
    case @size
      when 8
        @ram.byte_at(reference)
      when 16
        @ram.word_at(reference)
    end
  end
  
  def value=(value)
    case @size
      when 8
        @ram.set_byte_at(reference, value)
      when 16
        @ram.set_word_at(reference, value)
    end 
  end
	
	def reference
		Memory.absolute_address_for @segment, @offset
	end
	
	def to_s
		if @string
			@string
		else
			"[#{@offset.to_hex_string(4)}]"
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
		register_name = @register.name.to_s
		case @section
			when :high
				register_name[1] = 'h'
			when :low
				register_name[1] = 'l'
		end
		return register_name
	end
end


class ImmediateValue
  attr_reader :value, :size
	attr_writer :string
  
  def initialize(value, size)
    @value = value
		@size = size
		@string = nil
  end
	
	def to_s
		unless @string
			@value.to_hex_string(@size / 4)
		else
			@string
		end
	end
end