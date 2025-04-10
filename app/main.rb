# require "js"
# require "js/require_remote"
#
# module Kernel
#   alias_method :original_require_relative, :require_relative
#   def require_relative(path)
#     JS::RequireRemote.instance.load(path)
#   end
# end

require_relative('./app/test')

JS.global[:document].write "Hello, world!"