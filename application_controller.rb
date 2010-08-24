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
  attr_accessor :next_instr_raw_label, :next_instr_op_label, :next_instr_mode_label
  attr_accessor :terminal_window_view, :terminal_window, :send_interrupt_text_field
  
  def initialize
    # The main simulator object
    initialize_processor_with_hooks
    
    # Options
    @update_registers = true
    @update_checksums = true
    @update_all_displays = true
    @preload_os = true
    @log_to_database = false
    @registers_display_base = 16
  end
  
  def initialize_processor_with_hooks
    @processor = Processor.new(NSBundle.mainBundle.resourcePath.fileSystemRepresentation)
    @processor.after_execute do |instruction|
      instruction_address = Memory.segment_offset_string_from instruction.segment, instruction.pointer
      @instruction_display_source.executed_instructions << { address: instruction_address,
                                                             raw_instruction: instruction.bytes.collect { |b| b.to_hex_string(2) }.join,
                                                             assembly_instruction: instruction.opcode.to_s << ' ' << instruction.operands.join(', '),
                                                             mode: instruction.addressing_mode }
      refresh_all_displays
    end
    @next_instruction = nil
  end
    
  def submit_checksums_to_db(sender)
    db = SimulatorDatabase.new("css.cs.bju.edu", 1433, "sim86", "sim86fall2009", "jcole358")
    db.insert_checksums @last_loaded_object, @processor.registers_checksum, @processor.memory_checksum
  end
  
  def submit_results_to_db(sender)
    db = SimulatorDatabase.new("css.cs.bju.edu", 1433, "sim86", "sim86fall2009", "jcole358")
    instruction = @instruction_display_source.executed_instructions[-1]
    disassembly = instruction[:address].to_s + ' ' << instruction[:raw_instruction].to_s << ' ' << instruction[:assembly_instruction].to_s << ' ' << instruction[:mode].to_s
    db.insert_results @last_loaded_object, @processor.instruction_count, disassembly, @processor.addr_modes[instruction[:mode].to_sym].to_s, @processor.registers.collect { |reg| reg.value }, @processor.memory_checksum
  end
  
  def reset_simulator(sender)
    end_execution
    initialize_processor_with_hooks
    initialize_all_displays
    refresh_all_displays(true)
  end
  
  def choose_hardware_interrupt(sender)
    @interrupt_window.makeKeyAndOrderFront(sender)
  end
  
  def send_interrupt(sender)
    @processor.queue_interrupt(@send_interrupt_text_field.stringValue.to_i)
  end
  
  def send_nmi_interrupt(sender)
    @processor.queue_interrupt(2)
  end
  
  def load_module(sender)
    initialize_processor_with_hooks
    
    open_dialog = NSOpenPanel.openPanel
    if open_dialog.runModalForDirectory(nil, file:nil, types:["obj"]) == NSOKButton
      # Preload Sim86OS here
      if @preload_os
        sim86os_file = NSBundle.mainBundle.resourcePath.fileSystemRepresentation + "/Sim86OS.obj"
        @processor.load_object MemoryObject.new(File.new sim86os_file)
      end
      
      file = open_dialog.filenames[0]
      @processor.load_object MemoryObject.new(File.new file)
      
      @last_loaded_object = File.basename(file.to_s)
      @object_file_label.setStringValue @last_loaded_object
      
      get_next_instruction
    end
    
    initialize_all_displays
    refresh_all_displays(true)
  end
  
  def initialize_all_displays
    initialize_memory_display
    initialize_stack_display
    initialize_instruction_display
    intitialize_terminal_display
  end
  
  def refresh_all_displays(force=false)
    if @update_all_displays || force
      refresh_registers_display
      refresh_checksum_display
      refresh_flags_display
      refresh_memory_display
      refresh_stack_display
      refresh_instruction_display
      refresh_next_instruction_display
    end
  end
  
  def refresh_next_instruction_display
    if @next_instruction
      @next_instr_raw_label.stringValue = @next_instruction.bytes.collect { |b| b.to_hex_string(2) }.join
      @next_instr_op_label.stringValue = @next_instruction.opcode.to_s << ' ' << @next_instruction.operands.join(', ')
      @next_instr_mode_label.stringValue = @next_instruction.addressing_mode
    else
      @next_instr_raw_label.stringValue = ''
      @next_instr_op_label.stringValue = ''
      @next_instr_mode_label.stringValue = ''
    end
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
  
  def intitialize_terminal_display
    @terminal_window_view.reinitialize
    TerminalInput.character_queue = @terminal_window_view.character_queue
    TerminalOutput.terminal_window = @terminal_window_view
  end
  
  def refresh_checksum_display
    @registers_checksum_label.stringValue = @processor.registers_checksum.to_s
    @memory_checksum_label.stringValue = @processor.memory_checksum.to_s
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
  
  def show_terminal_window(sender)
    @terminal_window.makeKeyAndOrderFront(sender)
  end
  
  def display_registers_as(sender)
    @registers_display_base = (sender.selectedSegment == 0 ? 16 : 2)
    refresh_registers_display
  end
  
  def should_preload_os(sender)
    @preload_os = !@preload_os
    sender.setTitle((@preload_os ? "Disable " : "Enable ") + "OS Preload")
  end
  
  def should_update_displays(sender)
    @update_all_displays = !@update_all_displays
    sender.setTitle((@update_all_displays ? "Disable " : "Enable ") + "Display Updates")
  end
  
  def should_log_to_database(sender)
    @log_to_database = !@log_to_database
    sender.setTitle((@log_to_database ? "Disable " : "Enable ") + "DB Logging")
  end
  
  def prepare_for_execution
    @execution_stopped = false
    @executing = true
    @start_menu_item.action = ''
    @start_toolbar_item.action = ''
    @step_instruction_button.action = ''
    step_instruction_button.enabled = false
    @single_step_menu_item.action = ''
    @stop_menu_item.action = 'stop_execution:'
    @stop_toolbar_item.action = 'stop_execution:'
  end
  
  def end_execution
    @execution_stopped = true
    @start_menu_item.action = 'start_execution:'
    @start_toolbar_item.action = 'start_execution:'
    @step_instruction_button.action = 'step_execute_instruction:'
    @single_step_menu_item.action = 'step_execute_instruction:'
    step_instruction_button.enabled = true
    @stop_menu_item.action = ''
    @stop_toolbar_item.action = ''
  end
  
  def start_execution(sender)
    prepare_for_execution
    
    @thread = Thread.new do
      execution_time = Time.new
      while @executing && !@execution_stopped
        process_instruction
      end
      puts "Execution cycle lasted #{Time.new - execution_time} seconds."
      puts "Total instructions executed so far (per module load): #{@processor.instruction_count}"
      end_execution
      refresh_all_displays(true)
    end
  end
  
  def stop_execution(sender)
    end_execution
  end
  
  def get_next_instruction
    begin
      @next_instruction = @processor.decode(@processor.fetch)
    rescue => e
      puts e
      @next_instruction = nil
    end
  end
  
  def process_instruction
    @processor.execute(@next_instruction)
    submit_results_to_db(nil) if @log_to_database
    @executing = @processor.state == :EXECUTION_STATE
    get_next_instruction
    refresh_next_instruction_display if @should_update_displays
  end
  
  def step_execute_instruction(sender)
    Thread.new do
      prepare_for_execution
      
      begin
        process_instruction
      rescue => e
        puts "Caught error"
        puts e
      end
      refresh_all_displays(true)
      
      end_execution
    end
  end
  
  def manually_refresh_display(sender)
    refresh_all_displays(true)
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
    puts  "\nIts window is: #{@main_window.inspect}"
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
  
  def windowWillClose(notification)
    NSApp.terminate self
  end
  
end
