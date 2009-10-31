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
		register.direct_value = memory_operand.offset
	end
	
	# Load effective address: the offset the memory operand holds into the
	# destination and the segment (the next word in memory) into ES
	def execute_LES(destination, memory_operand)
		destination.direct_value = memory_operand.value
		@es.direct_value = memory_operand.next_word_value
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
	
	# Store AH into FLAGS
	def execute_SAHF(flags_register)
		# Mask the extra bits in AH for data consistency
		@flags.low = (@ax.high & 0b11010101)
	end
	
	# Load AH from FLAGS
	def execute_LAHF(flags_register)
		@ax.high = @flags.low
	end
	
	# Enter the halt state
	def execute_HLT
		@state = :HALT_STATE
	end
	
	# -----------------------------------------------------------------
	# Arithemetic Instructions
	# -----------------------------------------------------------------
	
	# Destination is set to the destination value plus the source value
	def execute_ADD(destination, source)
		perform_arithmetic_operation_storing_result(source, destination, destination.value + source.value)
	end
	
	# Destination is set to the destination value plus the source value + CF
	def execute_ADC(destination, source)
		perform_arithmetic_operation_storing_result(source, destination, destination.value + source.value + @flags[CARRY_FLAG])
	end
	
	# Destination is set to the destination value minus the source value
	def execute_SUB(destination, source)
		perform_arithmetic_operation_storing_result(source, destination, destination.value - source.value)
	end
	
	# Destination is set to the destination value minus the source value - CF
	def execute_SBB(destination, source)
		perform_arithmetic_operation_storing_result(source, destination, destination.value - source.value - @flags[CARRY_FLAG])
	end
	
	# Adds one to the operand
	def execute_INC(operand)
		perform_arithmetic_operation_storing_result(operand, operand, operand.value + 1)
	end
	
	# Subtracts one from the operand
	def execute_DEC(operand)
		perform_arithmetic_operation_storing_result(operand, operand, operand.value - 1)
	end
	
	# Perform subtraction but do not store the result in destination
	def execute_CMP(destination, source)
		perform_arithmetic_operation(source, destination, destination.value - source.value)
	end
	
	# -----------------------------------------------------------------
	# Bit Instructions
	# -----------------------------------------------------------------
	
	# Destination is set to the destination value bitwise ANDed with the source value
	def execute_AND(destination, source)
		# all flag are undefined
		destination.value &= source.value
	end
	
	# Perform bitwise AND but do not store the result in destination
	def execute_TEST(destination, source)
		# TODO: all flags affected but AF
		destination.value &= source.value
	end
	
	# Destination is set to the destination value bitwise ORed with the source value
	def execute_OR(destination, source)
		# TODO: all flags affected but AF
		destination.value |= source.value
	end
	
	# Destination is set to the destination value bitwise XORed with the source value
	def execute_XOR(destination, source)
		# TODO: all flags affected but AF
		destination.value ^= source.value
	end
	
	# Performs a one's complement on the operand (flips the bits)
	def execute_NOT(operand)
		# no flags affected
		operand.value = ~operand.value
	end
	
	# Performs a two's complement on the operand (flips the bits and adds one)
	# practically this means the negation of the number
	def execute_NEG(operand)
		# TODO: all flags affected
		operand.value = 0 - operand
	end
	
	def execute_SHR(operand)
		# TODO: all flags affected but AF
		operand.direct_value = operand.value >> bit_movement_count_for(operand)
	end
	
	def execute_SHL(operand)
		# TODO: all flags affected but AF
		operand.value = operand.value << bit_movement_count_for(operand)
	end
	
	def execute_SAR(operand)
		# TODO: all flags affected but AF
		size = operand.size
		sign = operand.value[size - 1]
		bit_moves = bit_movement_count_for(operand)
		value = operand.value >> bit_moves
		if sign == 1
			mask = size == 16 ? 0xFFFF : 0xFF
			mask = (mask >> size - bit_moves) << bit_moves
		end
		operand.direct_value = value | mask
	end
	
	def execute_ROR(operand)
		
	end
	
	def execute_ROL(operand)
		
	end
	
	def execute_RCR(operand)
		
	end
	
	def execute_RCL(operand)
		
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
	
	def execute_JMP(offset)
		jump_conditionally_to_signed_displacement(offset, true)
	end
	
	def execute_JMPFAR(pointer)
		@cs.direct_value = pointer.next_word_value # Segment
		jump_conditionally_to_signed_displacement(pointer, true) # Offset
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
	
	def execute_CALL(offset)
		# Executing an intra-segment call
		push_stack_word @ip.value
		jump_conditionally_to_signed_displacement(offset, true)
	end
	
	def execute_CALFAR(pointer)
		# Executing an inter-segment call
		push_stack_word @cs.value # Save current segment
		@cs.direct_value = pointer.next_word_value # Setup new segment
		push_stack_word @ip.value # Save current IP
		jump_conditionally_to_signed_displacement(pointer.value, true) # Goto new IP
	end
	
	def execute_RET(operand=nil)
		@ip.direct_value = pop_stack_word
		@sp.value += operand.value if operand
	end
	
	def execute_RETFAR(operand=nil)
		@ip.direct_value = pop_stack_word
		@cs.direct_value = pop_stack_word
		@sp.value += operand.value if operand
	end
	
	def execute_IRET
		@ip.direct_value = pop_stack_word
		@cs.direct_value = pop_stack_word
		@flags.direct_value = pop_stack_word
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
	
	def perform_arithmetic_operation_storing_result(source, destination, expected_value)
		actual = expected_value.to_fixed_size_signed(destination.size)
		set_arithmetic_flags_from(source.value, destination.value, expected_value, actual, destination.size)
		destination.direct_value = actual
	end
	
	def perform_arithmetic_operation(source, destination, expected_value)
		actual = expected_value.to_fixed_size_signed(destination.size)
		set_arithmetic_flags_from(source.value, destination.value, expected_value, actual, destination.size)
	end
	
	# -----------------------------------------------------------------
	# Jump Helper Methods
	# -----------------------------------------------------------------
	
	def jump_conditionally_to_signed_displacement(operand, condition)
		@ip.direct_value = operand.value if condition
	end
	
	def perform_counting_loop
		cx_counter = @register_operands_16[1]
		perform_arithmetic_operation_storing_result(cx_counter, cx_counter, cx_counter.value - 1)
	end
	
	# -----------------------------------------------------------------
	# Flag Handling Methods
	# -----------------------------------------------------------------
	
	def set_arithmetic_flags_from(source_value, destination_value, expected_value, actual_value, size)
		msb_index = size - 1
		set_zero_flag_from actual_value
		set_sign_flag_from actual_value, msb_index
		set_parity_flag_from actual_value, size
		set_overflow_flag_from source_value, destination_value, actual_value, msb_index
		set_carry_flag_from expected_value, size
	end
	
	def set_zero_flag_from(actual_value)
		@flags.set_bit_at(ZERO_FLAG, (actual_value.zero? ? 1 : 0))
	end
	
	def set_sign_flag_from(actual_value, msb_index)
		@flags.set_bit_at(SIGN_FLAG, actual_value[msb_index])
	end
	
	def set_overflow_flag_from(source_value, destination_value, actual_value, msb)
		# Detects if a signed operation overflowed (wrapped around - 
		# operand signs were the same, but result's sign is different )
		overflow_flag = ( (source_value[msb] == destination_value[msb]) && (actual_value[msb] != source_value[msb]) ? 1 : 0 )
		@flags.set_bit_at(OVERFLOW_FLAG, overflow_flag)
	end
	
	def set_parity_flag_from(actual_value, size)
		# Determine the parity (whether number of set bits is odd or even)
		bits_set = 1 # Start at one because the PF is 1 if even and 0 if odd
		actual_value.each_bit(size) { |bit| bits_set += bit }
		@flags.set_bit_at(PARITY_FLAG, bits_set & 1)
	end
	
	def set_carry_flag_from(expected_value, size)
		@flags.set_bit_at(CARRY_FLAG, (
			if size == 16
				expected_value > 0xFFFF || expected_value < 0 ? 1 : 0
			else
				expected_value > 0xFF || expected_value < 0 ? 1 : 0
			end
		))
	end
	
	# -----------------------------------------------------------------
	# Helper Methods
	# -----------------------------------------------------------------
	
	# Used by the shift and rotate instructions to determine the number
	# of bits to shift/rotate.
	def bit_movement_count_for(operand)
		operand.v_bit.zero? ? 1 : @cx.low
	end
	
	class InvalidInstructionCode < StandardError; end
end
