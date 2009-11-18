# io_access.rb
# MacRuby-Sim8086
#
# Created by James Coleman on 11/11/09.
# Copyright 2009 Radiadesign. All rights reserved.



class IOAccess
	
	def initialize(port, size)
		@port, @size = port, size
	end
	
	def self.for_port(port, size)
		case port
			when 1
			when 2
				return TerminalOutput.new(port, size)
			when 3
				return SpeakerSimulator.new(port, size)
		end
	end
	
	def read
		case @size
			when 8
				
			when 16
				
		end
	end
	
	def write(value, processor=nil)
		case @size
			when 8
				
			when 16
				
		end
	end
	
end

class SpeakerSimulator < IOAccess
	
	def self.initialize_audio_system
		require 'sine_generator'
		@@audio_device = Object::SineGenerator.new
		@@audio_device.initAudio
	end
	
	def write(value, processor)
		@@audio_device.play_sine_wave(value.to_f, seconds: (processor.cx.value.to_f / processor.bx.value) / 1000)
	end
	
end

class TerminalOutput < IOAccess
	
	def write(value, processor = nil)
		print value.chr
	end
	
end