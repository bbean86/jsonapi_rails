require 'rails/generators'

class JsonapiRailsRailtie < Rails::Generators::Base
  source_root File.expand_path(File.dirname(__FILE__))
  def copy_initializer
    copy_file 'jsonapi_rails.rb', 'config/initializers/jsonapi_rails.rb'
  end
end
