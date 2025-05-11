require 'core.rb'




# Création d'un conteneur principal
container = box({
                  id: 'container',
                  width: '80%',
                  height: 'auto',
                  style: {
                    margin: '20px auto',
                    padding: '20px',
                    backgroundColor: '#f5f5f5',
                    borderRadius: '10px',
                    boxShadow: '0 4px 8px rgba(0,0,0,0.1)',
                    fontFamily: 'Arial, sans-serif',
                    textAlign: 'center'
                  }
                })

# Titre
title = box({
              id: 'title',
              tag: 'h1',
              text: "Mini DSL Démo",
              parent: container,
              style: {
                fontSize: '2.5rem',
                color: '#333',
                marginBottom: '20px'
              }
            })

# Animation d'entrée pour le titre
animate_in(title, { from: :top }, 0.7, 0)

# Description
desc = box({
             id: 'description',
             tag: 'p',
             text: "Cette démo utilise un mini DSL compatible avec Opal et Ruby WASM",
             parent: container,
             style: {
               fontSize: '1.2rem',
               color: '#666',
               marginBottom: '30px'
             }
           })

# Animation d'entrée pour la description
animate_in(desc, { from: :top }, 0.7, 0.2)

# Zone pour les formes
shapes_area = box({
                    id: 'shapes-area',
                    parent: container,
                    style: {
                      display: 'flex',
                      justifyContent: 'center',
                      gap: '20px',
                      marginBottom: '30px'
                    }
                  })

# Boîte rouge
red_box = box({
                id: 'red-box',
                width: 100,
                height: 100,
                color: :red,
                parent: shapes_area,
                style: {
                  borderRadius: '10px',
                  boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
                  transition: 'transform 0.3s, background-color 0.3s'
                }
              })

# Animation d'entrée pour la boîte rouge
animate_in(red_box, { from: :scale }, 0.7, 0.4)

# Cercle bleu
blue_circle = circle({
                       id: 'blue-circle',
                       width: 100,
                       height: 100,
                       color: :blue,
                       parent: shapes_area,
                       style: {
                         boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
                         transition: 'transform 0.3s, background-color 0.3s'
                       }
                     })

# Animation d'entrée pour le cercle bleu
animate_in(blue_circle, { from: :scale }, 0.7, 0.6)

# Boîte verte
green_box = box({
                  id: 'green-box',
                  width: 100,
                  height: 100,
                  color: :green,
                  parent: shapes_area,
                  style: {
                    borderRadius: '10px',
                    boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
                    transition: 'transform 0.3s, background-color 0.3s'
                  }
                })

# Animation d'entrée pour la boîte verte
animate_in(green_box, { from: :scale }, 0.7, 0.8)

# Zone de boutons
buttons_area = box({
                     id: 'buttons-area',
                     parent: container,
                     style: {
                       display: 'flex',
                       justifyContent: 'center',
                       gap: '20px'
                     }
                   })

# Bouton d'animation
animate_button = box({
                       id: 'animate-button',
                       tag: 'button',
                       text: "Animer les formes",
                       parent: buttons_area,
                       style: {
                         padding: '10px 20px',
                         backgroundColor: '#4CAF50',
                         color: 'white',
                         border: 'none',
                         borderRadius: '5px',
                         cursor: 'pointer',
                         fontSize: '1rem',
                         boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
                         transition: 'background-color 0.3s, transform 0.3s'
                       }
                     })

# Animation d'entrée pour le bouton d'animation
animate_in(animate_button, { from: :bottom }, 0.7, 1.0)

# Événements de survol pour le bouton d'animation
animate_button.on(:mouseover) do
  animate_button[:style][:backgroundColor] = '#45a049'
  animate_button[:style][:transform] = 'scale(1.05)'
end

animate_button.on(:mouseout) do
  animate_button[:style][:backgroundColor] = '#4CAF50'
  animate_button[:style][:transform] = 'scale(1)'
end

# Événement de clic pour animer les formes
animate_button.on(:click) do
  # Animer le rectangle rouge
  red_box.animate({
                    rotate: 45,
                    scale: 1.2,
                    color: '#ff6347'
                  })

  # Animer le cercle bleu
  blue_circle.animate({
                        scale: 1.2,
                        color: '#1e90ff'
                      })

  # Animer la boîte verte
  green_box.animate({
                      rotate: -45,
                      scale: 1.2,
                      color: '#32cd32'
                    })

  # Créer quelques particules
  create_particles(20, 2, container)

  # Réinitialiser après 1 seconde
  JS.global.setTimeout(-> {
    red_box.animate({
                      rotate: 0,
                      scale: 1,
                      color: :red
                    })

    blue_circle.animate({
                          scale: 1,
                          color: :blue
                        })

    green_box.animate({
                        rotate: 0,
                        scale: 1,
                        color: :green
                      })
  }, 1000)
end

# Bouton de reset
reset_button = box({
                     id: 'reset-button',
                     tag: 'button',
                     text: "Réinitialiser",
                     parent: buttons_area,
                     style: {
                       padding: '10px 20px',
                       backgroundColor: '#f44336',
                       color: 'white',
                       border: 'none',
                       borderRadius: '5px',
                       cursor: 'pointer',
                       fontSize: '1rem',
                       boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
                       transition: 'background-color 0.3s, transform 0.3s'
                     }
                   })

# Animation d'entrée pour le bouton de reset
animate_in(reset_button, { from: :bottom }, 0.7, 1.2)

# Événements de survol pour le bouton de reset
reset_button.on(:mouseover) do
  reset_button[:style][:backgroundColor] = '#d32f2f'
  reset_button[:style][:transform] = 'scale(1.05)'
end

reset_button.on(:mouseout) do
  reset_button[:style][:backgroundColor] = '#f44336'
  reset_button[:style][:transform] = 'scale(1)'
end

# Événement de clic pour réinitialiser
reset_button.on(:click) do
  JS.global[:location].reload()
end

# Créer quelques particules d'arrière-plan
JS.global.setInterval(-> {
  # Utilisez JS.global[:document][:body] au lieu de document.body
  create_particles(5, 3, JS.global[:document][:body])
}, 2000)


####################################################################################################
# Test simple pour identifier le problème de transitions de couleur
# Exécutez ce script dans les deux environnements (Opal et Ruby WASM)

# Accès direct au DOM
doc = JS.global[:document]
body = doc[:body]

# Fonction de log
def log(message)
  JS.global[:console].log("TEST: #{message}")
end

log("Démarrage du test de transitions de couleur")

# Conteneur principal
container = doc.createElement('div')
container[:style][:width] = '80%'
container[:style][:margin] = '20px auto'
container[:style][:padding] = '20px'
container[:style][:backgroundColor] = '#f5f5f5'
container[:style][:borderRadius] = '10px'
container[:style][:textAlign] = 'center'
container[:style][:fontFamily] = 'Arial, sans-serif'

body.appendChild(container)

# Titre
title = doc.createElement('h1')
title[:innerText] = "Test de transitions de couleur"
container.appendChild(title)

# Explication
info = doc.createElement('p')
info[:innerText] = "Ce test valide différentes approches d'animation de couleur. " +
                   "Cliquez sur les boutons pour tester différentes méthodes."
container.appendChild(info)

# Grille de tests
tests_grid = doc.createElement('div')
tests_grid[:style][:display] = 'grid'
tests_grid[:style][:gridTemplateColumns] = 'repeat(3, 1fr)'
tests_grid[:style][:gap] = '20px'
tests_grid[:style][:marginTop] = '20px'
container.appendChild(tests_grid)

# Créer un test case
def create_test_case(container, title, description, document)
  test_case = document.createElement('div')
  test_case[:style][:border] = '1px solid #ddd'
  test_case[:style][:padding] = '15px'
  test_case[:style][:borderRadius] = '8px'
  test_case[:style][:backgroundColor] = 'white'

  # Titre du test
  test_title = document.createElement('h3')
  test_title[:innerText] = title
  test_title[:style][:marginTop] = '0'
  test_case.appendChild(test_title)

  # Description
  test_desc = document.createElement('p')
  test_desc[:innerText] = description
  test_desc[:style][:fontSize] = '0.9rem'
  test_desc[:style][:color] = '#666'
  test_case.appendChild(test_desc)

  # Boîte de couleur
  color_box = document.createElement('div')
  color_box[:style][:width] = '80px'
  color_box[:style][:height] = '80px'
  color_box[:style][:backgroundColor] = '#FF0000' # Rouge par défaut
  color_box[:style][:margin] = '10px auto'
  color_box[:style][:borderRadius] = '8px'
  color_box[:style][:boxShadow] = '0 2px 5px rgba(0,0,0,0.2)'
  test_case.appendChild(color_box)

  # Bouton de test
  test_button = document.createElement('button')
  test_button[:innerText] = "Tester"
  test_button[:style][:padding] = '8px 15px'
  test_button[:style][:backgroundColor] = '#4CAF50'
  test_button[:style][:color] = 'white'
  test_button[:style][:border] = 'none'
  test_button[:style][:borderRadius] = '4px'
  test_button[:style][:cursor] = 'pointer'
  test_button[:style][:marginTop] = '10px'
  test_case.appendChild(test_button)

  # Indicateur de statut
  status = document.createElement('div')
  status[:innerText] = "En attente"
  status[:style][:marginTop] = '10px'
  status[:style][:fontSize] = '0.9rem'
  status[:style][:color] = '#666'
  test_case.appendChild(status)

  container.appendChild(test_case)

  # Retourner les éléments importants
  return {
    case: test_case,
    box: color_box,
    button: test_button,
    status: status
  }
end

# Test 1: Utilisation directe de backgroundColor avec transition
test1 = create_test_case(
  tests_grid,
  "Style direct",
  "Modifie directement backgroundColor avec transition CSS",
  doc
)

# Configurer la transition initialement
test1[:box][:style][:transition] = 'background-color 0.5s ease'

test1[:button].addEventListener('click') do
  test1[:status][:innerText] = "Animation en cours..."
  test1[:status][:style][:color] = '#ff9900'

  # Changer la couleur
  test1[:box][:style][:backgroundColor] = '#0000FF' # Bleu

  # Réinitialiser après délai
  JS.global.setTimeout(-> {
    test1[:box][:style][:backgroundColor] = '#FF0000' # Rouge
    test1[:status][:innerText] = "Terminé"
    test1[:status][:style][:color] = '#4CAF50'
  }, 1000)
end

# Test 2: Définition de la transition juste avant le changement
test2 = create_test_case(
  tests_grid,
  "Transition explicite",
  "Définit la transition juste avant le changement de couleur",
  doc
)

test2[:button].addEventListener('click') do
  test2[:status][:innerText] = "Animation en cours..."
  test2[:status][:style][:color] = '#ff9900'

  # Définir la transition juste avant
  test2[:box][:style][:transition] = 'background-color 0.5s ease'

  # Changer la couleur
  test2[:box][:style][:backgroundColor] = '#0000FF' # Bleu

  # Réinitialiser après délai
  JS.global.setTimeout(-> {
    # Redéfinir la transition
    test2[:box][:style][:transition] = 'background-color 0.5s ease'
    test2[:box][:style][:backgroundColor] = '#FF0000' # Rouge
    test2[:status][:innerText] = "Terminé"
    test2[:status][:style][:color] = '#4CAF50'
  }, 1000)
end

# Test 3: Utilisation de classes CSS
test3 = create_test_case(
  tests_grid,
  "Classes CSS",
  "Utilise des classes CSS pour la transition",
  doc
)

# Ajouter des styles pour les classes
style = doc.createElement('style')
style[:innerHTML] = "
  .color-box { transition: background-color 0.5s ease; }
  .box-blue { background-color: #0000FF !important; }
"
doc[:head].appendChild(style)

# Ajouter la classe de base
test3[:box][:className] = 'color-box'

test3[:button].addEventListener('click') do
  test3[:status][:innerText] = "Animation en cours..."
  test3[:status][:style][:color] = '#ff9900'

  # Ajouter la classe de couleur
  test3[:box][:className] = 'color-box box-blue'

  # Réinitialiser après délai
  JS.global.setTimeout(-> {
    test3[:box][:className] = 'color-box'
    test3[:status][:innerText] = "Terminé"
    test3[:status][:style][:color] = '#4CAF50'
  }, 1000)
end

# Test 4: Utilisation de RGB au lieu de HEX
test4 = create_test_case(
  tests_grid,
  "Format RGB",
  "Utilise le format rgb() au lieu de valeurs HEX",
  doc
)

test4[:box][:style][:transition] = 'background-color 0.5s ease'
test4[:box][:style][:backgroundColor] = 'rgb(255, 0, 0)' # Rouge en RGB

test4[:button].addEventListener('click') do
  test4[:status][:innerText] = "Animation en cours..."
  test4[:status][:style][:color] = '#ff9900'

  # Changer la couleur en RGB
  test4[:box][:style][:backgroundColor] = 'rgb(0, 0, 255)' # Bleu en RGB

  # Réinitialiser après délai
  JS.global.setTimeout(-> {
    test4[:box][:style][:backgroundColor] = 'rgb(255, 0, 0)' # Rouge en RGB
    test4[:status][:innerText] = "Terminé"
    test4[:status][:style][:color] = '#4CAF50'
  }, 1000)
end

# Test 5: Animation sans transition
test5 = create_test_case(
  tests_grid,
  "Sans transition",
  "Change la couleur sans utiliser de transition CSS",
  doc
)

test5[:button].addEventListener('click') do
  test5[:status][:innerText] = "Animation en cours..."
  test5[:status][:style][:color] = '#ff9900'

  # Changer la couleur sans transition
  test5[:box][:style][:backgroundColor] = '#0000FF' # Bleu

  # Réinitialiser après délai
  JS.global.setTimeout(-> {
    test5[:box][:style][:backgroundColor] = '#FF0000' # Rouge
    test5[:status][:innerText] = "Terminé"
    test5[:status][:style][:color] = '#4CAF50'
  }, 1000)
end

# Test 6: Animation avec étapes manuelles
test6 = create_test_case(
  tests_grid,
  "Animation par étapes",
  "Anime la couleur progressivement en plusieurs étapes",
  doc
)

test6[:button].addEventListener('click') do
  test6[:status][:innerText] = "Animation en cours..."
  test6[:status][:style][:color] = '#ff9900'

  # Animation manuelle en 10 étapes
  steps = 10
  duration = 50  # ms entre chaque étape

  # Animation de rouge à bleu
  step = 0
  animation_timer = JS.global.setInterval(-> {
    if step < steps
      # Calculer la couleur intermédiaire
      progress = step / steps.to_f
      r = (255 * (1 - progress)).to_i
      g = 0
      b = (255 * progress).to_i

      # Appliquer la couleur
      test6[:box][:style][:backgroundColor] = "rgb(#{r}, #{g}, #{b})"

      step += 1
    else
      # Arrêter l'animation
      JS.global.clearInterval(animation_timer)

      # Attendre avant de revenir
      JS.global.setTimeout(-> {
        # Animation de retour
        step = 0
        return_timer = JS.global.setInterval(-> {
          if step < steps
            # Calculer la couleur intermédiaire
            progress = step / steps.to_f
            r = (255 * progress).to_i
            g = 0
            b = (255 * (1 - progress)).to_i

            # Appliquer la couleur
            test6[:box][:style][:backgroundColor] = "rgb(#{r}, #{g}, #{b})"

            step += 1
          else
            # Arrêter l'animation
            JS.global.clearInterval(return_timer)

            # Terminer
            test6[:status][:innerText] = "Terminé"
            test6[:status][:style][:color] = '#4CAF50'
          end
        }, duration)
      }, 500)
    end
  }, duration)
end

log("Test de transitions de couleur initialisé avec succès")