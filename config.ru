require 'bundler'
Bundler.require

sprockets = Sprockets::Environment.new.tap do |s|

  # register slim
  s.register_engine '.slim', Slim::Template


  # add folders
  s.append_path 'app'
  s.append_path 'views'
  s.append_path 'styles'
  s.append_path 'images'


  # add paths from rails-assets
  RailsAssets.load_paths.each do |p|
    s.append_path p
  end
end

sprockets.context_class.class_eval do 
  def asset_path(path, options ={}) 
  end
end

run Opal::Server.new(sprockets: sprockets) {|s|
      # the name of the ruby file to load. To use more files they must be required from here (see app)
      s.main = 'app'
      # need to set the index explicitly for opal server to pick it up
      s.index_path = 'views/index.html.slim'

    }
