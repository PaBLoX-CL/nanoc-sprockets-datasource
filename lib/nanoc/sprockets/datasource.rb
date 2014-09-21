# encoding: utf-8

require "nanoc"
require "sprockets"
require "sprockets-helpers"

module Nanoc::DataSources
  class Sprockets < Nanoc::DataSource
    identifier :sprockets
    LOOSE_ASSETS = lambda do |filename, path|
      path =~ /assets/ && !%w(.js .css).include?(File.extname(filename))
    end

    # See {Nanoc::DataSource#up}
    def up
      @config = {
        path: 'assets',
        compile: [],
        assets_additional_paths: []
      }.merge(@config)
    end

    # See {Nanoc::DataSource#items}.
    #
    # These 3 files: `.bower.json` `bower.json` `component.json`, require
    # special treatment because Sprockets use them to correctly bundle the
    # assets included in each package.
    def items
      assets = environment.each_logical_path(*compiled_assets).to_a
      assets.delete_if {|asset| %w( .bower.json bower.json component.json ).include? File.basename(asset) }

      assets.map do |bundle|
        asset = environment.find_asset(bundle)
        extension = File.extname(bundle)[1..-1]
        is_binary = !!(asset.pathname && !@site.config[:text_extensions].include?(extension))

        content_of_filename = is_binary ? asset.pathname : asset.to_s
        attributes = {filename: bundle, binary: is_binary, mtime: asset.mtime, extension: extension}
        next unless (is_binary || environment.extensions.include?(File.extname(bundle)))
        Nanoc::Item.new(content_of_filename, attributes, bundle, attributes)
      end.compact
    end

    protected
    def environment
      @environment ||= create_environment
    end

    def create_environment
      env = ::Sprockets::Environment.new

      %w(javascripts images stylesheets fonts).each do |asset|
        env.append_path File.join(config[:path], asset)
      end
      config[:assets_additional_paths].each do |path|
        env.append_path path
      end
      env.js_compressor  = config[:js_compressor].to_sym  if config[:js_compressor]
      env.css_compressor = config[:css_compressor].to_sym if config[:css_compressor]

      # Configure Sprockets::Helpers
      ::Sprockets::Helpers.configure do |c|
        c.environment = env
        c.prefix      = config[:items_root]
        c.asset_host  = config[:asset_host] if config[:asset_host]
        c.digest      = config[:digest]     if config[:digest]
      end
      env
    end

    def compiled_assets
      config[:compile] + [LOOSE_ASSETS]
    end
  end
end
