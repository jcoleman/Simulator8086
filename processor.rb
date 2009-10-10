require 'processor_constants'

class Processor
  
	include ProcessorConstants
	include Decoder
	include MemoryStack
	
	attr_reader :ram, :ss, :sp
	
  def initialize(base_path)
		@base_path = base_path
		
    initialize_registers
    initialize_memory
		initialize_decoder
		initialize_callbacks
  end
	
	# -----------------------------------------------------------------
	# Main Processor Execution-cycle Methods
	# -----------------------------------------------------------------
	
	def process_instruction
		execute(decode(fetch))
	end
	
	def fetch
		@before_fetch.call if @before_fetch
		
		instruction_segment = @cs.value
		instruction_pointer = @ip.value
		instruction_address = Memory.absolute_address_for instruction_segment, instruction_pointer
		@ip.value += 1 # Increment the instruction pointer
		byte = @ram.byte_at instruction_address
		
		@after_fetch.call(instruction_segment, instruction_pointer, byte) if @after_fetch
		return byte
	end
	
	def decode(initial_byte)
		@before_decode.call if @before_decode
		instruction = nil
		instruction = false if initial_byte == 0xF4
		@after_decode.call if @after_decode
	end
	
	def execute(instruction)
		@before_execute.call if @before_execute
		@after_execute.call if @after_execute
		return instruction
	end
	
	# -----------------------------------------------------------------
	# Execution-cycle Helper Methods
	# -----------------------------------------------------------------
	
	def segment_register_from_id(id)
		@segment_registers[id]
	end
	
	# -----------------------------------------------------------------
	# Callback Helper Methods
	# -----------------------------------------------------------------
	
	def before_fetch(&block)
		@before_fetch = block
	end
	
	def after_fetch(&block)
		@after_fetch = block
	end
	
	def before_decode(&block)
		@before_decode = block
	end
	
	def after_decode(&block)
		@after_decode = block
	end
	
	def before_execute(&block)
		@before_execute = block
	end
	
	def after_execute(&block)
		@after_execute = block
	end
	
	# -----------------------------------------------------------------
	# Initialization Helper Methods
	# -----------------------------------------------------------------
	
	def initialize_registers
		# Registers
    @ax = Register.new
    @bx = Register.new
    @cx = Register.new
    @dx = Register.new
    @di = Register.new
    @si = Register.new
    @cs = Register.new
    @ds = Register.new
    @es = Register.new
    @ss = Register.new
    @ip = Register.new
    @bp = Register.new
    @sp = Register.new
    @flags = Register.new
    
    @registers = [@ax, @bx, @cx, @dx, @sp, @bp, @si, @di, @cs, @ds, @ss, @es, @ip, @flags]
    @segment_registers = [@cs, @ds, @ss, @es]
	end
	
	def initialize_memory
		@ram = Memory.new(32768, 0)
	end
	
	def initialize_decoder
		File.open(@base_path + "/8086.ops") do |file|
			read_opcodes_from file
		end
	end
	
	def initialize_callbacks
		@before_fetch = nil
		@after_fetch = nil
		@before_decode = nil
		@after_decode = nil
		@before_execute = nil
		@after_execute = nil
	end
	
	# -----------------------------------------------------------------
	# External Access Helper Methods
	# -----------------------------------------------------------------
	
	def load_object(object)
		object.registers.each_with_index do |register_value, index|
      @registers[index].value = register_value
    end
		
		object.modules.each do |memory_module|		
			segment = segment_register_from_id(memory_module[:segment_register_id]).value
			memory_module[:address] = Memory.absolute_address_for segment, memory_module[:offset]
			@ram.load_module memory_module
		end
	end
	
	def register_values
		{ :ax => @ax.value,
			:bx => @bx.value,
			:cx => @cx.value,
			:dx => @dx.value,
			:di => @di.value,
			:si => @si.value,
			:cs => @cs.value,
			:ds => @ds.value,
			:es => @es.value,
			:ss => @ss.value,
			:ip => @ip.value,
			:bp => @bp.value,
			:sp => @sp.value,
			:flags => @flags.value }
	end
	
	def flag_values
		flags = @flags.value
		{ :of => flags[OVERFLOW_FLAG],
			:df => flags[DIRECTION_FLAG],
			:if => flags[INTERRUPT_FLAG],
			:tf => flags[TRACE_FLAG],
			:sf => flags[SIGN_FLAG],
			:zf => flags[ZERO_FLAG],
			:af => flags[AUX_CARRY_FLAG],
			:pf => flags[PARITY_FLAG],
			:cf => flags[CARRY_FLAG] }
	end
	
  def registers_checksum
    register_bytes = []
    
    @registers.each do |register|
      register_bytes << register.low
      register_bytes << register.high
    end
    Utility.checksum_byte_array(register_bytes)
  end
	
	def memory_checksum
		@ram.checksum
	end
  
  def print_registers
    @registers.each { |reg| puts reg.value.to_s(16) }
  end
  
end