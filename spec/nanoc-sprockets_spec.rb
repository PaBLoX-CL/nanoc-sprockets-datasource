require "spec_helper"

def new_data_source(params=nil)
  # Mock site
  site = ::Nanoc::Site.new({})
  data_source = Nanoc::DataSources::Sprockets.new(site, nil, nil, params)
  data_source
end

describe Nanoc::Sprockets do
  describe "VERSION" do
    it "returns the version" do
      expect(Nanoc::Sprockets::VERSION).to eq('0.0.2')
    end
  end
end

describe Nanoc::DataSources::Sprockets do
  it "should compile using sprockets directives" do

    # Create data source and configure it
    data_source = new_data_source(items_root: '/assets',
                                  path: 'foo/assets',
                                  compile: ['application.css'])
    data_source.up

    # Create Sample files
    FileUtils.mkdir_p 'foo/assets/stylesheets'
    File.open('foo/assets/stylesheets/application.css', 'w') do |f|
      f.write <<-APPCSS
      /*
       * =require ./module
       */
      body {
        background-color: red;
      }
      APPCSS
    end
    File.open('foo/assets/stylesheets/module.css',      'w') do |f|
      f.write <<-MODCSS
      h1 { color: blue; }
      MODCSS
    end

    # Get expected output
    out = data_source.send :items

    out.each do |o|
      expect(o.raw_content).to include 'h1 { color: blue; }'
    end

  end
end
