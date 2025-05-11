# demo.rb

require 'core.rb'

include Atome::DSL

# Test 1: Création d'un objet graphique
box = Atome::DSL.create_element("div", {
  id: :my_box,
  x: 45,
  y: 12,
  reference: {x: :center, y: 0},
  unit: {x: :px, y: '%'},
  width: 122,
  height: 122
})

# Ajouter l'élément au DOM
document = JS.global[:document]
document[:body].appendChild(box.element)

# Test 2: Utilisation de la syntaxe chaînée
box.left(55).width(66).color(Atome::Color.new(:the_col, 0.3, 0.5, 0, 0.4))

# Test 3: Accès par ID
a = Atome::DSL.grab('my_box')
a.left(55).width(66).color(Atome::Color.new(:the_col, 0.3, 0.5, 0, 0.4))

# Test 4: Gestion des callbacks
a.on("click") do
  a.color(Atome::Color.new(:red, 1.0, 0.0, 0.0, 1.0))
end

# Test 9: Chaining de méthodes
c = Atome::DSL.create_element("div")
c.x(100).y(200).width(50).height(50)