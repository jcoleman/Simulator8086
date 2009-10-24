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
	
	# -----------------------------------------------------------------
	# Arithemetic Instructions
	# -----------------------------------------------------------------
	
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
	
	# -----------------------------------------------------------------
	# Control Transfer Instructions
	# -----------------------------------------------------------------
	
	# Jump if the zero flag is set
	# (from a math operation or comparing two numbers that are equal)
	def execute_JNE(operand) # Same as the JNZ instruction
		jump_conditionally_to_signed_displacement(operand, !(@flags.value[ZERO_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the zero flag is not set
	# (from a math operation or comparing two numbers that are unequal)
	def execute_JE(operand) # Same as the JZ instruction
		jump_conditionally_to_signed_displacement(operand, @flags.value[ZERO_FLAG].zero?) # Non-zero means set
	end
	
	# Jump if the overflow flag is not set
	def execute_JNO(operand)
		jump_conditionally_to_signed_displacement(operand, !(@flags.value[OVERFLOW_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the overflow flag is set
	def execute_JO(operand)
		jump_conditionally_to_signed_displacement(operand, @flags.value[OVERFLOW_FLAG].zero?) # Non-zero means set
	end
	
	# Jump if the sign flag is not set
	def execute_JNS(operand)
		jump_conditionally_to_signed_displacement(operand, !(@flags.value[SIGN_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the sign flag is set
	def execute_JS(operand)
		jump_conditionally_to_signed_displacement(operand, @flags.value[SIGN_FLAG].zero?) # Non-zero means set
	end
	
	# Jump if the carry flag is set
	# (compare operation: either below || not above or equal)
	def execute_JNAE(operand) # Same as the JC and JB instructions
		jump_conditionally_to_signed_displacement(operand, !(@flags.value[CARRY_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the carry flag is not set
	# (compare operation: either not below || above or equal)
	def execute_JNB(operand) # Same as the JNC and JAE instructions
		jump_conditionally_to_signed_displacement(operand, @flags.value[CARRY_FLAG].zero?) # Non-zero means set
	end
	
	# Jump if the carry and zero flags are not set
	# (compare operation: either below or equal || not above)
	def execute_JNA(operand) # Same as the JBE instruction
		is_above = @flags.value[ZERO_FLAG].zero? && @flags.value[CARRY_FLAG].zero?
		jump_conditionally_to_signed_displacement(operand, !is_above)
	end
	
	# Jump if the carry and zero flags are not both set
	# (compare operation: either not below or equal || above)
	def execute_JNBE(operand) # Same as the JA instruction
		is_above = @flags.value[ZERO_FLAG].zero? && @flags.value[CARRY_FLAG].zero?
		jump_conditionally_to_signed_displacement(operand, is_above)
	end
	
	# Jump if the parity flag is not set
	# (parity is odd)
	def execute_JNP(operand) # Same as the JPO instruction
		jump_conditionally_to_signed_displacement(operand, !(@flags.value[PARITY_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the parity flag is set
	# (parity is even)
	def execute_JPE(operand) # Same as the JP instruction
		jump_conditionally_to_signed_displacement(operand, @flags.value[PARITY_FLAG].zero?) # Non-zero means set
	end
	
	# Jump if the sign flag does not equal the overflow flag
	# (compare operation: either less than || not greater than or equal)
	def execute_JL(operand) # Same as the JNGE instruction
		is_less_than = (@flags.value[SIGN_FLAG] ^ @flags.value[OVERFLOW_FLAG]) == 1
		jump_conditionally_to_signed_displacement(operand, is_less_than)
	end
	
	# Jump if the sign flag equals the overflow flag
	# (compare operation: either not less than || greater than or equal)
	def execute_JGE(operand) # Same as the JNL instruction
		is_greater_than = @flags.value[SIGN_FLAG] == @flags.value[OVERFLOW_FLAG]
		jump_conditionally_to_signed_displacement(operand, is_greater_than)
	end
	
	# Jump if the sign flag does not equal the overflow flag OR the zero flag is set
	# (compare operation: either less than or equal || not greater than)
	def execute_JLE(operand) # Same as the JNG instruction
		is_less_than = (@flags.value[SIGN_FLAG] ^ @flags.value[OVERFLOW_FLAG]) == 1
		is_less_than_or_equal = is_less_than || @flags.value[ZERO_FLAG] == 1
		jump_conditionally_to_signed_displacement(operand, is_less_than_or_equal)
	end
	
	# Jump if the sign flag equals the overflow flag AND the zero flag is not set
	# (compare operation: either greater than || not less than or equal)
	def execute_JG(operand) # Same as the JNLE instruction
		sf_equals_of = (@flags.value[SIGN_FLAG] ^ @flags.value[OVERFLOW_FLAG]).zero?
		is_greater_than = sf_equals_of && @flags.value[ZERO_FLAG].zero?
		jump_conditionally_to_signed_displacement(operand, is_greater_than)
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
	
	# -----------------------------------------------------------------
	# Stack Instructions
	# -----------------------------------------------------------------
	
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
