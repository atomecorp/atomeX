#qwen

class Box
  attr_reader :element

  # Constructeur : Crée un nouvel élément DOM ou enveloppe un élément existant
  def initialize(tag = 'div', parent = nil)
    @element = JS.global[:document].createElement(tag)
    parent&.appendChild(@element)
  end

  # Méthode pour définir la largeur
  def width(value)
    @element[:style][:width] = "#{value}px"
    self
  end

  # Méthode pour définir la couleur
  def color(value)
    @element[:style][:color] = value.to_s
    self
  end

  # Méthode pour ajouter du contenu HTML
  def content(html)
    @element[:innerHTML] = html
    self
  end

  # Méthode pour ajouter un enfant
  def append(child)
    @element.appendChild(child.element)
    self
  end
end


doc = JS.global[:document]
body = doc[:body]

b = Box.new('div', body)

# Modifier les propriétés avec une syntaxe simple
b.width(300)
 .color(:green)
 .content("<h1>Hello from a required file</h1><h2>#{Time.now}</h2>")

# Ajouter un autre élément enfant
child = Box.new('span')
child.content("This is a child element").color(:blue)

b.append(child)

# Vérifier la classe de l'objet
puts b.class  # => Box