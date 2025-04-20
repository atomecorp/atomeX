require "js"
require "js/require_remote"

module Kernel
  alias_method :original_require, :require

  def require(path)
    if path.end_with?(".rb")
      absolute_path = File.expand_path(path)
      JS::RequireRemote.instance.load(absolute_path)
    else
      original_require(path)
    end
  end
end