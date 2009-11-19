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
	
	def execute_XLAT
		operand = MemoryAccess.new(@ram, @ds.displacement, @bx.value + @ax.low, 8)
		@ax.low = operand.value
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
		set_auxiliary_carry_flag_from destination.value.lowest_4_bits + source.value.lowest_4_bits
		perform_arithmetic_operation_storing_result(source, destination, destination.value + source.value)
	end
	
	# Destination is set to the destination value plus the source value + CF
	def execute_ADC(destination, source)
		set_auxiliary_carry_flag_from destination.value.lowest_4_bits + source.value.lowest_4_bits + @flags.value[CARRY_FLAG]
		perform_arithmetic_operation_storing_result(source, destination, destination.value + source.value + @flags.value[CARRY_FLAG])
	end
	
	# Destination is set to the destination value minus the source value
	def execute_SUB(destination, source)
		set_auxiliary_carry_flag_from destination.value.lowest_4_bits - source.value.lowest_4_bits
		perform_arithmetic_operation_storing_result(source, destination, destination.value - source.value)
	end
	
	# Destination is set to the destination value minus the source value - CF
	def execute_SBB(destination, source)
		set_auxiliary_carry_flag_from destination.value.lowest_4_bits - source.value.lowest_4_bits - @flags.value[CARRY_FLAG]
		perform_arithmetic_operation_storing_result(source, destination, destination.value - source.value - @flags.value[CARRY_FLAG])
	end
	
	# Adds one to the operand
	def execute_INC(operand)
		set_auxiliary_carry_flag_from operand.value.lowest_4_bits + 1
		perform_inc_or_dec_storing_result(operand, operand, operand.value + 1)
	end
	
	# Subtracts one from the operand
	def execute_DEC(operand)
		set_auxiliary_carry_flag_from operand.value.lowest_4_bits - 1
		perform_inc_or_dec_storing_result(operand, operand, operand.value - 1)
	end
	
	# Perform subtraction but do not store the result in destination
	def execute_CMP(destination, source)
		set_auxiliary_carry_flag_from destination.value.lowest_4_bits - source.value.lowest_4_bits
		perform_arithmetic_operation(source, destination, destination.value - source.value)
	end
	
	# Perform unsigned multiplication
	def execute_MUL(operand)
		# Affects CF, OF; all other flags undefined
		if operand.size == 8
			@ax.value = operand.value * @ax.low
			flag = @ax.high.zero? ? 0 : 1
		else
			result = operand.value * @ax.value
			@dx.value = result >> 16
			@ax.value = result & 0xFFFF
			flag = @dx.value.zero? ? 0 : 1
		end
		
		@flags.set_bit_at(CARRY_FLAG, flag)
		@flags.set_bit_at(OVERFLOW_FLAG, flag)
	end
	
	# Perform signed multiplation
	def execute_IMUL(operand)
		
	end
	
	# Perform unsigned division
	def execute_DIV(operand)
		# All flags undefined
		
		# Check for divide by zero
		return perform_interrupt_for 0 if operand.value.zero?
		
		if operand.size == 8
			# Perform calculation
			quotient = @ax.value / operand.value
			remainder = @ax.value % operand.value
			
			# Check for overflow
			return perform_interrupt_for 0 if quotient > 0xFF
			
			# Save results
			@ax.low = quotient
			@ax.high = remainder
		else # 16-bit operation
			# Perform calculation
			dividend = (@dx.value << 16) + @ax.value
			quotient = dividend / operand.value
			remainder = dividend % operand.value
			
			# Check for overflow
			return perform_interrupt_for 0 if quotient > 0xFFFF
			
			# Save results
			@ax.value = quotient
			@dx.value = remainder
		end
	end
	
	# Perform signed division
	def execute_IDIV(operand)
		
	end
	
	def execute_OUT(io_port, operand)
		io_port.write(operand.value, self)
	end
	
	# -----------------------------------------------------------------
	# Bit Instructions
	# -----------------------------------------------------------------
	
	# Destination is set to the destination value bitwise ANDed with the source value
	def execute_AND(destination, source)
		# all flags are affected except AF is undefined
		destination.value &= source.value
		set_logical_flags_from destination.value, destination.size
	end
	
	# Perform bitwise AND but do not store the result in destination
	def execute_TEST(destination, source)
		# all flags are affected except AF is undefined
		set_logical_flags_from destination.value & source.value, destination.size
	end
	
	# Destination is set to the destination value bitwise ORed with the source value
	def execute_OR(destination, source)
		# all flags are affected except AF is undefined
		destination.value |= source.value
		set_logical_flags_from destination.value, destination.size
	end
	
	# Destination is set to the destination value bitwise XORed with the source value
	def execute_XOR(destination, source)
		# all flags are affected except AF is undefined
		destination.value ^= source.value
		set_logical_flags_from destination.value, destination.size
	end
	
	# Performs a one's complement on the operand (flips the bits)
	def execute_NOT(operand)
		# no flags affected
		operand.value = ~operand.value
	end
	
	# Performs a two's complement on the operand (flips the bits and adds one)
	# practically this means the negation of the number
	def execute_NEG(operand)
		# all flags affected
		set_auxiliary_carry_flag_from 0 - operand.value.lowest_4_bits
		perform_arithmetic_operation_storing_result(operand, operand, 0 - operand.value)
	end
	
	# Shift the operand's value to the right
	def execute_SHR(operand)
		# all flags are affected except AF is undefined
		count = bit_shift_count_for(operand, operand.size)
		new_value = operand.value >> count
		set_shift_flags_from(new_value, new_value, operand.value[count - 1], operand.size)
		operand.direct_value = new_value
	end
	
	# Shift the operand's value to the left
	def execute_SHL(operand) # Same instruction as SAL
		# all flags are affected except AF is undefined
		expected_value = operand.value << bit_shift_count_for(operand, operand.size)
		operand.value = expected_value
		size = operand.size
		set_shift_flags_from(operand.value, expected_value, expected_value[size], size)
	end
	
	# Shift arithmetic right (essentially sign extend the result from the original msb)
	def execute_SAR(operand)
		# all flags are affected except AF is undefined
		size = operand.size
		sign = operand.value[size - 1]
		bit_moves = bit_shift_count_for(operand, size)
		value = operand.value >> bit_moves
		if sign == 1
			mask_shift = size - bit_moves
			mask = ((size == 16 ? 0xFFFF : 0xFF) >> (mask_shift)) << mask_shift
			value |= mask
		end
		set_shift_flags_from(value, value, operand.value[bit_moves - 1], size)
		operand.direct_value = value
	end
	
	# Rotate the operand's value right
	def execute_ROR(operand)
		# affects CF and OF flags
		count = bit_rotate_count_for(operand, operand.size)
		mask = (operand.value << (operand.size - count))
		original_value = operand.value
		operand.value = (operand.value >> count) + mask
		set_rotate_flags_from(operand, original_value)
	end
	
	# Rotate the operand's value left
	def execute_ROL(operand)
		# affects CF and OF flags
		count = bit_rotate_count_for(operand, operand.size)
		mask = (operand.value >> (operand.size - count))
		original_value = operand.value
		operand.value = (operand.value << count) + mask
		set_rotate_flags_from(operand, original_value)
	end
	
	# Rotate the operand's value right through the carry flag
	def execute_RCR(operand)
		# affects CF and OF flags
		original_value = operand.value
		size = operand.size + 1
		count = bit_rotate_count_for(operand, size)
		carry_flag = operand.value[count - 1]
		mask = (operand.value << (size - count))
		previous_carry_flag = operand.v_bit.zero? ? @flags.value[CARRY_FLAG] : operand.value[count - 2]
		operand.value = (operand.value >> count) + mask + (previous_carry_flag << (operand.size - count))
		set_rotate_flags_from(operand, original_value)
		@flags.set_bit_at(CARRY_FLAG, carry_flag)
	end
	
	# Rotate the operand's value left through the carry flag
	def execute_RCL(operand)
		# affects CF and OF flags
		original_value = operand.value
		size = operand.size + 1
		count = bit_rotate_count_for(operand, size)
		carry_flag = operand.value[operand.size - count]
		mask = (operand.value >> (size - count))
		previous_carry_flag = operand.v_bit.zero? ? @flags.value[CARRY_FLAG] : operand.value[size - count]
		operand.value = (operand.value << count) + mask + (previous_carry_flag << (count - 1))
		set_rotate_flags_from(operand, original_value)
		@flags.set_bit_at(CARRY_FLAG, carry_flag)
	end
	
	# -----------------------------------------------------------------
	# Control Transfer Instructions
	# -----------------------------------------------------------------
	
	# Jump if the zero flag is set
	# (from a math operation or comparing two numbers that are equal)
	def execute_JNE(operand) # Same as the JNZ instruction
		jump_conditionally_to_signed_displacement(operand, @flags.value[ZERO_FLAG].zero?) # Zero means not set
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
	
	# Jump if CX is zero
	def execute_JCXZ(operand)
		# Another example of Intel's crazy CISC philosophy
		jump_conditionally_to_signed_displacement(operand, @cx.value.zero?)
	end
	
	# Unconditional jump within the current segment
	def execute_JMP(offset)
		jump_conditionally_to_signed_displacement(offset, true)
	end
	
	# Unconditional jump to a different segment
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
	
	# Intra-segment call
	def execute_CALL(offset)
		push_stack_word @ip.value
		jump_conditionally_to_signed_displacement(offset, true)
	end
	
	# Inter-segment call
	def execute_CALFAR(pointer)
		push_stack_word @cs.value # Save current segment
		@cs.direct_value = pointer.next_word_value # Setup new segment
		push_stack_word @ip.value # Save current IP
		jump_conditionally_to_signed_displacement(pointer.value, true) # Goto new IP
	end
	
	# Return near (within current segment) with optional pop
	def execute_RET(operand=nil)
		@ip.direct_value = pop_stack_word
		@sp.value += operand.value if operand
	end
	
	# Return far (to different segment) with optional pop
	def execute_RETFAR(operand=nil)
		@ip.direct_value = pop_stack_word
		@cs.direct_value = pop_stack_word
		@sp.value += operand.value if operand
	end
	
	# Return after interrupt (return far with flags restoration)
	def execute_IRET
		@ip.direct_value = pop_stack_word
		@cs.direct_value = pop_stack_word
		@flags.direct_value = pop_stack_word
	end
	
	# Execute the interrupt instruction
	def execute_INT(operand)
		perform_interrupt_for operand.value
	end
	
	# Execute the interrupt on overflow
	def execute_INTO
		# Overflow interrupt is Type 4
		perform_interrupt_for 4
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
		destination.value = actual
	end
	
	def perform_inc_or_dec_storing_result(source, destination, expected_value)
		actual = expected_value.to_fixed_size_signed(destination.size)
		set_arithmetic_flags_except_cf_from(source.value, destination.value, expected_value, actual, destination.size)
		destination.value = actual
	end
	
	def perform_arithmetic_operation(source, destination, expected_value)
		actual = expected_value.to_fixed_size_signed(destination.size)
		set_arithmetic_flags_from(source.value, destination.value, expected_value, actual, destination.size)
	end
	
	# -----------------------------------------------------------------
	# Control Transfer Helper Methods
	# -----------------------------------------------------------------
	
	def jump_conditionally_to_signed_displacement(operand, condition)
		@ip.direct_value = operand.value if condition
	end
	
	def perform_counting_loop
		cx_counter = @register_operands_16[1]
		cx_counter.value -= 1
	end
	
	def perform_interrupt_for(type)
		# Store old values for the flags, code segment, and instruction pointer
		push_stack_word @flags.value
		push_stack_word @cs.value
		push_stack_word @ip.value
		
		# Clear interrupt and trace flags
		@flags.set_bit_at INTERRUPT_FLAG, 0
		@flags.set_bit_at TRACE_FLAG, 0
		
		# Lookup the interrupt handler address and set the new control values
		handler_address = type * 4
		@cs.direct_value = @ram.word_at handler_address + 2
		@ip.direct_value = @ram.word_at handler_address
	end
	
	# -----------------------------------------------------------------
	# Flag Handling Methods
	# -----------------------------------------------------------------
	
	# Calculates all of the flags necessary for an arithmetic operation
	def set_arithmetic_flags_from(source_value, destination_value, expected_value, actual_value, size)
		msb_index = size - 1
		set_zero_flag_from actual_value
		set_sign_flag_from actual_value, msb_index
		set_parity_flag_from actual_value, size
		set_overflow_flag_from source_value, destination_value, expected_value, actual_value, msb_index
		set_carry_flag_from expected_value, size
	end
	
	# Calculates all of the flags necessary for an arithmetic operation
	# except CF (used particularly by INC and DEC)
	def set_arithmetic_flags_except_cf_from(source_value, destination_value, expected_value, actual_value, size)
		msb_index = size - 1
		set_zero_flag_from actual_value
		set_sign_flag_from actual_value, msb_index
		set_parity_flag_from actual_value, size
		set_overflow_flag_from source_value, destination_value, expected_value, actual_value, msb_index
	end
	
	# Calculates the flags for logical bit operations
	def set_logical_flags_from(actual_value, size)
		@flags.set_bit_at(OVERFLOW_FLAG, 0)
		@flags.set_bit_at(CARRY_FLAG, 0)
		set_zero_flag_from actual_value
		set_sign_flag_from actual_value, size - 1
		set_parity_flag_from actual_value, size
	end
	
	# Calculates the flags for shift operations
	def set_shift_flags_from(actual_value, expected_value, carry_flag, size)
		msb = size - 1
		@flags.set_bit_at(OVERFLOW_FLAG, actual_value[msb] == expected_value[msb] ? 0 : 1)
		@flags.set_bit_at(CARRY_FLAG, carry_flag)
		set_zero_flag_from actual_value
		set_sign_flag_from actual_value, msb
		set_parity_flag_from actual_value, size
	end
	
	# Calculates the flags for rotate operations
	def set_rotate_flags_from(operand, original_value)
		msb = operand.size - 1
		overflow_flag = original_value[msb] != operand.value[msb] ? 1 : 0
		@flags.set_bit_at(OVERFLOW_FLAG, overflow_flag)
		@flags.set_bit_at(CARRY_FLAG, operand.value[msb])
	end
	
	# Zero Flag: rather self-explanatory: is the computed value zero?
	def set_zero_flag_from(actual_value)
		@flags.set_bit_at(ZERO_FLAG, (actual_value.zero? ? 1 : 0))
	end
	
	def set_sign_flag_from(actual_value, msb_index)
		@flags.set_bit_at(SIGN_FLAG, actual_value[msb_index])
	end
	
	# Overflow Flag: detects if a signed operation overflowed (wrapped around -
	# operand signs were the same, but result's sign is different)
	def set_overflow_flag_from(source_value, destination_value, expected_value, actual_value, msb)
		flag = ( ((expected_value - destination_value)[msb] == destination_value[msb]) && (actual_value[msb] != destination_value[msb]) ? 1 : 0 )
		@flags.set_bit_at(OVERFLOW_FLAG, flag)
	end
	
	# Parity Flag: determine the parity (whether number of set bits is odd or even)
	def set_parity_flag_from(actual_value, size)
		bits_set = 1 # Start at one because the PF is 1 if even and 0 if odd
		actual_value.each_bit(size) { |bit| bits_set += bit }
		@flags.set_bit_at(PARITY_FLAG, bits_set & 1)
	end
	
	# Carry Flag: overflow from an unsigned operation (the expected value
	# did not fit in the destination)
	def set_carry_flag_from(expected_value, size)
		@flags.set_bit_at(CARRY_FLAG, (
			if size == 16
				(expected_value & 0xFFFFFFFF) > 0xFFFF || expected_value < 0 ? 1 : 0
			else
				(expected_value & 0xFFFFFFFF) > 0xFF || expected_value < 0 ? 1 : 0
			end
		))
	end
	
	# Auxiliary Carry Flag: overflow from the low nybble of the expected value
	# of the operation's result.
	# Note: the expected value is the result of the operation applied to the
	# lowest 4 bits of each operand.
	def set_auxiliary_carry_flag_from(expected_value)
		@flags.set_bit_at(AUX_CARRY_FLAG, (expected_value & 0xFFFFFFFF) > 0xF ? 1 : 0)
	end
	
	# -----------------------------------------------------------------
	# Helper Methods
	# -----------------------------------------------------------------
	
	# Determine the number of bits to rotate - if the operation would
	# wrap around, only need to rotate count mod size times
	def bit_rotate_count_for(operand, size)
		operand.v_bit.zero? ? 1 : @cx.low % size
	end
	
	# Determine the number of bits to shift - cannot be greater than size
	def bit_shift_count_for(operand, size)
		operand.v_bit.zero? ? 1 : (@cx.low > size ? size : @cx.low)
	end
	
	class InvalidInstructionCode < StandardError; end
end
