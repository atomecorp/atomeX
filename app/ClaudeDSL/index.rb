require 'core.rb'
#
# # --- Init on document load --------------------------------
# JS.global[:document].addEventListener('DOMContentLoaded') do
#   # Test direct DOM
#   doc = JS.global[:document]
#   test = doc.createElement('div')
#   test[:id] = 'test-direct'
#   test[:style][:width] = '150px'
#   test[:style][:height] = '150px'
#   test[:style][:backgroundColor] = 'blue'
#   test[:style][:position] = 'absolute'
#   test[:style][:top] = '300px'
#   test[:style][:left] = '10px'
#   test[:style][:zIndex] = '1000'
#   test[:style][:border] = '3px solid white'
#   test[:textContent] = 'Test Direct DOM'
#   doc[:body].appendChild(test)
#
#     # 🔹 Exemples de vérification du DSL
#     JS.global[:console].log('Création des éléments de test...')
#
#     # Élements avec différentes couleurs
#     a = box(id: :box1, x: 50, y: 50, width: 150, height: 100,
#             color: { red: 1.0, green: 0, blue: 0, alpha: 1.0 })
#
#     b = box(id: :box2, x: 250, y: 50, width: 150, height: 100,
#             color: { red: 0.3, green: 0.5, blue: 0, alpha: 1.0 })
#
#     c = color(id: :the_col, red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
#     d = box(id: :box3, x: 450, y: 50, width: 150, height: 100)
#     d.color(c)
#
#     e = circle(id: :circle1, x: 100, y: 200, width: 100, height: 100,
#                color: { red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0 })
#
#     JS.global[:console].log("Nombre d'atomes créés: #{AtomeRegistry.count}")
#     JS.global[:console].log("Liste des IDs: #{AtomeRegistry.list_all}")
#
#     # Test des fonctionnalités de dragging
#     JS.global[:console].log("Test des fonctionnalités de dragging...")
#
#     # Rendre circle1 déplaçable
#     draggable_circle = AtomeRegistry.find_by_id(:circle1)
#     if draggable_circle
#       JS.global[:console].log("Rendre le cercle déplaçable")
#
#       # Ajouter un observateur pour les événements de déplacement
#       draggable_circle.add_listener do |obj, prop, val|
#         if [:drag_start, :drag_move, :drag_end].include?(prop)
#           JS.global[:console].log("Événement #{prop} sur #{obj.id} : x=#{val[:x]}, y=#{val[:y]}")
#         end
#       end
#
#       # Rendre déplaçable
#       draggable_circle.draggable(true)
#
#       # Ajouter une bordure plus visible
#       draggable_circle.style(border: "2px dashed white")
#       draggable_circle.style(boxShadow: "0 0 10px rgba(0,0,0,0.5)")
#     end
#
#     # Rendre box2 tactile
#     touchable_box = AtomeRegistry.find_by_id(:box2)
#     if touchable_box
#       JS.global[:console].log("Rendre la boîte tactile")
#
#       # Ajouter un observateur pour les événements tactiles
#       touchable_box.add_listener do |obj, prop, val|
#         if [:tap, :double_tap, :long_touch].include?(prop)
#           JS.global[:console].log("Événement tactile #{prop} sur #{obj.id}")
#         end
#       end
#
#       # Rendre tactile
#       touchable_box.touchable(true)
#
#       # Ajouter une bordure plus visible
#       touchable_box.style(border: "2px solid white")
#       touchable_box.style(boxShadow: "0 0 10px rgba(255,255,255,0.5)")
#     end
#
#     # Tester les événements de souris sur tous les éléments
#     [:box1, :box2, :box3, :circle1].each do |id|
#       elem = AtomeRegistry.find_by_id(id)
#       if elem
#         elem.on(:click) do |event|
#           JS.global[:console].log("Click sur #{id}")
#           elem.style(border: "3px solid yellow")
#
#           # Retour à la normale après 500ms
#           JS.global.setTimeout(-> {
#             elem.style(border: "1px solid black")
#           }, 500)
#         end
#       end
#     end
# end
#
# # Un marqueur visible en JavaScript pur
# JS.global[:window].addEventListener('load') do
#   marker = JS.global[:document].createElement('div')
#   marker[:id] = 'js-marker'
#   marker[:style][:width] = '100px'
#   marker[:style][:height] = '100px'
#   marker[:style][:backgroundColor] = 'red'
#   marker[:style][:position] = 'absolute'
#   marker[:style][:bottom] = '10px'
#   marker[:style][:right] = '10px'
#   marker[:style][:zIndex] = '9999'
#   marker[:textContent] = 'JS marker'
#
#   JS.global[:document][:body].appendChild(marker)
#   JS.global[:console].log('Marqueur JS créé')
# end

b = box(id: :box2, x: 250, y: 50, width: 150, height: 100,
        color: { red: 0.3, green: 0.5, blue: 0, alpha: 1.0 })

c = circle(id: :circle2, x: 450, y: 50, width: 150, height: 100,
        color: { red: 0, green: 0.5, blue: 0, alpha: 1.0 })

b.on(:click) do |event|
  event = Native(event)

  # Débogage pour voir si l'événement est déclenché
  puts("Mousedown sur #{@id}")

  puts("Mousedown sur #{@id}")
  puts ">>>>> #{event[:clientX]}"
  # Accéder aux propriétés de l'événement natif
  # client_x = event[:clientX] || 0
  # client_y = event[:clientY] || 0
  JS.global[:console].log("Click sur box2")
  b.color({ red: 1, green: 0, blue: 0, alpha: 1.0 })
  b.style(border: "3px solid yellow")
  JS.global.setTimeout(-> {
    b.style(border: "2px solid white")
  }, 500)
end

b.element[:textContent] = "Tap ou Click moi!"

# Ajout d'un listener pour détecter les événements
# b.add_listener do |obj, prop, val|
#   if [:tap, :double_tap, :long_touch].include?(prop)
#     JS.global[:console].log("Événement tactile #{prop} sur #{obj.id}")
#
#     # Ajouter un effet visuel pour confirmer que l'événement a été détecté
#     b.style(border: "3px solid yellow")
#
#     # Retour à la normale après 500ms
#     JS.global.setTimeout(-> {
#       b.style(border: "2px solid white")
#     }, 500)
#   end
# end

# Ajout d'un événement de clic pour tester en mode souris

# Rendre tactile après avoir configuré tous les événements
# b.touchable(true)
# b.style(border: "2px solid red")
#
# # Ajouter explicitement un texte après avoir configuré touchable

# GSAP
