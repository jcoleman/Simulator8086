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
	
	
	
	# -----------------------------------------------------------------
	# OpCode Setup Methods
	# -----------------------------------------------------------------
	
	def read_opcodes_from(file)
		lines = file.readlines.map { |line| line.strip }
		@ops_symbols = read_symbols_from lines[ 29...lines.size ]
		@primary_opcode_table = opcode_table_from(lines[ 2..17 ])
		print @primary_opcode_table
		puts nil
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
						:addr_mode => addr_mode }
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
				ops_symbols[($2).to_i] = { :symbol => ($1).to_sym, :description => $3 }
			end
		end
		
		return ops_symbols
	end
	
end
