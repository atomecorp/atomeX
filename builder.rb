# builder.rb

# Ce script lance deux autres scripts Ruby : html_builder.rb et web_builder.rb

system("bundle install")


# Définir les noms de fichiers
html_builder = "html_builder.rb"
web_builder = "web_builder.rb"
hot_reloader= "hot_reloader.rb"

# Vérifier que les fichiers existent avant de les exécuter
unless File.exist?(html_builder)
  puts "Error: #{html_builder} not found."
  exit 1
end

unless File.exist?(web_builder)
  puts "Error: #{web_builder} not found."
  exit 1
end

# Exécuter les scripts Ruby

puts "Running #{html_builder}..."
system("ruby #{html_builder}")

puts "Running #{web_builder}..."
system("ruby #{web_builder}")

puts "Running #{hot_reloader}..."
system("ruby #{hot_reloader}")



puts "Both scripts have been executed successfully."

# Lancer le serveur dans un processus enfant (non bloquant)
# server_pid = fork do
#   # Remplacer le processus enfant par le serveur
#   exec("ruby -run -ehttpd ./build -p8000")
# end
