# require "js"
#
# document = JS.global[:document]
# output = document.getElementById('output')
# output[:innerHTML] = "<h1>Hello from app/index.rb! jeezs!!! so cool!</h1> <H2>#{Time.now}</H2>"
# puts "This goes to browser console"



# Solution unifiée Opal et Ruby WASM
begin
  # Pour Opal: on a besoin d'importer le module Native explicitement
  require 'native'
rescue LoadError
  # En Ruby WASM, ce require échouera, c'est normal
end

# Harmonisation des APIs
if defined?(Native) && !defined?(JS)
  # Si on est dans Opal et pas de JS déjà défini
  module JS
    def self.global
      @global ||= Native(`window`)
    end
  end
elsif defined?(JS) && !defined?(Native)
  # Si on est dans Ruby WASM et pas de Native déjà défini
  module Native
    def self.[](obj)
      obj
    end
  end
end

# Utilisation unique pour les deux environnements
doc = JS.global[:document]
output = doc.getElementById('output')
output[:innerHTML] = "<h1>Hello from unified code!</h1><h2>#{Time.now}</h2>"
JS.global[:console].log("Message dans la console")