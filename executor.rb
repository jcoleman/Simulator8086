#
#  executor.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 10/10/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#
#  Designed to be mixed into the Processor class

require 'processor_constants'

module Executor
	
	include ProcessorConstants
	
	def execute_XCHG(left, right)
		left.value, right.value = right.value, left.value
	end
	
	def execute_MOV(destination, source)
		destination.value = source.value
	end
	
	def execute_HLT
		@state = :HALT_STATE
	end
	
	def execute_ADD(destination, source)
		perform_arithmetic_operation(destination, destination.value + source.value)
	end
	
	def execute_SUB(destination, source)
		perform_arithmetic_operation(destination, destination.value - source.value)
	end
	
	def execute_AND(destination, source)
		destination.value &= source.value
	end
	
	def execute_OR(destination, source)
		destination.value |= source.value
	end
	
	def execute_INC(operand)
		perform_arithmetic_operation(operand, operand.value + 1)
	end
	
	def execute_DEC(operand)
		perform_arithmetic_operation(operand, operand.value - 1)
	end
	
	def execute_JNE(operand)
		jump_conditionally_to_signed_displacement(operand, !(@flags.value[ZERO_FLAG].zero?)) # Zero means not set
	end
	
	def execute_JE(operand)
		jump_conditionally_to_signed_displacement(operand, @flags.value[ZERO_FLAG].zero?) # Non-zero means set
	end
	
	def execute_JCXZ(operand)
		# Another example of Intel's crazy CISC
		# Jump if CX is zero
		jump_conditionally_to_signed_displacement(operand, @cx.value.zero?)
	end
	
	def execute_JMP(operand)
		jump_conditionally_to_signed_displacement(operand, true)
	end
	
	def execute_JMPFAR(offset, segment)
		
	end
	
	def execute_LOOP(operand)
		cx_counter = @register_operands_16[1]
		perform_arithmetic_operation(cx_counter, cx_counter.value - 1)
		jump_conditionally_to_signed_displacement(operand, !(cx_counter.value.zero?))
	end
	
	def execute_CALL(operand)
		# Executing an intra-segment call
		push_stack_word @ip.value
		jump_conditionally_to_signed_displacement(operand, true)
	end
	
	def execute_RET(operand=nil)
		@ip.value = pop_stack_word
	end
	
	def execute_PUSH(operand)
		push_stack_word operand.value
	end
	
	def execute_POP(operand)
		operand.value = pop_stack_word
	end
	
	def execute_PUSHF(operand)
		push_stack_word operand.value
	end
	
	def execute_POPF(operand)
		operand.value = pop_stack_word
	end
	
	# -----------------------------------------------------------------
	# Arithemetic Methods
	# -----------------------------------------------------------------
	
	def perform_arithmetic_operation(destination, expected_value)
		actual = expected_value.to_fixed_size(destination.size, true)
		set_arithmetic_flags_from(expected_value, actual)
		destination.value = actual
	end
	
	# -----------------------------------------------------------------
	# Jump Helper Methods
	# -----------------------------------------------------------------
	
	def jump_conditionally_to_signed_displacement(operand, condition)
		@ip.value += operand.value if condition
	end
	
	# -----------------------------------------------------------------
	# Flag Handling Methods
	# -----------------------------------------------------------------
	
	def set_arithmetic_flags_from(expected, actual)
		@flags.set_bit_at(ZERO_FLAG, (actual.zero? ? 1 : 0))
	end
	
	class InvalidInstructionCode < StandardError; end
end
