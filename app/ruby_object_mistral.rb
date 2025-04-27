#mistral

class Box
  def initialize(id)
    @element = JS.global[:document].createElement('div')
    @element[:id] = id
    @element[:style][:height] = '100px' # Ajout de la hauteur par défaut
    JS.global[:document][:body].appendChild(@element)
  end

  def width(value)
    @element[:style][:width] = "#{value}px"
  end

  def height(value)
    @element[:style][:height] = "#{value}px"
  end

  def color(value)
    @element[:style][:backgroundColor] = value.to_s
  end

  def to_s
    "Box with id: #{@element[:id]}"
  end
end

# Utilisation
b = Box.new('first_one')
b.width(33)
b.height(100) # Définir la hauteur
b.color(:red)
puts b

