# Initialisation

doc = JS.global[:document]
body = doc[:body]


container = doc.createElement('div')
container[:id] = 'chant-container'
container[:style] = "width: 100%; height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; background: linear-gradient(135deg, #1a2a6c, #b21f1f, #fdbb2d); color: white; font-family: Arial, sans-serif;"

title = doc.createElement('h1')
title[:id] = 'main-title'
title[:innerText] = "La Voix Harmonique"
title[:style] = "font-size: 3rem; margin-bottom: 1rem; opacity: 0; transition: opacity 2s, transform 2s; transform: translateY(-50px);"

subtitle = doc.createElement('h2')
subtitle[:id] = 'subtitle'
subtitle[:innerText] = "L'art du chant authentique"
subtitle[:style] = "font-size: 1.5rem; margin-bottom: 2rem; opacity: 0; transition: opacity 2s 0.5s, transform 2s 0.5s; transform: translateY(-50px);"

button = doc.createElement('button')
button[:id] = 'cta-button'
button[:innerText] = "Découvrir nos cours"
button[:style] = "padding: 12px 24px; background: transparent; border: 2px solid white; color: white; font-size: 1rem; border-radius: 30px; cursor: pointer; opacity: 0; transition: opacity 2s 1s, transform 2s 1s, background 0.3s; transform: translateY(50px);"

# Animation au survol du bouton
button.addEventListener('mouseover') do
  button[:style][:background] = "rgba(255, 255, 255, 0.2)"
end

button.addEventListener('mouseout') do
  button[:style][:background] = "transparent"
end

# Assemblage des éléments
container.appendChild(title)
container.appendChild(subtitle)
container.appendChild(button)
body.appendChild(container)

# Animation d'entrée
JS.global.setTimeout(-> {
  title[:style][:opacity] = "1"
  title[:style][:transform] = "translateY(0)"

  subtitle[:style][:opacity] = "1"
  subtitle[:style][:transform] = "translateY(0)"

  button[:style][:opacity] = "1"
  button[:style][:transform] = "translateY(0)"
}, 100)

# Animation de notes de musique
notes = ["♪", "♫", "♩", "♬", "♭", "♮"]
colors = ["#FFD700", "#FF6347", "#00BFFF", "#7CFC00", "#FF69B4", "#9370DB"]

JS.global.setInterval(-> {
  5.times do
    note = doc.createElement('div')
    note[:innerText] = notes.sample
    note[:style] = "position: absolute; font-size: #{20 + rand(30)}px; top: #{rand(100)}vh; left: #{rand(100)}vw; color: #{colors.sample}; opacity: 0.7; animation: float #{3 + rand(5)}s linear;"

    # Définition de l'animation float
    float_animation = "@keyframes float { from { transform: translateY(0) rotate(0deg); opacity: 0.7; } to { transform: translateY(-100px) rotate(360deg); opacity: 0; } }"

    style = doc.createElement('style')
    style[:innerText] = float_animation
    doc[:head].appendChild(style)

    container.appendChild(note)

    # Suppression après l'animation
    JS.global.setTimeout(-> {
      container.removeChild(note)
      doc[:head].removeChild(style)
    }, 5000)
  end
}, 1000)

JS.global[:console].log("Chant site initialized successfully")