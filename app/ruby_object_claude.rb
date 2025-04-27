#claude

class DOMElement
  attr_reader :element

  def initialize(element_or_tag)
    @element = element_or_tag.is_a?(String) ?
                 JS.global[:document].createElement(element_or_tag) :
                 element_or_tag
  end

  # Méthodes pour définir les propriétés
  def width(value)
    @element[:style][:width] = "#{value}px"
    self # Pour le chaînage
  end

  def height(value)
    @element[:style][:height] = "#{value}px"
    self
  end

  def color(value)
    @element[:style][:color] = value.is_a?(Symbol) ? value.to_s : value
    self
  end

  def background(value)
    @element[:style][:backgroundColor] = value.is_a?(Symbol) ? value.to_s : value
    self
  end

  def text(value)
    @element[:textContent] = value
    self
  end

  def html(value)
    @element[:innerHTML] = value
    self
  end

  def id(value)
    @element[:id] = value
    self
  end

  def add_class(value)
    @element[:classList].add(value)
    self
  end

  def remove_class(value)
    @element[:classList].remove(value)
    self
  end

  # Manipulation du DOM
  def append_to(parent)
    if parent.is_a?(DOMElement)
      parent.element.appendChild(@element)
    else
      parent.appendChild(@element)
    end
    self
  end

  def append_child(child)
    if child.is_a?(DOMElement)
      @element.appendChild(child.element)
    else
      @element.appendChild(child)
    end
    self
  end

  # Gestionnaire d'événements
  def on(event_name, &block)
    @element.addEventListener(event_name, block)
    self
  end

  # Propriétés dynamiques pour accéder directement aux styles
  def method_missing(method_name, *args)
    if args.empty?
      # Getter
      return @element[:style][method_name]
    else
      # Setter
      @element[:style][method_name] = args.first
      return self
    end
  end
end

# Fonction d'aide pour créer des éléments
def box(tag = 'div')
  DOMElement.new(tag)
end

# Fonction d'aide pour sélectionner des éléments existants
def select(selector)
  element = JS.global[:document].querySelector(selector)
  element ? DOMElement.new(element) : nil
end

# Fonction d'aide pour sélectionner tous les éléments correspondants
def select_all(selector)
  elements = JS.global[:document].querySelectorAll(selector)
  elements.map { |el| DOMElement.new(el) }
end

# Exemple d'utilisation:
# b = box
# b.width(100).height(100).color(:red).background(:blue).text("Hello World").append_to(JS.global[:document][:body])