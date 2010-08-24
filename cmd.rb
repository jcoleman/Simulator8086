#framework 'Cocoa'

# Loading all the Ruby project files.
@dir_path = (`pwd`).chomp
#@dir_path << '/'

puts @dir_path


#Dir.entries(@dir_path).each do |path|
#  if path != File.basename(__FILE__) and path[-3..-1] == '.rb'
#    require(path)
#  end
#end

require 'extension'
require 'memory'
require 'memory_object'
require 'storage_access'
require 'memory_stack'
require 'register'
require 'utility'
require 'processor_constants'
require 'instruction'
require 'executor'
require 'decoder'
require 'processor'


def get_next_instruction
  @next_instruction = @processor.decode(@processor.fetch)
end

def process_instruction
  @processor.execute(@next_instruction)
  @executing = @processor.state == :EXECUTION_STATE
  get_next_instruction
end

def test
  puts "Setting up processor"
  @processor = Processor.new(@dir_path)
  puts "Done creating processor object"
  
  puts "Loading object"
  object = MemoryObject.new(File.new '../mini_full_looped.obj')
  @processor.load_object object
  puts "Done loading object"
  #get_next_instruction

  execution_time = Time.new
  @executing = true
  
  puts "Beginning execution"
  while @executing
    #process_instruction
    @processor.execute @processor.decode(@processor.fetch)
    @executing = @processor.state == :EXECUTION_STATE
  end

  puts "Execution cycle lasted #{Time.new - execution_time} seconds."
  puts "Total instructions executed so far (per module load): #{@processor.instruction_count}"
end

test