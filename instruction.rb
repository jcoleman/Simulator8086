#
#  instruction.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 9/28/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

class Instruction
  attr_accessor :operands, :bytes
  attr_reader :opcode, :addressing_mode, :segment, :pointer
  attr_reader :decoder_function, :executor_function
  
  def initialize(segment, pointer)
    @segment, @pointer = segment, pointer
    @operands = []
    @bytes = []
  end
  
  def initialize_op_and_addr_mode(op_with_addr_mode)
    @opcode = op_with_addr_mode[:opcode]
    @addressing_mode = op_with_addr_mode[:addr_mode]
    @decoder_function = op_with_addr_mode[:decode_with]
    @executor_function = op_with_addr_mode[:execute_with]
  end
end
