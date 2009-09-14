#
#  ApplicationController.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/07/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

class ApplicationController
	
	attr_accessor :main_window, :inspector, :registers_checksum_label, :memory_checksum_label
	attr_accessor :ax_label, :bx_label, :cx_label, :dx_label, :di_label, :si_label, :cs_label
	attr_accessor :ds_label, :es_label, :ss_label, :ip_label, :bp_label, :sp_label, :flags_label
	attr_accessor :calculator_result_label, :calculator_input1, :calculator_input2, :loop_label
	
	# The main simulator object
	@processor = nil
	
	# Options
	@update_registers = true
	@update_checksums = true
	
	@thread = nil
	
	def calculator_action(sender)
		op = sender.title
		input1 = @calculator_input1.stringValue
		input2 = @calculator_input2.stringValue
		@calculator_result_label.setFont NSFont.fontWithName("Andale Mono", size:12)
		@calculator_result_label.setStringValue eval("0x#{input1} #{op} 0x#{input2}").to_i.to_s(16)
	end
	
	def loop_action(sender)
		begin
			unless @thread
				@thread = Thread.new(@loop_label) do |loop_label|
					@loop_value = 0
					loop do
						loop_label.setStringValue @loop_value.to_s
						puts @loop_value
						sleep 0.2
						@loop_value += 1
					end
				end
			end
		rescue Exception => e
			puts "Caught #{e}"
		end
	end
	
	def load_module(sender)
		@processor = Processor.new unless @processor
		
		open_dialog = NSOpenPanel.openPanel
		#runModalForDirectory:file:types:
		if open_dialog.runModalForDirectory(nil, file:nil, types:nil) == NSOKButton
			file = open_dialog.filenames[0]
			object = MemoryObject.new(File.new file)
			@processor.load_object object
		end
		
		refresh_checksum_display
		refresh_registers_display
	end
	
	def refresh_checksum_display
		@registers_checksum_label.setStringValue @processor.registers_checksum
		@memory_checksum_label.setStringValue @processor.memory_checksum
	end
	
	def refresh_registers_display
		register_values = @processor.register_values
		@ax_label.setStringValue storage_word_to_binary_string(register_values[:ax])
		@bx_label.setStringValue storage_word_to_binary_string(register_values[:bx])
		@cx_label.setStringValue storage_word_to_binary_string(register_values[:cx])
		@dx_label.setStringValue storage_word_to_binary_string(register_values[:dx])
		@di_label.setStringValue storage_word_to_binary_string(register_values[:di])
		@si_label.setStringValue storage_word_to_binary_string(register_values[:si])
		@cs_label.setStringValue storage_word_to_binary_string(register_values[:cs])
		@ds_label.setStringValue storage_word_to_binary_string(register_values[:ds])
		@es_label.setStringValue storage_word_to_binary_string(register_values[:es])
		@ss_label.setStringValue storage_word_to_binary_string(register_values[:ss])
		@ip_label.setStringValue storage_word_to_binary_string(register_values[:ip])
		@bp_label.setStringValue storage_word_to_binary_string(register_values[:bp])
		@sp_label.setStringValue storage_word_to_binary_string(register_values[:sp])
		@flags_label.setStringValue storage_word_to_binary_string(register_values[:flags])
	end
	
	def show_inspector(sender)
	  @inspector.makeKeyAndOrderFront(sender)
	end
	
	def registers_should_update(sender)
	  @update_registers = sender.state == NSOnState
	end
	
	def checksums_should_update(sender)
		@update_checksums = sender.state == NSOnState
	end
	
	def storage_word_to_binary_string(word)
		binary = word.to_s(2)
		("0" * (16 - binary.size) << binary).insert 8, ':'
	end
	
	def awakeFromNib
		# All the application delegate methods will be called on this object.
		NSApp.delegate = self
		
		puts "ApplicationController awoke."
		puts "Edit: app/controllers/application_controller.rb"
		puts	"\nIts window is: #{@main_window.inspect}"
	end
	
	# NSApplication delegate methods
	def applicationDidFinishLaunching(notification)
		Kernel.puts "\nApplication finished launching."
		puts "Ruby interpreter: #{RUBY_VERSION}"
	end
	
	def applicationWillTerminate(notification)
		Kernel.puts "\nApplication will terminate."
	end
	
end
