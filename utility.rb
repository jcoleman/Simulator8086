#
#  utility.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/11/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

module Utility
	MAX_32 = 2**32
  MAX_SIGNED_32 = 2**31 - 1
  
  def self.checksum_byte_array(byte_array)
    sum = 0
    byte_array.each_index do |index|
			sum += byte_array[index] ^ index
      sum = (sum - MAX_32) if sum > MAX_SIGNED_32
    end
    
    sum
  end
end
