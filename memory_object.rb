#
#  memory_object.rb
#  Simulator8086
#
#  Created by James Coleman on 9/11/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

#require 'memory'
#require 'register'

class MemoryObject
	
	def initialize(io)
		@io = io
		@positions = { :registers => 0,
									 :module_count => 28,
									 :modules => 29 }
	end
	
	def modules
		@io.seek @positions[:module_count]
		module_count = @io.getbyte
		
		@io.seek @positions[:modules]
    modules = []
		module_count.times { modules << read_module }
		
		return modules
	end
	
	def read_module
		# Determine where to load the module
    segment_register_id = @io.getbyte
		offset = @io.read_word
    
    # Read the module's memory dump
    bytes = @io.get_bytes(@io.read_word)
		
		print bytes
		print "\n"
		
		{ :segment_register_id => segment_register_id, :offset => offset, :bytes => bytes }
	end
	
	def registers
		@io.seek @positions[:registers]
		14.times.collect { @io.read_word }
	end
	
end

