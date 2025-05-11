# atome_dsl.rb

module Atome
  # Classe de base pour les éléments DOM
  class Element
    attr_reader :element

    def initialize(element)
      @element = element
      @properties = {}
    end

    # Méthodes de position
    def x(value = nil)
      value.nil? ? get_style('left') : set_style('left', value)
    end

    def left(value = nil)
      value.nil? ? get_style('left') : set_style('left', value)
    end

    def y(value = nil)
      value.nil? ? get_style('top') : set_style('top', value)
    end

    def top(value = nil)
      value.nil? ? get_style('top') : set_style('top', value)
    end

    # Méthodes de taille
    def width(value = nil)
      value.nil? ? get_style('width') : set_style('width', value)
    end

    def height(value = nil)
      value.nil? ? get_style('height') : set_style('height', value)
    end

    # Méthode de couleur
    def color(value = nil)
      if value.is_a?(Color)
        apply_color(value)
      else
        set_style('backgroundColor', value)
      end
      self
    end

    # Méthode de référence
    def reference(value = nil)
      @properties[:reference] = value if value
      @properties[:reference]
    end

    # Méthode d'unité
    def unit(value = nil)
      @properties[:unit] = value if value
      @properties[:unit]
    end

    # Méthode d'écoute des événements
    def on(event, &block)
      @element.addEventListener(event, block)
      self
    end

    private

    def get_style(property)
      @element[:style].getPropertyValue(property)
    end

    def set_style(property, value)
      @element[:style].setProperty(property, value)
      self
    end

    def apply_color(color)
      red = (color.red * 255).to_i
      green = (color.green * 255).to_i
      blue = (color.blue * 255).to_i
      alpha = color.alpha
      rgba = "rgba(#{red}, #{green}, #{blue}, #{alpha})"
      set_style('backgroundColor', rgba)
    end
  end

  # Classe pour gérer les couleurs
  class Color
    attr_reader :id, :red, :green, :blue, :alpha

    def initialize(id, red, green, blue, alpha)
      @id = id
      @red = red
      @green = green
      @blue = blue
      @alpha = alpha
    end

    def apply(element)
      element.color(self)
    end
  end

  # Module DSL pour créer et manipuler les éléments
  module DSL
    # Créer un élément DOM
    def self.create_element(tag_name, options = {})
      element = JS.global[:document].createElement(tag_name)
      element.id = options[:id] if options[:id]
      element.style.css_text = "position: absolute; #{options[:style]}" if options[:style]

      case tag_name.downcase
      when 'div'
        Element.new(element)
      when 'circle'
        Element.new(element)
      else
        Element.new(element)
      end
    end

    # Accéder à un élément par son ID
    def self.grab(id)
      element = JS.global[:document].getElementById(id)
      Element.new(element) if element
    end
  end
end