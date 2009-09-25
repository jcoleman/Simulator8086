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
			bytes = @ram.bytes_at(16*index, 16)
			display_bytes = bytes.map do |byte|
				byte_string = byte.to_s(16)
				"0" * (2 - byte_string.size) << byte_string
			end
			
			display_string = ""
			display_bytes.each_with_index do |display_byte, i|
				display_string << display_byte << (i == 7 ? '-' : ' ')
			end
			
			return display_string
		end
		
	end
	
	class ExecutedInstructionView
	
		def initialize
			
		end
		
		def numberOfRowsInTableView(tableView)
		
		end
		
		def tableView(tableView, objectValueForTableColumn:tableColumn, row:index)
			
		end
		
	end
	
end
