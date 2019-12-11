# frozen_string_literal: true

require 'execjs'
require 'json'
require 'opal'
require 'opal/sprockets'
require 'roda'
require 'sprockets'
require 'snabberb'

LIB_NAME = 'lib.js'
LIB_PATH = "./public/#{LIB_NAME}"
Opal.append_path('app')
File.write(LIB_PATH, Opal::Builder.build('requires')) unless File.file?(LIB_PATH)

class App < Roda
  plugin :public

  context = ExecJS.compile(File.read(LIB_PATH) + Opal::Builder.build('application').to_s)

  environment = Sprockets::Environment.new
  Opal.paths.each { |p| environment.append_path(p) }

  javascript_include_tags = "<script src=#{LIB_NAME}></script>" + Opal::Sprockets.javascript_include_tag(
    'application',
    sprockets: environment,
    prefix: '/assets',
    debug: true,
  )

  route do |r|
    r.public

    r.on 'assets' do
      r.run environment
    end

    r.root do
      context.eval(
        Snabberb.prerender_script(
          'Index',
          'Map',
          'map_id',
          javascript_include_tags: javascript_include_tags,
          size_x: 30,
          size_y: 30,
        )
      )
    end
  end
end

run App.freeze.app
