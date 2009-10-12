#
#  ApplicationController.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/07/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

require "table_view_source"


class ApplicationController
	
	attr_accessor :main_window, :inspector, :registers_checksum_label, :memory_checksum_label
	attr_accessor :ax_label, :bx_label, :cx_label, :dx_label, :di_label, :si_label, :cs_label
	attr_accessor :ds_label, :es_label, :ss_label, :ip_label, :bp_label, :sp_label, :flags_label
	attr_accessor :of_display, :df_display, :if_display, :tf_display, :sf_display, :zf_display
	attr_accessor :af_display, :pf_display, :cf_display, :object_file_label, :preload_os
	attr_accessor :memory_display, :stack_display, :instruction_display, :interrupt_window
	attr_accessor :memory_display_source, :start_toolbar_item, :stop_toolbar_item
	attr_accessor :start_menu_item, :stop_menu_item, :step_instruction_button, :single_step_menu_item
	
	def initialize
		# The main simulator object
		initialize_processor_with_hooks
		
		# Options
		@update_registers = true
		@update_checksums = true
		@preload_os = true
		@registers_display_base = 16
	end
	
	def initialize_processor_with_hooks
		@processor = Processor.new(NSBundle.mainBundle.resourcePath.fileSystemRepresentation)
		@processor.after_decode do |instruction|
			instruction_address = Memory.segment_offset_string_from instruction.segment, instruction.pointer
			@instruction_display_source.executed_instructions << { address: instruction_address,
																														 raw_instruction: instruction.bytes.collect { |b| b.to_hex_string(2) }.join,
																														 assembly_instruction: instruction.opcode.to_s << ' ' << instruction.operands.join(', '),
																														 mode: instruction.addressing_mode }
			refresh_all_displays
		end
	end
		
	def submit_checksums_to_db(sender)
		db = SimulatorDatabase.new("css.cs.bju.edu", 1433, "sim86", "sim86fall2009", "jcole358")
		db.insert_checksums @last_loaded_object, @processor.registers_checksum, @processor.memory_checksum
	end
	
	def reset_simulator(sender)
		initialize_processor_with_hooks
		initialize_all_displays
		refresh_all_displays
	end
	
	def choose_hardware_interrupt(sender)
		@interrupt_window.makeKeyAndOrderFront(sender)
	end
	
	def send_interrupt(sender)
		
	end
	
	def load_module(sender)
		initialize_processor_with_hooks
		
		open_dialog = NSOpenPanel.openPanel
		#runModalForDirectory:file:types:
		if open_dialog.runModalForDirectory(nil, file:nil, types:["obj"]) == NSOKButton
			file = open_dialog.filenames[0]
			object = MemoryObject.new(File.new file)
			@last_loaded_object = File.basename(file.to_s)
			@object_file_label.setStringValue @last_loaded_object
			# Preload Sim86OS here
			@processor.load_object object
		end
		
		initialize_all_displays
		refresh_all_displays
	end
	
	def initialize_all_displays
		initialize_memory_display
		initialize_stack_display
		initialize_instruction_display
	end
	
	def refresh_all_displays
		refresh_registers_display
		refresh_checksum_display
		refresh_flags_display
		refresh_memory_display
		refresh_instruction_display
	end
	
	def initialize_memory_display
		@memory_display_source = TableViewSource::MemoryView.new(@processor.ram)
		@memory_display.dataSource = @memory_display_source
	end
	
	def refresh_memory_display
		@memory_display.reloadData
	end
	
	def initialize_stack_display
		@stack_display_source = TableViewSource::StackView.new(@processor)
		@stack_display.dataSource = @stack_display_source
	end
	
	def refresh_stack_display
		@stack_display.reloadData
	end
	
	def initialize_instruction_display
		@instruction_display_source = TableViewSource::ExecutedInstructionView.new
		@instruction_display.dataSource = @instruction_display_source
	end
	
	def refresh_instruction_display
		@instruction_display.reloadData
		@instruction_display.scrollRowToVisible(@instruction_display.numberOfRows - 1)
	end
	
	def refresh_checksum_display
		@registers_checksum_label.setStringValue @processor.registers_checksum
		@memory_checksum_label.setStringValue @processor.memory_checksum
	end
	
	def refresh_registers_display
		register_values = @processor.register_values
		base = @registers_display_base
		@ax_label.setStringValue storage_word_to_numeric_string(register_values[:ax], base)
		@bx_label.setStringValue storage_word_to_numeric_string(register_values[:bx], base)
		@cx_label.setStringValue storage_word_to_numeric_string(register_values[:cx], base)
		@dx_label.setStringValue storage_word_to_numeric_string(register_values[:dx], base)
		@di_label.setStringValue storage_word_to_numeric_string(register_values[:di], base)
		@si_label.setStringValue storage_word_to_numeric_string(register_values[:si], base)
		@cs_label.setStringValue storage_word_to_numeric_string(register_values[:cs], base)
		@ds_label.setStringValue storage_word_to_numeric_string(register_values[:ds], base)
		@es_label.setStringValue storage_word_to_numeric_string(register_values[:es], base)
		@ss_label.setStringValue storage_word_to_numeric_string(register_values[:ss], base)
		@ip_label.setStringValue storage_word_to_numeric_string(register_values[:ip], base)
		@bp_label.setStringValue storage_word_to_numeric_string(register_values[:bp], base)
		@sp_label.setStringValue storage_word_to_numeric_string(register_values[:sp], base)
		@flags_label.setStringValue storage_word_to_numeric_string(register_values[:flags], base)
	end
	
	def refresh_flags_display
		flag_values = @processor.flag_values
		@of_display.setIntValue flag_values[:of]
		@df_display.setIntValue flag_values[:df]
		@if_display.setIntValue flag_values[:if]
		@tf_display.setIntValue flag_values[:tf]
		@sf_display.setIntValue flag_values[:sf]
		@zf_display.setIntValue flag_values[:zf]
		@af_display.setIntValue flag_values[:af]
		@pf_display.setIntValue flag_values[:pf]
		@cf_display.setIntValue flag_values[:cf]
	end
	
	def show_inspector(sender)
	  @inspector.makeKeyAndOrderFront(sender)
	end
	
	def display_registers_as(sender)
		@registers_display_base = (sender.selectedSegment == 0 ? 16 : 2)
		refresh_registers_display
	end
	
	def should_preload_os(sender)
		@preload_os = !@preload_os
		sender.setTitle((@preload_os ? "Disable " : "Enable ") + "OS Preload")
	end
	
	def registers_should_update(sender)
	  @update_registers = sender.state == NSOnState
	end
	
	def checksums_should_update(sender)
		@update_checksums = sender.state == NSOnState
	end
	
	def prepare_for_execution
		@executing = true
		@start_menu_item.action = nil
		@start_toolbar_item.action = nil
		@step_instruction_button.action = nil
		@single_step_menu_item.action = nil
		@stop_menu_item.action = 'stop_execution:'
		@stop_toolbar_item.action = 'stop_execution:'
	end
	
	def end_execution
		@executing = false
		@start_menu_item.action = 'start_execution:'
		@start_toolbar_item.action = 'start_execution:'
		@step_instruction_button.action = 'step_execute_instruction:'
		@single_step_menu_item.action = 'step_execute_instruction:'
		@stop_menu_item.action = nil
		@stop_toolbar_item.action = nil
	end
	
	def start_execution(sender)
		prepare_for_execution
		
		@thread = Thread.new do
			ret = nil
			until ret == false || @executing == false
				ret = @processor.process_instruction
				sleep 0.1
			end
			end_execution
		end
	end
	
	def stop_execution(sender)
		end_execution
	end
	
	def step_execute_instruction(sender)
		@processor.process_instruction
		refresh_all_displays
	end
	
	def storage_word_to_numeric_string(word, base)
		word_length = 4 # default to hex
		word_length = 16 if base == 2
		
		word.to_s(base).upcase.rjust(word_length, '0').insert(word_length/2, ' ')
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
		
		initialize_all_displays
		refresh_all_displays
	end
	
	def applicationWillTerminate(notification)
		Kernel.puts "\nApplication will terminate."
	end
	
end
