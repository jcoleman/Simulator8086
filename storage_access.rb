#
#  memory_access.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/09/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

class MemoryAccess
  attr_writer :ram, :string
  attr_accessor :reference, :size, :v_bit
	attr_reader :displacement, :offset, :type
  
  def initialize(ram, displacement, offset, size, string = nil)
    @ram = ram
    @offset, @displacement = offset, displacement
    @size = size
		@string = string
		@type = :memory
  end
  
  def value
    case @size
      when 8
        @ram.byte_at(reference)
      when 16
        @ram.word_at(reference)
    end
  end
	
	def next_word_value
		@ram.word_at(reference + 2)
	end
  
  def value=(value)
    case @size
      when 8
        @ram.set_byte_at(reference, value)
      when 16
        @ram.set_word_at(reference, value)
    end
  end
	
	def direct_value=(value)
		case @size
      when 8
        @ram.set_direct_byte_at(reference, value)
      when 16
        @ram.set_direct_word_at(reference, value)
    end
	end
	
	def reference
		@displacement + @offset
	end
	
	def segment
		displacement >> 4
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
  attr_accessor :register, :section, :v_bit
	attr_writer :string
	attr_reader :type
  
  def initialize(register, section = nil)
    @register = register
    @section = section
		@type = :register
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
  
	def direct_value=(value)
		case @section
      when nil
        @register.direct_value = value
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
		return @string if @string
		
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
  attr_reader :value, :size, :type
	attr_writer :string
	# next_word_value is only used to support the Inter addressing mode
  attr_accessor :next_word_value
	
  def initialize(value, size)
    @value = value
		@size = size
		@string = nil
		@type = :immediate
	end
	
	def to_s
		unless @string
			@value.to_hex_string(@size / 4)
		else
			@string
		end
	end
end