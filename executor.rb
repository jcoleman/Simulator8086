#
#  executor.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 10/10/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#
#  Designed to be mixed into the Processor class

module Executor
	
	def execute_XCHG(left, right)
		left.value, right.value = right.value, left.value
	end
	
	class InvalidInstructionCode < StandardError; end
end
