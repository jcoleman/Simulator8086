#
# rb_main.rb
# MacRuby-Sim8086
#
# Created by James Coleman on 9/13/09.
# Copyright __MyCompanyName__ 2009. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.

#$:.map! { |x| x.sub(/^\/Library\/Frameworks/, NSBundle.mainBundle.privateFrameworksPath) }
#$:.unshift NSBundle.mainBundle.resourcePath.fileSystemRepresentation

framework 'Cocoa'

# Loading all the Ruby project files.
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.entries(dir_path).each do |path|
  if path != File.basename(__FILE__) and path[-4..-1] =~ /\.rb/
    require(path)
  end
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
