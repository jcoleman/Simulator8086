#
#  simulator_database.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/16/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

class SimulatorDatabase
	
	def initialize(host, port, user_id, password, logged_user)
		@user_id = user_id
		@password = password
		@host = host
		@port = port
		@logged_user = logged_user
	end
	
	def insert_checksums(object_name, registers_checksums, memory_checksum)
		call_database_procedure "ChecksumsInsert", "'#{object_name}'", registers_checksums, memory_checksum
	end
	
	def call_database_procedure(procedure, *parameters)
		sql = "exec #{procedure} #{@logged_user} "
		parameters.each { |param| sql << ", #{param}" }
		sql << '\ngo'
		
		cmd = "export TDSVER=7.0 && echo \"#{sql}\" | /usr/local/bin/tsql -H #{@host} -p #{@port} -U #{@user_id} -P #{@password}"
		`#{cmd}`
	end
	
end
