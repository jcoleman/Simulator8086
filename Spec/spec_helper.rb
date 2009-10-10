#
#  spec_helper.rb
#  MacRuby-Sim8086
#
#  Created by James Coleman on 10/10/09.
#  Copyright (c) 2009 Radiadesign. All rights reserved.
#

$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../Vendor/RSpec/lib/')
require 'spec/autorun'

framework 'Cocoa'

# Loading all the Ruby project files.
dir_path = File.expand_path(File.dirname(__FILE__) + '/../Classes/')
Dir.entries(dir_path).each do |path|
  if path != File.basename(__FILE__) and path[-3..-1] == '.rb'
    require(dir_path + '/' + path)
  end
end