require 'listen'
require 'fileutils'

listener = Listen.to('app/') do |modified, added, removed|
  puts "🔁 Fichier modifié, recompilation..."
  puts "Modified files: #{modified.join(', ')}" unless modified.empty?
  puts "Added files: #{added.join(', ')}" unless added.empty?
  puts "Removed files: #{removed.join(', ')}" unless removed.empty?
  
  # Copy the modified files to build/app
  (modified + added).each do |file|
    relative_path = file.sub(/^app\//, '')
    dest_path = File.join('build/app', relative_path)
    FileUtils.mkdir_p(File.dirname(dest_path))
    FileUtils.cp(file, dest_path)
    puts "Copied #{file} to #{dest_path}"
  end
  
  # Recompile index.rb if it was modified
  if modified.any? { |file| file.end_with?('index.rb') } || added.any? { |file| file.end_with?('index.rb') }
    puts "Recompiling Opal application..."
    system("cat build/app/index.rb | bundle exec opal --no-opal --compile --enable-source-location - > build/opal/application.js")
    if $?.success?
      puts "✅ Recompilation successful"
    else
      puts "❌ Recompilation failed"
    end
  end
end

puts "👂 Watching app/ pour hot reload avec Opal..."
listener.start
sleep