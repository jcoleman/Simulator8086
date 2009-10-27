#
#  memory_stack.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/25/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#
#  Designed to be mixed into the Processor class

module MemoryStack
	
	MAX_STACK_SIZE = 65536
	MAX_STACK_INDEX = 65535
	MAX_STACK_WORD_OFFSET = 65534
	
	def push_stack_word(word_value)
		@sp.value -= 2
		raise StackOverflowError.new if @sp.value < 0
		@ram.set_word_at stack_pointer, word_value
	end
	
	def pop_stack_word
		address = stack_pointer
		@sp.value += 2
		raise StackUnderrunError.new if @sp.value > MAX_STACK_INDEX
		@ram.word_at address
	end
	
	def stack_word_at(word_index)
		@ram.word_at stack_word_index_to_address(word_index)
	end
	
	
	# -----------------------------------------------------
	# Helper Methods
	# -----------------------------------------------------
	
	def stack_word_index_to_offset(word_index)
		stack_offset + (word_index * 2)
	end
	
	def stack_word_index_to_address(word_index)
		stack_pointer + (word_index * 2)
	end
	
	def stack_word_size
		(MAX_STACK_INDEX - stack_offset) / 2
	end
	
	def stack_pointer
		@ss.displacement + stack_offset
	end
	
	def stack_offset
		@sp.value
	end
	
	def stack_segment
		@ss.value
	end
	
	def stack_segment_top
		(stack_segment << 4) + MAX_STACK_INDEX
	end
	
	class StackOverflowError < StandardError; end
	class StackUnderrunError < StandardError; end
	
end
