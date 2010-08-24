#
#  extension.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/11/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

module Extension
  # IO class extensions
  class Object::IO
    def get_bytes(size)
      size.times.collect { readbyte }
    end
    
    def read_word
      readbyte + (readbyte << 8)
    end
  end
  
  class Object::Fixnum
    def to_hex_string(length)
      self.to_s(16).upcase.rjust(length, '0')
    end
    
    def to_fixed_size(bit_count, signed = false)
      # Converts self to an integer limited in size to bit_count bits, signed or unsigned
      # This simulates fixed sized math for use in hardware math simulation
      unsigned = self & (1 << bit_count) - 1
      if signed && unsigned[bit_count - 1] == 1
        unsigned - (1 << bit_count)
      else
        unsigned
      end
    end
    
    def to_fixed_size_signed(bit_count)
      # Converts self to an integer limited in size to bit_count bits, signed or unsigned
      # This simulates fixed sized math for use in hardware math simulation
      unsigned = self & (1 << bit_count) - 1
      if unsigned[bit_count - 1] == 1
        unsigned - (1 << bit_count)
      else
        unsigned
      end
    end
    
    def to_unsigned_16_bits
      self & 0xFFFF
    end
    
    def to_unsigned_8_bits
      self & 0xFF
    end
    
    def to_signed_16_bits
      unsigned = self & 0xFFFF
      unsigned[7] == 1 ? unsigned - 0x10000 : unsigned
    end
    
    def to_signed_8_bits
      unsigned = self & 0xFF
      unsigned[7] == 1 ? unsigned - 0b100000000 : unsigned
    end
    
    def sign_extend_8_to_16_bits
      self < 0x80 ? self : self | 0xFF00
    end
    
    def lowest_4_bits
      self & 0xF
    end
    
    def each_bit(bit_count, &block)
      bit_count.times { |index| block.call(self[index]) }
    end
  end
  
end

