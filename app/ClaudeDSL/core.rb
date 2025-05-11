# DSL Graphique – Implémentation autonome (Opal + RubyWasm)
# ----------------------------------------------------------

# --- Base --------------------------------------------------
class Atome
  attr_reader :id, :properties, :element

  def initialize(params = {})
    @id         = params[:id] || "atome_#{object_id}"
    @properties = {}
    @listeners  = []
    create_element
    params.each { |k, v| dispatch_property(k, v) }
    AtomeRegistry.register(self)
  end

  # ---------- DOM creation ----------
  def create_element
    doc = JS.global[:document]
    @element = doc.createElement('div')
    @element[:dataset][:atome_id] = @id
    doc[:body].appendChild(@element)
    style(position: 'absolute')
  end


  #optimized veriosn
  # def create_element
  #   # doc = JS.global[:document]
  #   # @element = doc.createElement('div')
  #   # @element[:dataset][:atome_id] = @id
  #   # doc[:body].appendChild(@element)
  #   # style(position: 'absolute')
  #   doc = JS.global.document
  #   container = doc.createElement('div')
  #   container.id = @id
  #   # container.style.cssText = "width: 100%; height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; background: linear-gradient(135deg, #1a2a6c, #b21f1f, #fdbb2d); color: white; font-family: Arial, sans-serif;"
  #   doc.body.appendChild(container)
  # end



  # ---------- Properties ----------
  def dispatch_property(key, value)
    m = "#{key}="
    respond_to?(m) ? send(m, value) : set_property(key, value)
  end

  def set_property(prop, val)
    @properties[prop] = val
    update_element(prop, val)
    self
  end

  def get_property(prop)
    @properties[prop]
  end

  # ---------- Dynamic getters/setters ----------
  def method_missing(name, *args, &block)
    str = name.to_s
    if str.end_with?('=') && args.size == 1
      set_property(str.chop.to_sym, args.first)
    elsif args.empty?
      get_property(name)
    else
      set_property(name, args.first)
    end
    self
  end

  # ---------- Shorthand explicit methods ----------
  %i[x y width height].each do |prop|
    define_method(prop) do |val = nil|
      if val.nil?
        get_property(prop)
      else
        set_property(prop, val)
      end
    end
  end

  def color(val = nil)
    if val.nil?
      get_property(:color)
    else
      val = AtomeRegistry.find_by_id(val) if val.is_a?(Symbol)
      set_property(:color, val)
    end
  end

  # ---------- Position helpers ----------
  def left(val = nil)
    if val.nil?
      get_property(:x)
    else
      ref = get_property(:reference)&.dig(:x) || :left
      offset = ref == :center ? (get_property(:width).to_i / 2) : 0
      set_property(:x, val - offset)
    end
  end

  def top(val = nil)
    if val.nil?
      get_property(:y)
    else
      ref = get_property(:reference)&.dig(:y) || :top
      offset = ref == :center ? (get_property(:height).to_i / 2) : 0
      set_property(:y, val - offset)
    end
  end

  # ---------- Style ----------
  def style(hash = {})
    hash.each { |k, v| @element[:style][k.to_s.camelize(:lower)] = v.to_s }
    self
  end

  # ---------- DOM update ----------
  def update_element(prop, val)
    case prop
    when :x         then style(left: "#{val}px")
    when :y         then style(top:  "#{val}px")
    when :width     then style(width:  "#{val}px")
    when :height    then style(height: "#{val}px")
    when :color
      css = val.is_a?(Color) ? val.to_css : val.to_s
      if val.is_a?(Hash)
        r = (val[:red] || 0) * 255
        g = (val[:green] || 0) * 255
        b = (val[:blue] || 0) * 255
        a = val[:alpha] || 1.0
        css = "rgba(#{r.to_i},#{g.to_i},#{b.to_i},#{a})"
      end
      style(backgroundColor: css)
    when :reference then update_position
    end
    notify_listeners(prop, val)
  end

  def update_position
    left(get_property(:x)) if get_property(:x)
    top(get_property(:y))  if get_property(:y)
  end

  # ---------- Listeners ----------
  def add_listener(&blk)
    @listeners << blk
  end

  def notify_listeners(prop, val)
    @listeners.each { |listener| listener.call(self, prop, val) }
  end

  # ---------- DOM events ----------
  def on(evt, &blk)
    @element.addEventListener(evt.to_s, &blk)
    self
  end

  # ---------- Drag & Drop ----------
  def draggable(enable = true)
    if enable
      # Variables pour suivre l'état du déplacement
      @drag_state = { active: false, start_x: 0, start_y: 0, offset_x: 0, offset_y: 0 }

      # Gestion de la souris
      on(:mousedown) do |native_event|
        # Convertir l'événement natif en objet Ruby
        event = Native(native_event)

        # Débogage pour voir si l'événement est déclenché
        JS.global[:console].log("Mousedown sur #{@id}")

        # Accéder aux propriétés de l'événement natif
        client_x = event[:clientX] || 0
        client_y = event[:clientY] || 0

        JS.global[:console].log("Coordonnées: x=#{client_x}, y=#{client_y}")
        start_drag(client_x, client_y)
      end

      # Utiliser une référence pour pouvoir la supprimer plus tard
      @mousemove_handler = proc { |native_event|
        event = Native(native_event)
        if @drag_state && @drag_state[:active]
          client_x = event[:clientX] || 0
          client_y = event[:clientY] || 0
          update_drag(client_x, client_y)
        end
      }

      @mouseup_handler = proc { |native_event|
        event = Native(native_event)
        if @drag_state && @drag_state[:active]
          end_drag
        end
      }

      # Ajouter les gestionnaires au document
      JS.global[:document].addEventListener(:mousemove, @mousemove_handler)
      JS.global[:document].addEventListener(:mouseup, @mouseup_handler)

      # Gestion tactile
      on(:touchstart) do |native_event|
        event = Native(native_event)
        JS.global[:console].log("Touchstart sur #{@id}")
        if event[:touches] && event[:touches].length > 0
          touch = Native(event[:touches][0])
          client_x = touch[:clientX] || 0
          client_y = touch[:clientY] || 0
          start_drag(client_x, client_y)
        end
      end

      @touchmove_handler = proc { |native_event|
        event = Native(native_event)
        if @drag_state && @drag_state[:active] && event[:touches] && event[:touches].length > 0
          touch = Native(event[:touches][0])
          client_x = touch[:clientX] || 0
          client_y = touch[:clientY] || 0
          update_drag(client_x, client_y)
        end
      }

      @touchend_handler = proc { |native_event|
        event = Native(native_event)
        if @drag_state && @drag_state[:active]
          end_drag
        end
      }

      # Ajouter les gestionnaires au document
      JS.global[:document].addEventListener(:touchmove, @touchmove_handler)
      JS.global[:document].addEventListener(:touchend, @touchend_handler)

      # Visuel de déplacement
      @element[:style][:cursor] = 'move'

      # Ajouter du texte explicite
      @element[:textContent] = "Drag me!"

      JS.global[:console].log("#{@id} est maintenant déplaçable")
    else
      # Désactiver le déplacement
      @drag_state = { active: false }
      @element[:style][:cursor] = 'default'

      # Supprimer les gestionnaires
      if @mousemove_handler
        JS.global[:document].removeEventListener(:mousemove, @mousemove_handler)
        JS.global[:document].removeEventListener(:mouseup, @mouseup_handler)
      end

      if @touchmove_handler
        JS.global[:document].removeEventListener(:touchmove, @touchmove_handler)
        JS.global[:document].removeEventListener(:touchend, @touchend_handler)
      end
    end

    self
  end

  # Débuter le déplacement
  def start_drag(client_x, client_y)
    JS.global[:console].log("Start drag à #{client_x}, #{client_y}")

    @drag_state = {
      active: true,
      start_x: client_x,
      start_y: client_y,
      offset_x: get_property(:x) || 0,
      offset_y: get_property(:y) || 0
    }

    # Effet visuel pour l'élément en cours de déplacement
    @element[:style][:opacity] = '0.8'
    @element[:style][:zIndex] = '1000'

    # Notification de début de déplacement
    notify_listeners(:drag_start, { x: client_x, y: client_y })
  end

  # Mettre à jour la position pendant le déplacement
  def update_drag(client_x, client_y)
    return unless @drag_state && @drag_state[:active]

    JS.global[:console].log("Update drag à #{client_x}, #{client_y}")

    # Calculer la nouvelle position
    delta_x = client_x - @drag_state[:start_x]
    delta_y = client_y - @drag_state[:start_y]

    new_x = @drag_state[:offset_x] + delta_x
    new_y = @drag_state[:offset_y] + delta_y

    # Mettre à jour la position
    set_property(:x, new_x)
    set_property(:y, new_y)

    # Notification de déplacement
    notify_listeners(:drag_move, { x: new_x, y: new_y })
  end

  # Terminer le déplacement
  def end_drag
    return unless @drag_state && @drag_state[:active]

    JS.global[:console].log("End drag à #{get_property(:x)}, #{get_property(:y)}")

    # Restaurer l'apparence
    @element[:style][:opacity] = '1'

    # Notification de fin de déplacement
    notify_listeners(:drag_end, { x: get_property(:x), y: get_property(:y) })

    # Réinitialiser l'état
    @drag_state[:active] = false
  end

  # ---------- Touch events ----------
  def touchable(enable = true)
    if enable
      # Gestion des événements tactiles de base
      @touch_state = { touching: false, start_time: 0, last_tap_time: 0 }

      on(:touchstart) do |event|
        JS.global[:console].log("Touchstart sur #{@id}")
        if event[:touches] && event[:touches].length > 0
          touch = event[:touches][0]
          client_x = touch[:clientX] || 0
          client_y = touch[:clientY] || 0
          handle_touch_start(client_x, client_y)
        end
      end

      on(:touchend) do |event|
        JS.global[:console].log("Touchend sur #{@id}")
        if @touch_state && @touch_state[:touching]
          handle_touch_end
        end
      end

      # Ajouter du texte explicite
      @element[:textContent] = "Tap me!"

      JS.global[:console].log("#{@id} est maintenant tactile")
    else
      @touch_state = { touching: false }
    end

    self
  end

  def handle_touch_start(x, y)
    JS.global[:console].log("Handle touch start à #{x}, #{y}")

    @touch_state = {
      touching: true,
      start_time: JS.global[:Date].now,
      start_x: x,
      start_y: y,
      last_tap_time: @touch_state ? @touch_state[:last_tap_time] || 0 : 0
    }

    # Notification de début de toucher
    notify_listeners(:touch_start, { x: x, y: y })
  end

  def handle_touch_end
    return unless @touch_state && @touch_state[:touching]

    now = JS.global[:Date].now
    duration = now - @touch_state[:start_time]

    JS.global[:console].log("Handle touch end, durée: #{duration}ms")

    # Détecter un tap (toucher court)
    if duration < 300
      # Détecter un double tap
      if now - @touch_state[:last_tap_time] < 500
        JS.global[:console].log("Double tap détecté!")
        notify_listeners(:double_tap, { x: @touch_state[:start_x], y: @touch_state[:start_y] })

        # Changement de couleur pour les double taps
        new_color = {
          red: JS.global[:Math].random,
          green: JS.global[:Math].random,
          blue: JS.global[:Math].random,
          alpha: 1.0
        }
        color(new_color)
      else
        JS.global[:console].log("Tap simple détecté!")
        notify_listeners(:tap, { x: @touch_state[:start_x], y: @touch_state[:start_y] })

        # Changement de couleur pour les taps simples
        new_color = {
          red: JS.global[:Math].random,
          green: JS.global[:Math].random,
          blue: JS.global[:Math].random,
          alpha: 0.7
        }
        color(new_color)
      end

      @touch_state[:last_tap_time] = now
    else
      # Toucher long
      JS.global[:console].log("Toucher long détecté!")
      notify_listeners(:long_touch, { x: @touch_state[:start_x], y: @touch_state[:start_y], duration: duration })
    end

    # Notification de fin de toucher
    notify_listeners(:touch_end, { x: @touch_state[:start_x], y: @touch_state[:start_y] })

    # Réinitialiser l'état
    @touch_state[:touching] = false
  end
end

# --- Shapes ------------------------------------------------
class Box < Atome
  def initialize(h = {})
    super(h)
    style(borderRadius: '0px')
  end
end

class Circle < Atome
  def initialize(h = {})
    super(h)
    style(borderRadius: '50%')
  end
end

# --- Colors -----------------------------------------------
class Color
  attr_reader :id, :red, :green, :blue, :alpha

  def initialize(h = {})
    @id    = h[:id] || "color_#{object_id}"
    @red   = h[:red]   || 0
    @green = h[:green] || 0
    @blue  = h[:blue]  || 0
    @alpha = h[:alpha] || 1.0
    AtomeRegistry.register(self)
  end

  def to_css
    "rgba(#{(@red*255).to_i},#{(@green*255).to_i},#{(@blue*255).to_i},#{@alpha})"
  end

  def apply(atome_id)
    at = AtomeRegistry.find_by_id(atome_id)
    at.color(self) if at
    self
  end
end

# --- Registry & DOM watcher -------------------------------
class AtomeRegistry
  @registry = {}
  @observers = []

  def self.register(obj)
    @registry[obj.id] = obj
    notify(:register, obj)
  end

  def self.find_by_id(id)
    @registry[id]
  end

  def self.add_observer(&blk)
    @observers << blk
  end

  def self.notify(action, obj)
    @observers.each { |observer| observer.call(action, obj) }
  end

  # DOM mutations -> notify(:dom_change, id)
  def self.watch_dom
    # Désactivé temporairement
    JS.global[:console].log("Watcher DOM désactivé temporairement")
  end

  def self.count
    @registry.size
  end

  def self.list_all
    @registry.keys.join(", ")
  end
end

# --- Helper factories -------------------------------------
def box(params = {})
  Box.new(params)
end

def circle(params = {})
  Circle.new(params)
end

def color(params = {})
  Color.new(params)
end

# --- String helper (camelize lower) -----------------------
class String
  def camelize(first = :upper)
    result = gsub(/(?:^|_)([a-z])/) { $1.upcase }

    if first == :lower && !result.empty?
      first_char = result[0].downcase
      result = first_char + result[1..-1]
    end

    result
  end
end