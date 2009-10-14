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
		address = Memory.absolute_address_for @ds.value, offset
		
		if instruction.bytes.first[0] == 1 # W-bit
			# Word value
			accumulator = @register_operands_16[0] # AX register operand
			memory = MemoryAccess.new(@ram, address, 16)
		else
			# Byte value
			accumulator = @register_operands_8[0] # AL register
			memory = MemoryAccess.new(@ram, address, 8)
		end
		
		# Determine direction of operands
		if instruction.bytes.first[1] == 1 # !D-bit
			instruction.operands << memory
			instruction.operands << accumulator
		else
			instruction.operands << accumulator
			instruction.operands << memory
		end
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
		add_signed_immediate_byte_operand(instruction)
	end
	
	def decode_Intra(instruction)
		add_signed_immediate_word_operand(instruction)
	end
	
	def decode_Inter(instruction)
		add_immediate_word_operand(instruction)
		add_immediate_word_operand(instruction)
	end
	
	def decode_Acc(instruction)
		# Accumulator register, 8 or 16 bits
		if instruction.bytes.first[0] == 1 # W-bit
			instruction.operands << @register_operands_16[0] # AX register
		else
			instruction.operands << @register_operands_8[0] # AL register
		end
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
	
	def decode_illegal_addr_mode
		raise IllegalAddressingMode.new
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
	
	def add_signed_immediate_word_operand(instruction)
		word_value = fetch_word_value(instruction).to_fixed_size(16, true)
		instruction.operands << ImmediateValue.new(word_value, 16)
	end
	
	def add_signed_immediate_byte_operand(instruction)
		instruction.operands << ImmediateValue.new(fetch_byte(instruction).to_fixed_size(8, true), 8)
	end
	
	def fetch_word_value(instruction)
		Memory.word_from_little_endian_bytes(fetch_byte(instruction), fetch_byte(instruction))
	end
	
	# -----------------------------------------------------------------
	# Helper Methods
	# -----------------------------------------------------------------
	
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
	
	# -----------------------------------------------------------------
	# OpCode Setup Methods
	# -----------------------------------------------------------------
	
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
				code_row << { :opcode => opcode,
											:decode_with => "decode_#{addr_mode}".to_sym,
				              :addr_mode => addr_mode,
				              :execute_with => "execute_#{opcode}".to_sym }
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
