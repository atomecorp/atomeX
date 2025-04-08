puts "output from local required file works!"
puts '==========success==============='

require 'js'
JS.global[:document].write "Hello, jeezs!"
