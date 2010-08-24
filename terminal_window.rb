# terminal_window.rb
# MacRuby-Sim8086
#
# Created by James Coleman on 11/21/09.
# Copyright 2009 Radiadesign. All rights reserved.

require 'thread'

class TerminalWindow < NSView
  
  attr_writer :text_label
  attr_reader :character_queue
  
  def reinitialize
    @character_queue = Queue.new
    @lines = [""]
    draw_text
  end
  
  def keyDown(theEvent)
    @character_queue.push theEvent.characters.characterAtIndex(0)
  end
  
  def print(character)
    unless character == "\r"
      character == "\n" ? @lines << "" : @lines[-1] << character
      draw_text
    end
  end
  
  def draw_text
    @lines.delete_at(0) until @lines.size < 20
    @text_label.stringValue = @lines.join "\n"
  end
  
  def acceptsFirstResponder
    true
  end
  
  def becomeFirstResponder
    true
  end
  
  def resignFirstResponder
    true
  end
  
end