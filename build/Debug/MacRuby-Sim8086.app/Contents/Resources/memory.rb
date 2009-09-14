class Memory
	
  def initialize(bytes, initial_value)
    @bytes_array = Array.new(bytes, initial_value)
  end
  
  def byte_at(reference)
    raise new MemoryAccessViolation unless reference < @bytes_array.size
    @bytes_array[reference]
  end
  
  def word_at(reference)
    raise new MemoryAccessViolation unless reference + 1 < @bytes_array.size
    (@bytes_array[reference + 1] << 8) + @bytes_array[reference]
  end
  
  def set_byte_at(reference, value)
    raise new MemoryAccessViolation unless reference < @bytes_array.size
    @bytes_array[reference] = value
  end
  
  def set_word_at(reference, value)
    raise new MemoryAccessViolation unless reference + 1 < @bytes_array.size
    @bytes_array[reference] = value >> 8
    @bytes_array[reference + 1] = value & 0x00FF
  end
  
  # Note: set_bytes_at will not correct endianess! Do not use unless
  # 'bytes' is already stored in the correct endian format
  def set_bytes_at(reference, bytes)
    raise new MemoryAccessViolation unless reference + bytes.size < @bytes_array.size
    bytes.each_with_index do |byte, index|
      @bytes_array[reference + index] = byte
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
  
  def checksum
    Utility.checksum_byte_array @bytes_array
  end
  
end

class MemoryAccessViolation < StandardError; end