def new_data_source(params=nil)
  # Mock site
  site = ::Nanoc::Site.new({})
  params = {
    items_root: '/assets',
    path:       'foo/assets',
    compile:    ['application.css']
  }.merge(params)

  data_source = Nanoc::DataSources::Sprockets.new(site, nil, nil, params)
  data_source
end

def clean_up_dirs
  FileUtils.rm_rf 'foo'
  FileUtils.rm_rf 'foobar'
end

describe Nanoc::Sprockets do
end

describe Nanoc::DataSources::Sprockets do

  before :example do
    clean_up_dirs

    # Create Sample files
    FileUtils.mkdir_p 'foo/assets/stylesheets'
    File.open('foo/assets/stylesheets/application.css', 'w') do |f|
      f.write <<-APPCSS
      /*
       * =require ./module
       */
      body { background-color: red; }
      APPCSS
    end
    File.open('foo/assets/stylesheets/module.css',      'w') do |f|
      f.write <<-MODCSS
      h1 { color: blue; }
      MODCSS
    end
    FileUtils.mkdir_p 'foo/assets/javascripts'
    File.open('foo/assets/javascripts/application.js', 'w') do |f|
      f.write <<-APPJS
      //= require test
      function app() {
        // testing
      }
      APPJS
    end
    File.open('foo/assets/javascripts/test.js',        'w') do |f|
      f.write <<-TESTJS
      function test() {

      }
      TESTJS
    end
  end

  after :example do
    Sprockets::Helpers.configure do |c|
      c.digest = nil
      c.asset_host = nil
    end
  end

  after :context do
    clean_up_dirs
  end

  describe "type: sprockets" do
    it "should compile using sprockets directives" do
      data_source = new_data_source(items_root: '/assets',
                                   path: 'foo/assets',
                                   compile: ['application.css'])
      data_source.up

      # Get expected output
      out = data_source.send :items

      out.each do |o|
        expect(o.raw_content).to include 'h1 { color: blue; }'
        expect(o.raw_content).to include 'body { background-color: red; }'
      end
    end
  end

  describe "items_root: '/foobar/assets'" do
    it "should allow changing the path when assets are stored" do
      data_source = new_data_source(items_root: '/foobar/assets')
      data_source.up

      # Create Sample files
      FileUtils.mkdir_p 'foobar/assets/stylesheets'
      File.open('foobar/assets/stylesheets/application.css', 'w') do |f|
        f.write <<-APPCSS
        /*
         * =require ./module
         */
        body { background-color: red; }
        APPCSS
      end
      File.open('foobar/assets/stylesheets/module.css',      'w') do |f|
        f.write <<-MODCSS
        h1 { color: blue; }
        MODCSS
      end

      # Get expected output
      out = data_source.send :items

      out.each do |o|
        expect(o.raw_content).to include 'h1 { color: blue; }'
        expect(o.raw_content).to include 'body { background-color: red; }'
      end

    end
  end

  describe "compile: ['application.css','application.js']" do
    it "should compile css and js independently" do
      data_source = new_data_source(compile: ['application.css', 'application.js'])
      data_source.up

      # Get expected output
      out = data_source.send :items
      out.each do |o|
        case o[:filename]
        when "application.js"
          expect(o.raw_content).to include 'function app() {'
          expect(o.raw_content).to include 'function test() {'
        when "application.css"
          expect(o.raw_content).to include 'h1 { color: blue; }'
          expect(o.raw_content).to include 'body { background-color: red; }'
        end
      end
    end
  end

  describe "path: 'foo/output/assets'" do
    it "should allow compiling in different directories" do
      data_source = new_data_source(path: 'foo/output/assets')
      data_source.up

      # Get expected output
      out = data_source.send :items

      out.each do |o|
        expect(o.raw_content).to include 'h1 { color: blue; }'
        expect(o.raw_content).to include 'body { background-color: red; }'
        expect(o.asset_path(o[:filename])).to match %r(/foo/output/assets/application.css)
      end
    end
  end

  describe "css_compressor: scss" do
    it "should compile using scss/sass" do
      data_source = new_data_source(items_root: '/assets',
                                   path: 'foo/assets',
                                   css_compressor: 'scss',
                                   compile: ['application.css'])
      data_source.up

      # Create sample files
      FileUtils.mkdir_p 'foo/assets/stylesheets'
      File.open('foo/assets/stylesheets/application.css.sass', 'w') do |f|
        f.write <<-SASS
// =require ./module
body
  background-color: red
        SASS
      end
      File.open('foo/assets/stylesheets/module.css.sass',      'w') do |f|
        f.write <<-SASS
h1
  color: blue
        SASS
      end

      # Get expected output
      out = data_source.send :items

      out.each do |o|
        expect(o.raw_content).to include 'h1{color:blue}'
        expect(o.raw_content).to include 'body{background-color:red}'
      end
    end
  end

  describe "js_compressor: uglifier" do
    it "should compile javascript with uglifier" do
      data_source = new_data_source(compile: ['application.js'],
                                   js_compressor: 'uglifier')
      data_source.up


      # Get expected output
      out = data_source.send :items

      out.each do |o|
        expect(o.raw_content).to include 'function app(){}'  # application.js
        expect(o.raw_content).to include 'function test(){}' # test.js
      end
    end
  end

  describe "assets_additional_paths: ['foo/vendor/assets/stylesheets']" do
    it "should compile assets in additional paths" do
      data_source = new_data_source(assets_additional_paths: ['foo/vendor/assets/stylesheets'])
      data_source.up

      # Create Sample files
      FileUtils.mkdir_p 'foo/vendor/assets/stylesheets'
      File.open('foo/assets/stylesheets/application.css', 'w') do |f|
        f.write <<-APPCSS
        /*
         * =require ./module
         * =require vendor
         */
        body {
          background-color: red;
        }
        APPCSS
      end
      File.open('foo/vendor/assets/stylesheets/vendor.css', 'w') do |f|
        f.write <<-VENDORCSS
        p { color: #ededed; }
        VENDORCSS
      end

      # Get expected output
      out = data_source.send :items

      out.each do |o|
        expect(o.raw_content).to include 'p { color: #ededed; }'
      end
    end
  end

  describe "digest: true" do
    it "should compile using digest paths" do
      data_source = new_data_source(digest: true)
      data_source.up

      # Get expected output
      out = data_source.send :items

      out.each do |o|
        expect(o.raw_content).to include 'h1 { color: blue; }'
        expect(o.asset_path(o[:filename])).to match(%r(/assets/application-[0-9a-f]+.css))
      end
    end
  end

  describe "asset_host: " do

    before :context do
      FileUtils.mkdir_p 'foo/public'
      FileUtils.touch   'foo/public/image.png'
    end

    context "when a string" do
      it "prepends the asset_host" do
        data_source = new_data_source(asset_host: 'assets.example.com')
        data_source.up

        # Get expected output
        out = data_source.send :items

        expect(out.asset_path('application.css')).to eq 'http://assets.example.com/assets/application.css'
        expect(out.asset_path('image.png')).to match %r(http://assets.example.com/image.png)
      end
    end
    context "when a wildcard" do
      it "cycles asset_host" do
        data_source = new_data_source(asset_host: 'assets%d.example.com')
        data_source.up

        # Get expected output
        out = data_source.send :items

        expect(out.asset_path('application.css')).to match %r(http://assets[0-3].example.com/assets/application.css)
        expect(out.asset_path('image.png')).to match %r(http://assets[0-3].example.com/image.png)
      end
    end
    context "when a proc" do
      it "prepends the returned asset_host" do
        data_source = new_data_source(asset_host: Proc.new { |source| File.basename(source, File.extname(source)) + '.assets.example.com' })
        data_source.up

        # Get expected output
        out = data_source.send :items

        expect(out.asset_path('application.css')).to eq 'http://application.assets.example.com/assets/application.css'
        expect(out.asset_path('image.png')).to match %r(http://image.assets.example.com/image.png)
      end
    end
  end
end
