#
#  table_view_source.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/23/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

module TableViewSource

	class MemoryView
		
		def initialize(ram)
			@ram = ram
			@row_count = ram.byte_size / 16
		end
		
		def numberOfRowsInTableView(tableView)
			@row_count
		end
		
		def tableView(tableView, objectValueForTableColumn:tableColumn, row:index)
			address = index * 16
			bytes = bytes = @ram.bytes_at(address, 16)
			case tableColumn.identifier
				when 'raw'
					raw_data_from_bytes bytes
				when 'ascii'
					bytes.collect { |byte| (32 <= byte && byte <= 126) ? byte.chr : '.' }.join
				when 'address'
					address.to_hex_string(5)
			end
		end
		
		def raw_data_from_bytes(bytes)
			display_bytes = bytes.map do |byte|
				byte_string = byte.to_hex_string(2)
			end
			
			display_string = ""
			display_bytes.each_with_index do |display_byte, i|
				display_string << display_byte
				display_string << (i == 7 ? '-' : ' ') unless i == 15
			end
			
			return display_string
		end
		
	end
	
	class StackView
		
		def initialize(processor)
			@processor = processor
		end
		
		def numberOfRowsInTableView(tableView)
			stack_word_size = @processor.stack_word_size
			stack_word_size > 16 ? 16 : stack_word_size
		end
		
		def tableView(tableView, objectValueForTableColumn:tableColumn, row:index)
			case tableColumn.identifier
				when 'offset'
					@processor.stack_word_index_to_offset(index).to_hex_string(4)
				when 'raw'
					@processor.stack_word_at(index).to_hex_string(4).insert(2, ' ')
			end
		end
		
	end
	
	class ExecutedInstructionView
		
		attr_accessor :executed_instructions
		
		def initialize
			@executed_instructions = []
		end
		
		def numberOfRowsInTableView(tableView)
			@executed_instructions.size
		end
		
		def tableView(tableView, objectValueForTableColumn:tableColumn, row:index)
			@executed_instructions[index][tableColumn.identifier.to_sym]
		end
		
	end
	
	class StatisticsView
		
		attr_accessor :statistics
		
		def initialize
			@statistics = []
		end
		
		def numberOfRowsInTableView(tableView)
			@statistics.size
		end
		
		def tableView(tableView, objectValueForTableColumn:tableColumn, row:index)
			@statistics[index][tableColumn.identifier.to_sym].to_s
		end
		
	end
	
end
