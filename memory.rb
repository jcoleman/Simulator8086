#
#  memory.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/05/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

class Memory
	
  def initialize(bytes, initial_value)
    @bytes_array = Array.new(bytes, initial_value)
  end
  
  def byte_at(reference)
    raise MemoryAccessViolation.new unless reference < @bytes_array.size
    @bytes_array[reference]
  end
  
  def word_at(reference)
    raise MemoryAccessViolation.new unless reference + 1 < @bytes_array.size
    Memory.word_from_little_endian_bytes(@bytes_array[reference], @bytes_array[reference + 1])
  end
	
	def bytes_at(reference, count)
		@bytes_array[reference ... (reference + count)]
	end
  
  def set_byte_at(reference, value)
    raise MemoryAccessViolation.new unless reference < @bytes_array.size
    @bytes_array[reference] = value.to_fixed_size(8)
  end
  
  def set_word_at(reference, value)
    raise MemoryAccessViolation.new unless reference + 1 < @bytes_array.size
		value = value.to_fixed_size(16)
    @bytes_array[reference] = value & 0x00FF
		@bytes_array[reference + 1] = value >> 8
  end
  
  # Note: set_bytes_at will not correct endianess! Do not use unless
  # 'bytes' is already stored in the correct endian format
  def set_bytes_at(reference, bytes)
    raise MemoryAccessViolation.new unless reference + bytes.size < @bytes_array.size
    bytes.each_with_index do |byte, index|
      @bytes_array[reference + index] = byte.to_fixed_size(8)
    end
  end
  
  def [] (params)
    case params[:type]
      when :byte
        byte_at(params[:reference])
      when :word
        word_at(params[:reference])
    end
  end
  
  def []= (params, value)
    case params[:type]
      when :byte
        set_byte_at(params[:reference], value)
      when :word
        set_word_at(params[:reference], value)
    end
  end
	
	def load_module(memory_module)
		set_bytes_at memory_module[:address], memory_module[:bytes]
	end
  
  def self.absolute_address_for(segment, offset)
    (segment << 4) + offset
  end
  
	def byte_size
		@bytes_array.size
	end
	
  def checksum
    Utility.checksum_byte_array @bytes_array
  end
	
	def self.segment_offset_string_from(segment, offset)
		segment.to_hex_string(4) << ':' << offset.to_hex_string(4)
	end
  
	def self.word_from_little_endian_bytes(byte0, byte1)
		(byte1 << 8) + byte0
	end
	
end

class MemoryAccessViolation < StandardError; end