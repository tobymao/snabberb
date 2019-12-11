# frozen_string_literal: true

require 'json'
require 'opal'
require 'snabberb/version'

Opal.append_path(File.expand_path('../opal', __dir__))

module Snabberb
  def self.prerender_script(layout, application, application_id, javascript_include_tags: '', **needs)
    needs = JSON.generate(needs)

    <<~JS
      Opal.$$.#{layout}.$html(Opal.hash({
        application: Opal.$$.#{application}.$new(null, Opal.hash(#{needs})).$render(),
        javascript_include_tags: '#{javascript_include_tags.gsub("\n", '')}',
        attach_func: 'Opal.$$.#{application}.$attach("#{application_id}", Opal.hash(#{needs}))'
      }))
    JS
  end
end
