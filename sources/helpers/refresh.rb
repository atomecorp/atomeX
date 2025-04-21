require  './web_builder.rb'
rebuild_opal=false
copy_ressources=false
copy_app=false
# ARGV.each_with_index do |arg, i|
#   puts "  #{i + 1}: #{arg}"
# end
web_builder = BuilderScript.new
web_builder.copy_app_directory
web_builder.compile_opal

# html_builder=HtmlBuilder.new
# html_builder.build_all
