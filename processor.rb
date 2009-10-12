require 'processor_constants'

class Processor
  
	include ProcessorConstants
	include Decoder
	include Executor
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
		
		# Split the byte into the two nybbles for lookup purposes
		hi = initial_byte >> 4
		lo = initial_byte & 0x0F
		
		# Look up the two nybbles to decode the opcode and addressing mode
		op_with_addr_mode = @primary_opcode_table[hi][lo]
		
		segment = @cs.value
		pointer = @ip.value - 1
		instruction = Instruction.new(op_with_addr_mode, segment, pointer)
		instruction.bytes << initial_byte
		
		# Decode the addressing mode to gather the operands
		self.send(instruction.decoder_function, instruction)
		
		@after_decode.call(instruction) if @after_decode
		
		return instruction
	end
	
	def execute(instruction)
		@before_execute.call if @before_execute
		
		# Execute the instruction
		self.send(instruction.executor_function, *instruction.operands)
		
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
    @ax = Register.new :ax
    @bx = Register.new :bx
    @cx = Register.new :cx
    @dx = Register.new :dx
    @di = Register.new :di
    @si = Register.new :si
    @cs = Register.new :cs
    @ds = Register.new :ds
    @es = Register.new :es
    @ss = Register.new :ss
    @ip = Register.new :ip
    @bp = Register.new :bp
    @sp = Register.new :sp
    @flags = Register.new :flags
    
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
		
		preload_register_operands
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