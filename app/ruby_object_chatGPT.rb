#chatGPT

class Box
  def initialize
    doc = JS.global[:document]
    @element = doc.createElement('div')
    @element[:id] = "box_#{rand(1000)}"
    doc[:body].appendChild(@element)
  end

  def width(value)
    @element[:style][:width] = "#{value}px"
  end

  def height(value)
    @element[:style][:height] = "#{value}px"
  end

  def color(value)
    @element[:style][:color] = value.to_s
  end

  def background(value)
    @element[:style][:backgroundColor] = value.to_s
  end

  def html(content)
    @element[:innerHTML] = content
  end

  def to_s
    "<Box ##{@element[:id]}>"
  end
end

# Exemple d'utilisation
b = Box.new
b.width(300)
b.height(100)
b.color(:red)
b.background(:yellow)
b.html("<h1>Hello</h1>")

puts b.class   # => Box
puts b         # => <Box #box_123>