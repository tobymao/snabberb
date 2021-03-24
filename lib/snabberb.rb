# frozen_string_literal: true

require 'json'
require 'opal'
require 'snabberb/version'

Opal.append_path(File.expand_path('../opal', __dir__))

module Snabberb
  def self.wrap(obj)
    case obj
    when Hash
      wrap_h(obj)
    when Array
      wrap_a(obj)
    when Numeric, TrueClass, FalseClass
      obj
    when nil
      'Opal.nil'
    else
      wrap_s(obj.to_s)
    end
  end

  def self.wrap_s(str)
    JSON.generate(str)
  end

  def self.wrap_a(array)
    "[#{array.map { |v| wrap(v) }.join(',')}]"
  end

  def self.wrap_h(hash)
    args = hash.flat_map do |k, v|
      [wrap_s(k), wrap(v)]
    end.join(',')

    "Opal.hash(#{args})"
  end

  # takes in a file and needs
  # calls html on the CamelCased version of the file with the needs
  def self.html_script(file, **needs)
    klass = file.split('/').last
                .split('.').first
                .split('_').map(&:capitalize).join

    script = <<~RUBY
      #{File.read(file)}
      #{klass}.html(`#{wrap(needs)}`)
    RUBY

    Opal.compile(script).strip.chomp(';')
  end

  def self.prerender_script(layout, application, application_id, javascript_include_tags: '', **needs)
    needs = wrap(needs)
    attach_func = wrap_s("Opal.#{application}.$attach(\"#{application_id}\", #{needs})")

    <<~JS
      Opal.#{layout}.$html(Opal.hash({
        application: Opal.#{application}.$new(null, #{needs}).$render(),
        javascript_include_tags: '#{javascript_include_tags.gsub("\n", '')}',
        attach_func: #{attach_func}
      }))
    JS
  end
end
