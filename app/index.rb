# Version ultra minimaliste pour Ruby WASM
class Box
  attr_reader :element

  def initialize(tag = 'div')
    @element = JS.global[:document].createElement(tag)
  end

  # Méthodes de style de base
  def width(val)
    @element[:style][:width] = "#{val}px"
    self
  end

  def height(val)
    @element[:style][:height] = "#{val}px"
    self
  end

  def color(val)
    val_str = val.is_a?(Symbol) ? val.to_s : val
    @element[:style][:color] = val_str
    self
  end

  def background(val)
    val_str = val.is_a?(Symbol) ? val.to_s : val
    @element[:style][:backgroundColor] = val_str
    self
  end

  def text(val)
    @element[:textContent] = val
    self
  end

  def append_to(parent)
    if parent.is_a?(Box)
      parent.element.appendChild(@element)
    else
      parent.appendChild(@element)
    end
    self
  end

  # Récupérer des valeurs
  def get_width
    @element[:style][:width]
  end

  def get_height
    @element[:style][:height]
  end

  def copy_height_from(other_box)
    @element[:style][:height] = other_box.get_height
    self
  end

  # Événements simples
  def on_click(&block)
    @element.addEventListener('click', block)
    self
  end
end

# Test simple
title = Box.new('h1')
title.text("Test Simple")
title.color(:blue)
title.append_to(JS.global[:document][:body])

box1 = Box.new
box1.width(100)
    .height(100)
    .color(:white)
    .background(:red)
    .text("Box 1")
box1.append_to(JS.global[:document][:body])

box2 = Box.new
box2.width(200)
    .color(:white)
    .background(:green)
    .text("Box 2")
box2.append_to(JS.global[:document][:body])

# Copier la hauteur
box2.copy_height_from(box1)

# Ajouter un texte d'info
info = Box.new('p')
info.text("La hauteur de la box 2 est maintenant égale à celle de la box 1")
info.append_to(JS.global[:document][:body])

# Événements
box1.on_click do |e|
  box1.background(:purple)
  info.text(box2.height)
end

box2.on_click do |e|
  box2.background(:yellow)
  info.text("Box 2 cliquée!")
end