require 'listen'

listener = Listen.to('app/') do |_modified, _added, _removed|
  puts "🔁 Fichier modifié, recompilation..."
  # system("cat build/app/index.rb | opal --no-opal --compile --enable-source-location - > build/application.js")
end

puts "👂 Watching app/ pour hot reload avec Opal..."
listener.start
sleep