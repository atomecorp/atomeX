doc = JS.global[:document]
body = doc[:body]

output_div = doc.createElement('div')
output_div[:id] = 'first_one'

body.appendChild(output_div)

output = doc.getElementById('first_one')
output[:innerHTML] = "<h1>Hello from a required file</h1><h2>#{Time.now}</h2>"
