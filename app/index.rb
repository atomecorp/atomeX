require "js"
begin
  # Pour Opal : on importe Native pour bénéficier de l'enrobage et de l'opérateur []
  require 'native'
rescue LoadError
  # En Ruby WASM, ce require échouera, c'est normal
end

if defined?(JS) && defined?(Native)
  # En Opal, JS et Native sont définis : on surcharge JS.global pour enrober window avec Native
  module JS
    class << self
      alias_method :original_global, :global unless method_defined?(:original_global)
      def global
        @global ||= Native(`window`)
      end
    end
  end
elsif defined?(JS) && !defined?(Native)
  # En Ruby WASM, si Native n'est pas défini, on le définit minimalement
  module Native
    def self.[](obj)
      obj
    end
  end
end

# Utilisation unique pour les deux environnements
doc = JS.global[:document]
output = doc.getElementById('output')
output[:innerHTML] = "<h1>Hello from unified code! from atome</h1><h2>#{Time.now}</h2>"
JS.global[:console].log("Message dans la console")