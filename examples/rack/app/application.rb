# frozen_string_literal: true

require 'opal'
require 'snabberb'

class Row < Snabberb::Component
  needs :index
  needs :value
  needs :selected_id, default: nil, store: true

  def selected?
    @index == @selected_id
  end

  def render
    onclick = lambda do
      store(:selected_id, selected? ? nil : @index)
    end

    style = {
      cursor: 'pointer',
      border: 'solid 1px rgba(0,0,0,0.2)',
    }

    style['background-color'] = 'lightblue' if selected?

    h(:div, { style: style, on: { click: onclick } }, [
      h(:div, @value)
    ])
  end
end

class Form < Snabberb::Component
  needs :values, store: true

  def render
    input = h(:input, props: { type: 'text', value: @values.last })

    onclick = lambda do |event|
      value = input.JS['elm'].JS['value']
      event.JS.preventDefault
      store(:values, @values + [value])
    end

    h(:form, { style: { width: '300px' } }, [
      input,
      h(:button, { on: { click: onclick } }, 'Add row'),
    ])
  end
end

class Application < Snabberb::Component
  needs :values, store: true

  def render
    rows = @values.map.with_index do |value, index|
      h(Row, index: index, value: value)
    end

    h(:div, { style: { width: '100px' } }, [
      h(:div, 'List of Fruits'),
      *rows,
      h(Form),
    ])
  end
end

Application.attach('app', values: %w[apple banana cantaloupe])
