require "js"
begin
  # For Opal: we import Native to benefit from the wrapper and the [] operator
  require 'native'
rescue LoadError
  # In Ruby WASM, this require will fail, which is normal
end

if defined?(JS) && defined?(Native)
  # In Opal, JS and Native are defined: we override JS.global to wrap window with Native
  module JS
    class << self
      alias_method :original_global, :global unless method_defined?(:original_global)
      def global
        @global ||= Native(`window`)
      end
    end
  end
elsif defined?(JS) && !defined?(Native)
  # In Ruby WASM, if Native is not defined, we define it minimally
  module Native
    def self.[](obj)
      obj
    end
  end
end
