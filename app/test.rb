# puts "output from local required file works!"
# puts '==========success!==============='
#
# require 'js'
# JS.global[:document].write "Hello, jeezs!"


puts "second message from require.rb"
doc = JS.global[:document]
body = doc[:body]
output_div = doc.createElement('div')
output_div[:id] = 'output'
body.appendChild(output_div)
output = doc.getElementById('output')
output[:innerHTML] = "<h1>Hello from requires code!</h1><h2>#{Time.now}</h2>"
JS.global[:console].log("Require message in the console")
