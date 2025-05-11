# Affiche un message dans la console
puts "Page d'accueil animée en Ruby WASM"

# Accède au document global
doc = JS.global[:document]
body = doc[:body]

# Crée un conteneur principal
container = doc.createElement('div')
container[:style] = 'display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f0f0f0;'

# Crée un élément animé
animated_element = doc.createElement('div')
animated_element[:style] = 'width: 100px; height: 100px; background-color: #3498db; position: relative;'

# Ajoute l'élément animé au conteneur
container.appendChild(animated_element)

# Ajoute le conteneur au corps du document
body.appendChild(container)

# Fonction d'animation
def animate_element(element, position)
  element[:style][:transform] = "translateX(#{position}px)"
end

# Position initiale
position = 0

# Direction de l'animation
direction = 1

# Boucle d'animation
JS.global.setInterval(-> {
  # Met à jour la position
  position += 5 * direction

  # Change de direction si on atteint les limites
  if position > 300 || position < 0
    direction *= -1
  end

  # Anime l'élément
  animate_element(animated_element, position)
}, 50)

# Affiche un message dans la console
JS.global[:console].log("Animation en cours...")
