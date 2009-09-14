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
      read(size).each_byte.collect { |byte| byte }
    end
    
    def read_word
      getbyte + (getbyte << 8)
    end
  end
end

