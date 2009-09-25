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
end

