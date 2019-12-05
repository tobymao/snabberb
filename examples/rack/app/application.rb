# frozen_string_literal: true

require 'opal'
require 'snabberb'

class Row < Snabberb::Component
  needs :index
  needs :value

  def selected?
    @index == store(:selected_id)
  end

  def render
    onclick = lambda do
      set_store(:selected_id, selected? ? nil : @index)
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
  def render
    input = h(:input, props: { type: 'text', value: store(:values).last })

    onclick = lambda do |event|
      value = input.JS['elm'].JS['value']
      event.JS.preventDefault
      set_store(:values, store(:values) + [value])
    end

    h(:form, { style: { width: '300px' } }, [
      input,
      h(:button, { on: { click: onclick } }, 'Add row'),
    ])
  end
end

class Application < Snabberb::Component
  needs :values, store: true
  needs :selected_id, default: nil, store: true

  def render
    rows = store(:values).map.with_index do |value, index|
      c(Row, index: index, value: value)
    end

    h(:div, { style: { width: '100px' } }, [
      h(:div, 'Rows'),
      *rows,
      c(Form),
    ])
  end
end

Application.attach('app', values: [1, 2, 3])
