alias original_require require
def require(path)
  begin
    original_require(path)
  rescue LoadError => e
    JS.global.ruby_require(path).then do |content|
      eval(content.to_s)
    end.catch do |error|
      puts "===> Erreur: #{error}"
    end
  end
end

require "js"