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
					address.to_s(16).upcase.rjust(4, '0').insert(2, ' ')
			end
		end
		
		def raw_data_from_bytes(bytes)
			display_bytes = bytes.map do |byte|
				byte_string = byte.to_s(16).upcase.rjust(2, '0')
			end
			
			display_string = ""
			display_bytes.each_with_index do |display_byte, i|
				display_string << display_byte
				display_string << (i == 7 ? '-' : ' ') unless i == 15
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
