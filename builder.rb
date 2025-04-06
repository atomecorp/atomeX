# launcher.rb

# Ce script lance deux autres scripts Ruby : html_builder.rb et web_builder.rb

# Définir les noms de fichiers
html_builder = "html_builder.rb"
web_builder = "web_builder.rb"

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

puts "Both scripts have been executed successfully."

# Lancer le serveur dans un processus enfant (non bloquant)
server_pid = fork do
  # Remplacer le processus enfant par le serveur
  exec("ruby -run -ehttpd ./build -p8000")
end

# # Attendre un instant pour permettre au serveur de démarrer
# sleep(1)
#
# # Détecter le système d'exploitation et ouvrir le navigateur avec l'URL du serveur
# require 'rbconfig'
# host_os = RbConfig::CONFIG['host_os']
#
# if host_os =~ /darwin/
#   system "open http://localhost:8000"
# elsif host_os =~ /linux|bsd/
#   system "xdg-open http://localhost:8000"
# elsif host_os =~ /mswin|mingw|cygwin/
#   system "start http://localhost:8000"
# else
#   puts "Système d'exploitation non reconnu : veuillez ouvrir manuellement http://localhost:8000 dans votre navigateur."
# end
#
# # Trapper les signaux pour s'assurer que le serveur est terminé lorsque le script se ferme
# Signal.trap("INT")  { Process.kill("TERM", server_pid); exit }
# Signal.trap("TERM") { Process.kill("TERM", server_pid); exit }
# Signal.trap("HUP")  { Process.kill("TERM", server_pid); exit }
#
# # Attendre la fin du processus serveur
# Process.wait(server_pid)