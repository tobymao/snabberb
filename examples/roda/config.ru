# frozen_string_literal: true

require 'execjs'
require 'opal'
require 'roda'
require 'snabberb'
require 'tilt/opal'

class OpalTemplate < Opal::TiltTemplate
  def evaluate(_scope, _locals)
    builder = Opal::Builder.new(stubs: 'opal')
    builder.append_paths('assets/js')
    builder.append_paths('build')

    opal_path = 'build/compiled-opal.js'
    File.write(opal_path, Opal::Builder.build('opal')) unless File.exist?(opal_path)

    content = builder.build(file).to_s
    map_json = builder.source_map.to_json
    "#{content}\n#{to_data_uri_comment(map_json)}"
  end

  def to_data_uri_comment(map_json)
    "//# sourceMappingURL=data:application/json;base64,#{Base64.encode64(map_json).delete("\n")}"
  end
end

Tilt.register 'rb', OpalTemplate

class App < Roda
  plugin :public
  plugin :assets, js: 'application.rb'
  compile_assets
  context = ExecJS.compile(File.read("#{assets_opts[:compiled_js_path]}.#{assets_opts[:compiled]['js']}.js"))

  route do |r|
    r.public
    r.assets

    r.root do
      context.eval(
        Snabberb.prerender_script(
          'Index',
          'Map',
          'map_id',
          javascript_include_tags: assets(:js),
          size_x: 30,
          size_y: 30,
        )
      )
    end
  end
end

run App.freeze.app
