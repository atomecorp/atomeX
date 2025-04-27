# require "js"
# require "js/require_remote"
#
# module Kernel
#   alias_method :original_require, :require
#
#   def require(path)
#     if path.end_with?(".rb")
#       absolute_path = File.expand_path(path)
#       JS::RequireRemote.instance.load(absolute_path)
#     else
#       original_require(path)
#     end
#   end
# end
require "js"
require "js/require_remote"

module Kernel
  alias_method :original_require, :require

  def require(path)
    if path.end_with?(".rb")
      # Si le path n'est pas déjà dans ./app/, on le préfixe
      unless path.start_with?("./app/")
        path = "./app/#{path}"
      end
      absolute_path = File.expand_path(path)
      JS::RequireRemote.instance.load(absolute_path)
    else
      original_require(path)
    end
  end
end