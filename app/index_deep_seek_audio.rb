# Initialisation de l'application
puts "Démarrage de l'application Ruby WASM"

# Récupération des éléments globaux
doc = JS.global[:document]
body = doc[:body]
audio_context = JS.global[:AudioContext].new

# Création des éléments de base
container = doc.createElement('div')
container[:id] = 'container'
container[:style] = "width: 100%; height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; background: linear-gradient(135deg, #1a1a2e, #16213e); color: white; font-family: Arial, sans-serif;"

# Titre principal
title = doc.createElement('h1')
title[:innerHTML] = "Bienvenue sur KeySite"
title[:style] = "font-size: 3em; margin-bottom: 0.5em; text-shadow: 0 0 10px rgba(255,255,255,0.5); transition: all 0.3s;"

# Sous-titre animé
subtitle = doc.createElement('h2')
subtitle[:innerHTML] = "L'expérience Ruby dans le navigateur"
subtitle[:style] = "font-size: 1.5em; opacity: 0.8; margin-bottom: 2em; animation: fadeIn 2s;"

# Bouton interactif
button = doc.createElement('button')
button[:innerHTML] = "Cliquez pour l'expérience"
button[:style] = "padding: 15px 30px; background: #e94560; border: none; border-radius: 50px; color: white; font-size: 1.2em; cursor: pointer; transition: all 0.3s; box-shadow: 0 5px 15px rgba(233, 69, 96, 0.4);"

# Élément pour le son visuel
visualizer = doc.createElement('div')
visualizer[:style] = "width: 300px; height: 50px; margin-top: 30px; display: flex; justify-content: space-between; align-items: flex-end;"

# Création des barres de visualisation
5.times do |i|
  bar = doc.createElement('div')
  bar[:style] = "width: 20px; background: #e94560; border-radius: 10px; transition: height 0.2s;"
  bar[:id] = "bar-#{i}"
  visualizer.appendChild(bar)
end

# Ajout des éléments au container
container.appendChild(title)
container.appendChild(subtitle)
container.appendChild(button)
container.appendChild(visualizer)
body.appendChild(container)

# Animation du titre
animate_title = proc do
  title[:style][:transform] = "scale(1.05)"
  JS.global.setTimeout(-> {
    title[:style][:transform] = "scale(1)"
  }, 300)
end

# Animation des barres de visualisation
animate_bars = proc do
  5.times do |i|
    bar = doc.getElementById("bar-#{i}")
    random_height = (10 + rand(40)).to_s
    bar[:style][:height] = "#{random_height}px"
  end
end

# Configuration audio corrigée
setup_audio = proc do
  oscillator = audio_context.createOscillator
  gain_node = audio_context.createGain

  # Correction: utilisation de la syntaxe JS correcte pour définir le type
  oscillator[:type] = "sine"
  oscillator[:frequency][:value] = 440
  gain_node[:gain][:value] = 0

  oscillator.connect(gain_node)
  gain_node.connect(audio_context[:destination])

  oscillator.start(0)

  { oscillator: oscillator, gain_node: gain_node }
end

# Démarrer l'audio
audio_nodes = setup_audio.call

# Interaction avec le bouton
button.addEventListener('click') do |event|
  # Animation du bouton
  button[:style][:transform] = "scale(0.95)"
  button[:style][:boxShadow] = "0 2px 10px rgba(233, 69, 96, 0.6)"

  JS.global.setTimeout(-> {
    button[:style][:transform] = "scale(1)"
    button[:style][:boxShadow] = "0 5px 15px rgba(233, 69, 96, 0.4)"
  }, 200)

  # Jouer un son
  audio_nodes[:gain_node][:gain][:value] = 0.3
  audio_nodes[:oscillator][:frequency][:value] = 300 + rand(500)

  JS.global.setTimeout(-> {
    audio_nodes[:gain_node][:gain][:value] = 0
  }, 200)

  # Changer le titre
  title[:innerHTML] = "Vous avez déclenché l'expérience!"
  animate_title.call
end

# Animation continue
JS.global.setInterval(-> {
  animate_title.call
  animate_bars.call
}, 2000)

# Animation initiale
animate_bars.call

# Ajout des keyframes CSS via JS
styles = doc.createElement('style')
styles[:innerHTML] = "
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 0.8; transform: translateY(0); }
}
"
doc[:head].appendChild(styles)

puts "Application initialisée avec succès"