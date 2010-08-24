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
        return TerminalInput.new(port, size)
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
  
  def to_s
    @port.to_s
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
  
  def self.terminal_window=(window)
    @@terminal_window = window
  end
  
  def write(value, processor = nil)
    @@terminal_window.print value.chr
  end
  
end

class TerminalInput < IOAccess
  
  def self.character_queue=(character_queue)
    @@character_queue = character_queue
  end
  
  # Returns the last character added to the queue or blocks until one is added
  def read
    @@character_queue.pop
  end
  
  def add_character(char)
    @@character_queue.push char
  end
  
end