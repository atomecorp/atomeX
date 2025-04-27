require "js"
require "native"

# Override JS.global to wrap window with Native
module JS
  class << self
    alias_method :original_global, :global unless method_defined?(:original_global)
    def global
      @global ||= Native(JS[:window])
    end
  end
end