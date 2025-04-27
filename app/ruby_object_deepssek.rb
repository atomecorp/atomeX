#deepseek

class Box
  def initialize(element_id = nil)
    @doc = `document`

    if element_id && element = `document.getElementById(#{element_id})`
      @element = element
    else
      @element = `document.createElement('div')`
      `#{@element}.id = #{element_id}` if element_id
      `document.body.appendChild(#{@element})`
    end
  end

  def width(value)
    `#{@element}.style.width = #{value.to_s + 'px'}`
    self
  end

  def height(value)
    `#{@element}.style.height = #{value.to_s + 'px'}`
    self
  end

  def color(value)
    `#{@element}.style.color = #{value.to_s}`
    self
  end

  def background(value)
    `#{@element}.style.backgroundColor = #{value.to_s}`
    self
  end

  def html(content)
    `#{@element}.innerHTML = #{content}`
    self
  end

  def text(content)
    `#{@element}.innerText = #{content}`
    self
  end

  def on(event, &handler)
    `
    #{@element}.addEventListener(#{event}, function(e) {
      #{handler.call(`e`)}
    })
    `
    self
  end

  def show
    `#{@element}.style.display = 'block'`
    self
  end

  def hide
    `#{@element}.style.display = 'none'`
    self
  end

  def inspect
    id = `#{@element}.id || 'anonymous_box'`
    "<Box id=#{id}>"
  end
end

def box(element_id = nil)
  Box.new(element_id)
end

# Exemple d'utilisation
b = box('test_box')
      .width(300)
      .height(200)
      .color('blue')
      .background('#f0f0f0')
      .html('<p>Cliquez-moi! Test réussi!</p>')
      .on('click') { puts "La box a été cliquée!" }

puts "Box créée avec succès: #{b.inspect}"