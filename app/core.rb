# Mini DSL construit par-dessus le code fonctionnel
# Fonctionne avec Opal et Ruby WASM

# Couleurs prédéfinies
COLORS = {
  red: '#FF0000',
  green: '#00FF00',
  blue: '#0000FF',
  black: '#000000',
  white: '#FFFFFF',
  transparent: 'transparent'
}

# Fonction pour créer une boîte
def box(params = {})
  doc = JS.global[:document]

  element = doc.createElement('div')
  element[:id] = params[:id] || "box_#{rand(9999)}"

  # Position
  if params[:x] || params[:y]
    element[:style][:position] = 'absolute'
    element[:style][:left] = "#{params[:x]}px" if params[:x]
    element[:style][:top] = "#{params[:y]}px" if params[:y]
  end

  # Dimensions
  element[:style][:width] = "#{params[:width]}px" if params[:width]
  element[:style][:height] = "#{params[:height]}px" if params[:height]


  # Couleur
  if params[:color]
    color_value = params[:color]

    # Si c'est un symbole, essayer de le convertir en utilisant COLORS
    if COLORS.has_key?(color_value.to_sym)
      color_value = COLORS[color_value.to_sym]
    end

    element[:style][:backgroundColor] = color_value
  end
  # Autres styles
  if params[:style].is_a?(Hash)
    params[:style].each do |prop, value|
      element[:style][prop.to_s] = value.to_s
    end
  end

  # Contenu
  element[:innerText] = params[:text] if params[:text]

  # Attacher au parent
  parent = if params[:parent]
             if params[:parent].is_a?(String) || params[:parent].is_a?(Symbol)
               doc.getElementById(params[:parent].to_s)
             else
               params[:parent] # Supposer que c'est un élément DOM
             end
           else
             doc[:body]
           end

  parent.appendChild(element) if parent

  # Ajouter des méthodes utiles à l'élément
  add_element_methods(element)

  element
end

# Fonction pour créer un cercle
def circle(params = {})
  element = box(params)
  element[:style][:borderRadius] = '50%'
  element
end

# Fonction pour récupérer un élément par ID
def grab(id)
  element = JS.global[:document].getElementById(id.to_s)
  add_element_methods(element) if element
  element
end

# Ajouter des méthodes utiles à un élément DOM
def add_element_methods(element)
  # Pour définir la position X
  def element.x(value = nil)
    if value
      self[:style][:position] = 'absolute' unless self[:style][:position]
      self[:style][:left] = "#{value}px"
      self
    else
      self[:style][:left]&.to_s&.gsub('px', '')&.to_i || 0
    end
  end

  # Pour définir la position Y
  def element.y(value = nil)
    if value
      self[:style][:position] = 'absolute' unless self[:style][:position]
      self[:style][:top] = "#{value}px"
      self
    else
      self[:style][:top]&.to_s&.gsub('px', '')&.to_i || 0
    end
  end

  # Pour définir la largeur
  def element.width(value = nil)
    if value
      self[:style][:width] = "#{value}px"
      self
    else
      self[:style][:width]&.to_s&.gsub('px', '')&.to_i || 0
    end
  end

  # Pour définir la hauteur
  def element.height(value = nil)
    if value
      self[:style][:height] = "#{value}px"
      self
    else
      self[:style][:height]&.to_s&.gsub('px', '')&.to_i || 0
    end
  end

  # Pour définir la couleur
  def element.color(value)
    color_value = if value.is_a?(Symbol)
                    COLORS[value] || COLORS[:black]
                  else
                    value.to_s
                  end

    self[:style][:backgroundColor] = color_value
    self
  end

  # Pour attacher un événement
  def element.on(event, &block)
    self.addEventListener(event.to_s, &block)
    self
  end

  # Pour animer l'élément
  def element.animate(props = {}, duration = 0.3, delay = 0)
    # Configurer la transition
    transitions = []

    props.each do |prop, value|
      case prop
      when :x
        self[:style][:position] = 'absolute' unless self[:style][:position]
        transitions << "left #{duration}s ease #{delay}s"
        self[:style][:left] = "#{value}px"
      when :y
        self[:style][:position] = 'absolute' unless self[:style][:position]
        transitions << "top #{duration}s ease #{delay}s"
        self[:style][:top] = "#{value}px"
      when :width
        transitions << "width #{duration}s ease #{delay}s"
        self[:style][:width] = "#{value}px"
      when :height
        transitions << "height #{duration}s ease #{delay}s"
        self[:style][:height] = "#{value}px"
      when :color
        transitions << "background-color #{duration}s ease #{delay}s"
        color_value = value.is_a?(Symbol) ? COLORS[value] : value
        self[:style][:backgroundColor] = color_value
      when :opacity
        transitions << "opacity #{duration}s ease #{delay}s"
        self[:style][:opacity] = value.to_s
      when :rotate
        transitions << "transform #{duration}s ease #{delay}s"
        self[:style][:transform] = "rotate(#{value}deg)"
      when :scale
        transitions << "transform #{duration}s ease #{delay}s"
        self[:style][:transform] = "scale(#{value})"
      else
        # Propriété CSS générique
        css_prop = prop.to_s.gsub('_', '-')
        transitions << "#{css_prop} #{duration}s ease #{delay}s"
        self[:style][css_prop] = value.to_s
      end
    end

    self[:style][:transition] = transitions.join(', ')
    self
  end

  element
end

# Fonctions utilitaires
def animate_in(element, props = {}, duration = 0.5, delay = 0)
  # Configurer les styles initiaux
  element[:style][:opacity] = '0'

  if props[:from] == :top
    element[:style][:transform] = 'translateY(-20px)'
  elsif props[:from] == :bottom
    element[:style][:transform] = 'translateY(20px)'
  elsif props[:from] == :left
    element[:style][:transform] = 'translateX(-20px)'
  elsif props[:from] == :right
    element[:style][:transform] = 'translateX(20px)'
  elsif props[:from] == :scale
    element[:style][:transform] = 'scale(0.8)'
  end

  # Configurer la transition
  element[:style][:transition] = "opacity #{duration}s ease #{delay}s, transform #{duration}s ease #{delay}s"

  # Déclencher l'animation après un court délai
  JS.global.setTimeout(-> {
    element[:style][:opacity] = '1'
    element[:style][:transform] = 'translate(0, 0) scale(1)'
  }, 50)

  element
end

# Fonction pour créer des particules animées
def create_particles(count = 10, duration = 3, container = nil)
  doc = JS.global[:document]
  container ||= doc[:body]

  # Ajouter la définition d'animation si elle n'existe pas déjà
  if !doc.getElementById('particle-animation')
    style_el = doc.createElement('style')
    style_el[:id] = 'particle-animation'
    style_el[:innerHTML] = "@keyframes float { 0% { transform: translate(0, 0); opacity: 0.6; } 100% { transform: translate(var(--end-x), var(--end-y)); opacity: 0; } }"
    doc[:head].appendChild(style_el)
  end

  # Créer les particules
  count.times do
    # Propriétés aléatoires
    size = 5 + rand(10)
    color = ['#ff9999', '#99ff99', '#9999ff', '#ffff99', '#ff99ff'].sample

    # Créer la particule
    particle = doc.createElement('div')
    particle[:style][:position] = 'absolute'
    particle[:style][:width] = "#{size}px"
    particle[:style][:height] = "#{size}px"
    particle[:style][:backgroundColor] = color
    particle[:style][:borderRadius] = '50%'
    particle[:style][:top] = "#{rand(100)}%"
    particle[:style][:left] = "#{rand(100)}%"
    particle[:style][:opacity] = '0.6'

    # Configurer les variables CSS pour l'animation
    particle[:style][:'--end-x'] = "#{-50 + rand(100)}px"
    particle[:style][:'--end-y'] = "#{-100 - rand(50)}px"

    # Ajouter l'animation
    particle[:style][:animation] = "float #{duration}s linear forwards"

    # Ajouter au conteneur
    container.appendChild(particle)

    # Supprimer après l'animation
    JS.global.setTimeout(-> {
      container.removeChild(particle) if container.contains(particle)
    }, duration * 1000)
  end
end

# Fonction pour log
def log(message)
  JS.global[:console].log(message)
end

# Afficher un message de succès
log("Mini DSL chargé avec succès")