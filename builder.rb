# builder.rb
# Script principal qui orchestre le processus de compilation et de déploiement

require 'fileutils'
require './web_builder.rb'

# Vérifie si un argument est passé au script
# run_server = ARGV.include?("--serve")
# update_mode = ARGV.include?("--update")
# build_opal = !ARGV.include?("--skip-opal")
# build_wasm = !ARGV.include?("--skip-wasm")

# Définir les noms de fichiers
html_builder = "html_builder.rb"
# web_builder = "web_builder.rb"
hot_reloader= "hot_reloader.rb"

# Installer les dépendances
puts "Installing dependencies..."
system("bundle install")

# Créer le dossier build s'il n'existe pas
FileUtils.mkdir_p("build")

# Vérifier que les fichiers existent avant de les exécuter
unless File.exist?(html_builder)
  puts "Error: #{html_builder} not found."
  exit 1
end


web_builder = BuilderScript.new
web_builder.run
# unless File.exist?(web_builder)
#   puts "Error: #{web_builder} not found."
#   exit 1
# end

# # Construire les arguments pour web_builder.rb
# web_builder_args = []
# web_builder_args << "--update" if update_mode
# web_builder_args << "--skip-opal" unless build_opal
# web_builder_args << "--skip-wasm" unless build_wasm

# Exécuter les scripts Ruby
puts "Running #{html_builder}..."
system("ruby #{html_builder}")

# puts "Running #{web_builder} #{web_builder_args.join(' ')}..."
# system("ruby #{web_builder} #{web_builder_args.join(' ')}")

puts "All build scripts have been executed successfully."

# Lancer le hot reloader dans un processus enfant (non bloquant) si demandé
# if run_server
#   puts "Starting development server with hot reloading..."
#
#   # Lancer le serveur dans un processus enfant (non bloquant)
#   server_pid = fork do
#     # Remplacer le processus enfant par le serveur
#     exec("ruby -run -ehttpd ./build -p8000")
#   end
#
#
#   # Attendre que l'utilisateur interrompe le programme
#   puts "Server running at http://localhost:8000/"
#   puts "Press Ctrl+C to stop..."
#
#   begin
#     Process.wait
#   rescue Interrupt
#     puts "Shutting down server and hot reloader..."
#     Process.kill("TERM", server_pid) if server_pid
#     Process.kill("TERM", hot_reloader_pid) if hot_reloader_pid
#   end
# else
#   # puts "To start the server with hot reloading, run: ruby builder.rb --serve"
# end

# # Lancer le hot reloader
# hot_reloader_pid = fork do
#
# end

exec("ruby #{hot_reloader}")