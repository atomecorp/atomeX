require 'listen'
require 'fileutils'
require './web_builder.rb'
listener=Listen.to('app/') do |modified, _added, _removed|
   modified.each do |file|
     filename = File.basename(file)
     puts filename
   end
   builder = BuilderScript.new
    builder.copy_app_directory
   builder.compile_opal_application

end

 Listen.to('sources/') do |modified, _added, _removed|
  modified.each do |file|
    filename = File.basename(file)
    puts filename  end
end

 Listen.to('html_sources/') do |modified, _added, _removed|
  modified.each do |file|
    filename = File.basename(file)
    puts filename  end
end



puts "👂 Watching app/ pour hot reload avec Opal..."
listener.start
sleep