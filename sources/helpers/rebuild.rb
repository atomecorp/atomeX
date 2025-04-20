require  './builder.rb'
web_builder = BuilderScript.new
web_builder.copy_app_directory
web_builder.compile_opal
# html_builder=HtmlBuilder.new
# html_builder.build_all
