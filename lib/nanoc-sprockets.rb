# encoding: utf-8

require "sprockets"
require "sprockets-helpers"

module Nanoc::DataSources
  class SprocketsDataSource < Nanoc::DataSource
    identifier :sprockets
    LOOSE_ASSETS = lambda do |filename, path|
      path =~ /assets/ && !%w(.js .css).include?(File.extname(filename))
    end

    def items
      assets = environment.each_logical_path(*compiled_assets).to_a

      assets.map do |bundle|
        asset = environment.find_asset(bundle)
        is_binary = !!(asset.pathname && !@site.config[:text_extensions].include?(File.extname(asset.pathname)[1..-1]))

        attributes = {filename: bundle, binary: is_binary, mtime: asset.mtime}
        if is_binary
          Nanoc::Item.new(asset.pathname, attributes, bundle, attributes)
        else
          Nanoc::Item.new(asset.to_s, attributes, bundle, attributes)
        end
      end
    end

    protected
    def environment
      @environment ||= create_environment
    end

    def create_environment
      env = ::Sprockets::Environment.new

      env.append_path File.join(config[:path], 'javascripts')
      env.append_path File.join(config[:path], 'images')
      env.append_path File.join(config[:path], 'stylesheets')
      config[:assets_path].each do |path|
        env.append_path File.join(config[:path], path)
      end
      env.js_compressor  = config[:js_compressor].to_sym
      env.css_compressor = config[:css_compressor].to_sym

      # Configure Sprockets::Helpers
      Sprockets::Helpers.configure do |c|
        c.environment = env
        c.prefix      = config[:items_root]
        c.digest      = production?
      end
      env
    end

    def compiled_assets
      config[:compile] + [LOOSE_ASSETS]
    end
  end
end
include Sprockets::Helpers
