#require "memory"
#require "register"
#require "storage_access"
#require "utility"

class Processor
  
  def initialize
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
    
    # Memory
    @ram = Memory.new(32768, 0)
  end
	
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
  
	def segment_register_from_id(id)
		@segment_registers[id]
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
  
  def print_checksums
    puts "Register checksum: #{checksum_registers}"
    puts "RAM checksum: #{@ram.checksum}"
  end
  
end