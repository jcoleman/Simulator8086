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
	
	# Swap the values in the two operands
	def execute_XCHG(left, right)
		left.value, right.value = right.value, left.value
	end
	
	# Copy the value in source to destination
	def execute_MOV(destination, source)
		destination.value = source.value
	end
	
	# Load effective address (offset in DS) of the memory operand into the register
	def execute_LEA(register, memory_operand)
		register.value = memory_operand.offset
	end
	
	# Convert word to double word
	def execute_CWD(accumulator)
		@dx.value = (accumulator.value < 0x8000 ? 0x0000 : 0xFFFF)
	end
	
	# Convert byte to word
	def execute_CBW(accumulator)
		@ax.high = (@ax.low < 0x80 ? 0x00 : 0xFF)
	end
	
	# -----------------------------------------------------------------
	# Processor Control Instructions
	# -----------------------------------------------------------------
	
	def execute_CLC
		@flags.set_bit_at(CARRY_FLAG, 0)
	end
	
	def execute_STC
		@flags.set_bit_at(CARRY_FLAG, 1)
	end
	
	def execute_CLD
		@flags.set_bit_at(DIRECTION_FLAG, 0)
	end
	
	def execute_STD
		@flags.set_bit_at(DIRECTION_FLAG, 1)
	end
	
	def execute_CLI
		@flags.set_bit_at(INTERRUPT_FLAG, 0)
	end
	
	def execute_STI
		@flags.set_bit_at(INTERRUPT_FLAG, 1)
	end
	
	# Toggle the state of the carry flag
	def execute_CMC
		@flags.set_bit_at(CARRY_FLAG, @flags[CARRY_FLAG] ^ 1)
	end
	
	# Enter the halt state
	def execute_HLT
		@state = :HALT_STATE
	end
	
	# -----------------------------------------------------------------
	# Arithemetic Instructions
	# -----------------------------------------------------------------
	
	def execute_ADD(destination, source)
		perform_arithmetic_operation_storing_result(destination, destination.value + source.value)
	end
	
	def execute_SUB(destination, source)
		perform_arithmetic_operation_storing_result(destination, destination.value - source.value)
	end
	
	def execute_AND(destination, source)
		destination.value &= source.value
	end
	
	def execute_OR(destination, source)
		destination.value |= source.value
	end
	
	def execute_XOR(destination, source)
		destination.value ^= source.value
	end
	
	def execute_INC(operand)
		perform_arithmetic_operation_storing_result(operand, operand.value + 1)
	end
	
	def execute_DEC(operand)
		perform_arithmetic_operation_storing_result(operand, operand.value - 1)
	end
	
	# Perform subtraction but do not store the result in destination
	def execute_CMP(destination, source)
		perform_arithmetic_operation(destination, destination.value - source.value)
	end
	
	# Perform bitwise AND but do not store the result in destination
	def execute_TEST(destination, source)
		perform_arithmetic_operation(destination, destination.value & source.value)
	end
	
	# -----------------------------------------------------------------
	# Control Transfer Instructions
	# -----------------------------------------------------------------
	
	# Jump if the zero flag is set
	# (from a math operation or comparing two numbers that are equal)
	def execute_JNE(operand) # Same as the JNZ instruction
		jump_conditionally_to_signed_displacement(operand, (@flags.value[ZERO_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the zero flag is not set
	# (from a math operation or comparing two numbers that are unequal)
	def execute_JE(operand) # Same as the JZ instruction
		jump_conditionally_to_signed_displacement(operand, @flags.value[ZERO_FLAG] == 1) # Non-zero means set
	end
	
	# Jump if the overflow flag is not set
	def execute_JNO(operand)
		jump_conditionally_to_signed_displacement(operand, (@flags.value[OVERFLOW_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the overflow flag is set
	def execute_JO(operand)
		jump_conditionally_to_signed_displacement(operand, @flags.value[OVERFLOW_FLAG] == 1) # Non-zero means set
	end
	
	# Jump if the sign flag is not set
	def execute_JNS(operand)
		jump_conditionally_to_signed_displacement(operand, (@flags.value[SIGN_FLAG].zero?)) # Zero means not set
	end
	
	# Jump if the sign flag is set
	def execute_JS(operand)
		jump_conditionally_to_signed_displacement(operand, @flags.value[SIGN_FLAG] == 1) # Non-zero means set
	end
	
	# Jump if the carry flag is set
	# (compare operation: either below || not above or equal)
	def execute_JNAE(operand) # Same as the JC and JB instructions
		jump_conditionally_to_signed_displacement(operand, @flags.value[CARRY_FLAG] == 1) # Zero means not set
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
		jump_conditionally_to_signed_displacement(operand, @flags.value[PARITY_FLAG] == 1) # Zero means not set
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
	
	# Decrement CX and jump to operand offset until CX == 0
	def execute_LOOP(operand)
		jump_conditionally_to_signed_displacement(operand, !(perform_counting_loop.zero?))
	end
	
	# Decrement CX and jump to operand offset until CX == 0 and ZF is not set
	def execute_LOOPE(operand) # Same as the LOOPZ instruction
		condition = perform_counting_loop.zero? && @flags[ZERO_FLAG].zero?
		jump_conditionally_to_signed_displacement(operand, condition)
	end
	
	# Decrement CX and jump to operand offset until CX == 0 and ZF is set
	def execute_LOOPNE(operand) # Same as the LOOPNZ instruction
		condition = perform_counting_loop.zero? && @flags[ZERO_FLAG] == 1
		jump_conditionally_to_signed_displacement(operand, condition)
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
	# Arithemetic Helper Methods
	# -----------------------------------------------------------------
	
	def perform_arithmetic_operation_storing_result(destination, expected_value)
		actual = expected_value.to_fixed_size(destination.size, true)
		set_arithmetic_flags_from(expected_value, actual)
		destination.value = actual
	end
	
	def perform_arithmetic_operation(destination, expected_value)
		actual = expected_value.to_fixed_size(destination.size, true)
		set_arithmetic_flags_from(expected_value, actual)
	end
	
	# -----------------------------------------------------------------
	# Jump Helper Methods
	# -----------------------------------------------------------------
	
	def jump_conditionally_to_signed_displacement(operand, condition)
		@ip.value += operand.value if condition
	end
	
	def perform_counting_loop
		cx_counter = @register_operands_16[1]
		perform_arithmetic_operation_storing_result(cx_counter, cx_counter.value - 1)
	end
	
	# -----------------------------------------------------------------
	# Flag Handling Methods
	# -----------------------------------------------------------------
	
	def set_arithmetic_flags_from(expected, actual)
		@flags.set_bit_at(ZERO_FLAG, (actual.zero? ? 1 : 0))
	end
	
	class InvalidInstructionCode < StandardError; end
end
