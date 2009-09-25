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
	
	attr_reader :registers, :modules
	
	def initialize(io)
		@registers = 14.times.collect { io.read_word }
		@modules = read_modules(io)
	end
	
	def read_modules(io)
		module_count = io.readbyte
		
    modules = []
		module_count.times { modules << read_module(io) }
		
		return modules
	end
	
	def read_module(io)
		# Determine where to load the module
    segment_register_id = io.readbyte
		offset = io.read_word
		
    # Read the module's memory dump
		size = io.read_word
    bytes = io.get_bytes(size)
		
		{ :segment_register_id => segment_register_id, :offset => offset, :bytes => bytes }
	end
	
end

