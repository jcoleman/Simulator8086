#
#  decoder.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/18/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#
#  Designed to be mixed into the Processor class

module Decoder
	
	# -----------------------------------------------------------------
	# Addressing Mode Decode Methods
	# -----------------------------------------------------------------
	
	def decode_None(instruction)
		# Do nothing! No addressing modes need to be decoded :)
	end
	
	def decode_AccMem(instruction)
		# Accumulator to/from memory
		
		# Determine memory offset
		offset = Memory.word_from_little_endian_bytes(fetch_byte(instruction), fetch_byte(instruction))
		
		if instruction.bytes.first[0] == 1 # W-bit
			# Word value
			accumulator = @register_operands_16[0] # AX register operand
			memory = MemoryAccess.new(@ram, @ds.displacement, offset, 16)
		else
			# Byte value
			accumulator = @register_operands_8[0] # AL register
			memory = MemoryAccess.new(@ram, @ds.displacement, offset, 8)
		end
		
		add_operands_by_direction_flag(instruction, memory, accumulator, instruction.bytes.first[1] ^ 1)
	end
	
	def decode_AccReg(instruction)
		# Only used for XCHG, so order of operands is unnecessary
		instruction.operands << @register_operands_16[0] # AX register operand
		
		add_register16_operand(instruction)
	end
	
	def decode_AccImm(instruction)
		# From immediate to accumulator
		if instruction.bytes.first[0] == 1 # W-bit
			# Word value
			instruction.operands << @register_operands_16[0] # AX register operand
			add_immediate_word_operand(instruction)
		else
			# Byte value
			instruction.operands << @register_operands_8[0] # AL register
			add_immediate_byte_operand(instruction)
		end
	end
	
	def decode_Reg(instruction)
		# A single 16-bit register
		add_register16_operand(instruction)
	end
	
	def decode_RegImm(instruction)
		# From immediate to register
		if instruction.bytes.first[3] == 1 # W-bit
			# Word value
			add_register16_operand(instruction)
			add_immediate_word_operand(instruction)
		else
			# Byte value
			add_register8_operand(instruction)
			add_immediate_byte_operand(instruction)
		end
	end
	
	def decode_Short(instruction)
		add_sign_extended_immediate_byte_to_word_ip_offset_operand(instruction)
		#decode_display_for_signed_ip_offset_for instruction, instruction.operands.first
	end
	
	def decode_Intra(instruction)
		add_signed_immediate_word_ip_offset_operand(instruction)
		#decode_display_for_signed_ip_offset_for instruction, instruction.operands.first
	end
	
	def decode_Inter(instruction)
		add_immediate_word_operand(instruction)
		instruction.operands[0].next_word_value = fetch_word_value(instruction)
	end
	
	def decode_XferInd(instruction)
		first_byte = instruction.bytes.first
		mod_rm_byte = retrieve_second_byte_for(instruction)
		
		# Get operand determined by the mod r/m fields
		instruction.operands << mod_rm_operand_for(instruction, mod_rm_byte, 1)
	end
	
	def decode_Acc(instruction)
		# Accumulator register on 16 bit support
		instruction.operands << @register_operands_16[0] # AX register
	end
	
	def decode_Segment(instruction)
		add_segment_register_operand(instruction, instruction.bytes.first)
	end
	
	def decode_Flags(instruction)
		instruction.operands << RegisterAccess.new(@flags)
	end
	
	def decode_RetPop(instruction)
		add_immediate_word_operand(instruction)
	end
	
	def decode_IntNum(instruction)
		add_immediate_byte_operand(instruction)
	end
	
	def decode_RegRM(instruction)
		first_byte = instruction.bytes.first
		width_bit = first_byte[0]
		direction_bit = first_byte[1]
		mod_rm_byte = fetch_byte(instruction)
		
		# Get operand determined by the mod r/m fields
		rm_operand = mod_rm_operand_for(instruction, mod_rm_byte, width_bit)
		
		# Get the register operand
		reg_index = (mod_rm_byte >> 3) & 0x07 # bits 3-5 determine register
		reg_operand = (
			if width_bit == 1
				@register_operands_16[reg_index]
			else
				@register_operands_8[reg_index]
			end
		)
		
		add_operands_by_direction_flag(instruction, rm_operand, reg_operand, direction_bit)
	end
	
	def decode_Type3(instruction)
		instruction.operands << ImmediateValue.new(3, 16)
	end
	
	def decode_RM(instruction)
		first_byte = instruction.bytes.first
		width_bit = first_byte[0]
		mod_rm_byte = retrieve_second_byte_for(instruction)
		
		# Get operand determined by the mod r/m fields
		operand = mod_rm_operand_for(instruction, mod_rm_byte, width_bit)
		operand.v_bit = v_bit = first_byte == 0xD2 || first_byte == 0xD3 ? 1 : 0
		instruction.operands << operand
		
		if operand.type == :memory
			# Specialize the decoding since a single memory operand
			# has no other indicator as to the width of access
			size = width_bit.zero? ? 'BYTE ' : 'WORD '
			string = operand.to_s
			operand.string = string.insert 0, size
		end
	end
	
	def decode_SegRM(instruction)
		first_byte = instruction.bytes.first
		direction_bit = first_byte[1]
		mod_rm_byte = fetch_byte(instruction)
		
		# Get operand determined by the mod r/m fields
		rm_operand = mod_rm_operand_for(instruction, mod_rm_byte, width_bit)
		
		# Get the segment register operand
		seg_index = (mod_rm_byte >> 3) & 0x03 # bits 3-4 determine segment register
		seg_operand = @segment_register_operands[seg_index]
		
		add_operands_by_direction_flag(instruction, rm_operand, seg_operand, direction_bit)
	end
	
	def decode_RMImm(instruction)
		first_byte = instruction.bytes.first
		width_bit = first_byte[0]
		direction_bit = first_byte[1]
		mod_rm_byte = retrieve_second_byte_for(instruction)
		
		# Get operand determined by the mod r/m fields
		rm_operand = mod_rm_operand_for(instruction, mod_rm_byte, width_bit)
		
		# Now handle the immediate operand
		unless instruction.bytes.first == 0x83
			# Normal W-bit immediate mode decoding
			if width_bit == 1
				add_immediate_word_operand(instruction) # Word value
			else
				add_immediate_byte_operand(instruction) # Byte value
			end
		else
			# Intel's special S-bit case
			sign_extended_byte = fetch_byte(instruction).sign_extend_8_to_16_bits
			instruction.operands << ImmediateValue.new(sign_extended_byte, 16)
		end
	end
	
	def decode_AccPort(instruction)
		
	end
	
	def decode_AccVPort(instruction)
		
	end
	
	def decode_AccBase(instruction)
		
	end
	
	def decode_String(instruction)
		
	end
	
	def decode_illegal_addr_mode
		raise IllegalAddressingMode.new
	end
	
	# -----------------------------------------------------------------
	# Mod R/M Methods
	# -----------------------------------------------------------------
	
	def mod_rm_operand_for(instruction, mod_rm_byte, width_bit)
		mod = mod_rm_byte >> 6 # 7-8
		rm = mod_rm_byte & 0x07 # bits 0-2
		
		case mod
			# Zero displacement
			when 0b00
				unless rm == 0b110
					rm_indexed_memory_operand_with_displacement(mod, rm, 0, width_bit)
				else
					# Stupid intel's exceptions - no index if rm = 0b110, just direct offset
					offset = two_byte_displacement_for(instruction)
					MemoryAccess.new(@ram, @ds.displacement, offset, (width_bit == 1 ? 16 : 8 ))
				end
			# Sign extended single byte as displacement
			when 0b01
				sign_extended_displacement = fetch_byte(instruction).sign_extend_8_to_16_bits
				rm_indexed_memory_operand_with_displacement(mod, rm, sign_extended_displacement, width_bit)
			# RM operand is a register operand
			when 0b11
				if width_bit == 1
					@register_operands_16[rm]
				else
					@register_operands_8[rm]
				end
			# Displacement is the next two bytes
			when 0b10
				displacement = two_byte_displacement_for(instruction)
				rm_indexed_memory_operand_with_displacement(mod, rm, displacement, width_bit)
		end
	end
	
	# Displacement is calculated as an offset in the current data segment with
	# an index based on the R/M decoding.
	def rm_indexed_memory_operand_with_displacement(mod, rm, displacement, width_bit)
		rm_name, rm_indices = @rm_index_operands[rm]
		bits = width_bit == 1 ? 16 : 8
		index = rm_indices.inject(0) { |sum, register| sum + register.value }
		address_string = "[#{rm_name} + #{displacement.to_s(16)}]"
		MemoryAccess.new(@ram, @ds.displacement, index + displacement, bits, address_string)
	end
	
	def two_byte_displacement_for(instruction)
		byte0 = fetch_byte(instruction)
		byte1 = fetch_byte(instruction)
		Memory.word_from_little_endian_bytes(byte0, byte1)
	end
	
	# -----------------------------------------------------------------
	# Register Methods
	# -----------------------------------------------------------------
	
	def add_register16_operand(instruction)
		reg_index = instruction.bytes[0] & 0x07 # last 3 bits determine register
		instruction.operands << @register_operands_16[reg_index]
	end
	
	def add_register8_operand(instruction)
		reg_index = instruction.bytes[0] & 0x07 # last 3 bits determine register
		instruction.operands << @register_operands_8[reg_index]
	end
	
	def add_segment_register_operand(instruction, byte_with_index)
		segment_register_index = (byte_with_index >> 3) & 0x03 # Retrieve bits 4-3
		instruction.operands << @segment_register_operands[segment_register_index]
	end
	
	# -----------------------------------------------------------------
	# Immediate Methods
	# -----------------------------------------------------------------
	
	def add_immediate_word_operand(instruction)
		word_value = fetch_word_value(instruction)
		instruction.operands << ImmediateValue.new(word_value, 16)
	end
	
	def add_immediate_byte_operand(instruction)
		instruction.operands << ImmediateValue.new(fetch_byte(instruction), 8)
	end
	
	def add_signed_immediate_word_ip_offset_operand(instruction)
		word_value = fetch_word_value(instruction)
		adjusted_offset = @ip.value + instruction.bytes.size + word_value
		instruction.operands << ImmediateValue.new(adjusted_offset.to_unsigned_16_bits, 16)
	end
	
	def add_sign_extended_immediate_byte_to_word_ip_offset_operand(instruction)
		word_value = fetch_byte(instruction).sign_extend_8_to_16_bits
		adjusted_offset = @ip.value + instruction.bytes.size + word_value
		instruction.operands << ImmediateValue.new(adjusted_offset.to_unsigned_16_bits, 16)
	end
	
	def fetch_word_value(instruction)
		Memory.word_from_little_endian_bytes(fetch_byte(instruction), fetch_byte(instruction))
	end
	
	# -----------------------------------------------------------------
	# Helper Methods
	# -----------------------------------------------------------------
	
	def add_operands_by_direction_flag(instruction, operand1, reg_operand, direction_bit)
		if direction_bit == 1
			instruction.operands << reg_operand
			instruction.operands << operand1
		else
			instruction.operands << operand1
			instruction.operands << reg_operand
		end
	end
	
	def decode_display_for_signed_ip_offset_for(instruction, operand)
		new_instruction_pointer = current_ip_adjusted_for(instruction) + operand.value
		operand.string = new_instruction_pointer.to_hex_string(4)
	end
	
	# Helper method to fetch or return if already fetched the second byte
	# of an instruction - specifically for retrieving the Mod R/M byte
	# whether we are in the primary or secondary opcode tables
	def retrieve_second_byte_for(instruction)
		instruction.bytes[1] || fetch_byte(instruction)
	end
	
	# -----------------------------------------------------------------
	# Setup Methods
	# -----------------------------------------------------------------
	
	def preload_rm_index_operands
		@rm_index_operands = [
		                       [ "BX + SI", [@bx, @si] ],
		                       [ "BX + DI", [@bx, @di] ],
		                       [ "BP + SI", [@bp, @si] ],
		                       [ "BP + DI", [@bp, @di] ],
		                       [ "SI", [@si] ],
		                       [ "DI", [@di] ],
		                       [ "BP", [@bp] ],
		                       [ "BX", [@bx] ]
		                     ]
	end
	
	def preload_register_operands
		@register_operands_16 = [ @ax, @cx, @dx, @bx, @sp, @bp, @si, @di ].collect do |register|
			RegisterAccess.new(register)
		end
		
		split_registers = [ @ax, @cx, @dx, @bx ]
		@register_operands_8 = []
		
		split_registers.each do |register|
			@register_operands_8 << RegisterAccess.new(register, :low)
		end
		
		split_registers.each do |register|
			@register_operands_8 << RegisterAccess.new(register, :high)
		end
		
		@segment_register_operands = [ @es, @cs, @ss, @ds ].collect do |register|
			RegisterAccess.new(register)
		end
	end
	
	def read_opcodes_from(file)
		lines = file.readlines.map { |line| line.strip }
		@ops_symbols = read_symbols_from lines[ 29...lines.size ]
		@primary_opcode_table = opcode_table_from(lines[ 2..17 ])
		@secondary_opcode_table = opcode_table_from(lines[ 21..27 ])
	end
	
	def opcode_table_from(lines)
		opcode_table = []
		lines.each do |line|
			codes = line[3..line.size].strip.split(/\s+/).collect { |code| code.to_i }
			code_row = []
			
			index = 0
			until index >= codes.size
				opcode_index = codes[index]
				addr_mode_index = codes[index+1]
				unless opcode_index.to_i == 999
					opcode = @ops_symbols[opcode_index][:symbol]
					addr_mode = @ops_symbols[addr_mode_index][:symbol]
				else
					opcode = :execute_illegal_opcode
					addr_mode = :decode_illegal_addr_mode
				end
				
				code_row << [ { :opcode => opcode,
												:decode_with => "decode_#{addr_mode}".to_sym,
												:addr_mode => addr_mode,
												:execute_with => "execute_#{opcode}".to_sym },
											opcode_index
				            ]
				index += 2
			end
			
			opcode_table << code_row
		end
		
		return opcode_table
	end
	
	def read_symbols_from(lines)
		ops_symbols = {}
		lines.each do |line|
			unless line.empty?
				line =~ /(\S+)\s+=\s+(\d+);\s+\{ (.+) \}/
				key = ($2).to_i
				symbol = ($1).to_sym
				ops_symbols[key] = { :symbol => symbol, :description => $3 }
			end
		end
		
		return ops_symbols
	end
	
	class IllegalAddressingMode < StandardError; end
end
