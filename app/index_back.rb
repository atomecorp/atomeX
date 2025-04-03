require "js"

document = JS.global[:document]
output = document.getElementById('output')
output[:innerHTML] = "<h1>Hello from app/index.rb! jeezs!!! so cool!</h1> <H2>#{Time.now}</H2>"
puts "This goes to browser console"