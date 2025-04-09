require './app/test.rb'
puts "first message from index.rb"
doc = JS.global[:document]
body = doc[:body]

output_div = doc.createElement('div')
output_div[:id] = 'output'
body.appendChild(output_div)
output = doc.getElementById('output')
output[:innerHTML] = "<h1>Hello from unified code! from atome</h1><h2>#{Time.now}</h2>"
JS.global[:console].log("Message in the console")
