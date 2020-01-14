# frozen_string_literal: true

require 'compiled-opal'
require 'polyfill'
require 'snabberb'
require 'set'

class Tile < Snabberb::Component
  def render
    h(:g, { attrs: { transform: 'rotate(60)' } }, [
      h(:path, attrs: { d: 'm 0 87 L 0 -87', stroke: 'black', 'stroke-width' => 8 }),
      h(:path, attrs: { d: 'm -4 86 L -4 -86', stroke: 'white', 'stroke-width' => 2 }),
      h(:path, attrs: { d: 'm 4 86 L 4 -86', stroke: 'white', 'stroke-width' => 2 }),
    ])
  end
end

class Hex < Snabberb::Component
  SIZE = 100
  POINTS = '100,0 50,-87 -50,-87 -100,-0 -50,87 50,87'

  needs :x
  needs :y
  needs :selected, default: Set.new, store: true

  def translation
    offset = self.class::SIZE
    x = self.class::SIZE * Math.sqrt(3) / 2 * @x + offset
    y = self.class::SIZE * 3 / 2 * @y + offset
    "translate(#{x}, #{y})"
  end

  def transform
    "#{translation} rotate(30)"
  end

  def render
    coordinates = [@x, @y]
    selected = @selected.include?(coordinates)
    children = [h(:polygon, attrs: { points: self.class::POINTS })]
    children << h(Tile) if selected

    onclick = lambda do
      if selected
        store(:selected, @selected - [coordinates])
      else
        store(:selected, @selected | [coordinates])
      end
    end

    props = {
      attrs: {
        transform: transform,
        fill: selected ? 'yellow' : 'white',
        stroke: 'black',
      },
      style: { cursor: 'pointer' },
      on: { click: onclick }
    }

    h(:g, props, children)
  end
end

class Map < Snabberb::Component
  needs :size_x
  needs :size_y

  def render
    hexes = @size_x.times.flat_map do |x|
      @size_y.times.map do |y|
        h(Hex, x: y.even? ? x + 1 : x, y: x.even? ? y + 1 : y)
      end
    end

    container_style = {
      width: '100%',
      height: '100%',
      overflow: 'auto',
    }

    # adding 44 and 21 helps with lower size_x and size_y values
    svg_style = {
      width: "#{44 + (@size_x * 50)}px",
      height: "#{21 + (@size_y * 80)}px",
    }

    h(:div, { props: { id: 'map_id' }, style: container_style }, [
      h(:svg, { style: svg_style }, [
        h(:g, { attrs: { transform: 'scale(0.5)' } }, hexes)
      ])
    ])
  end
end

class Index < Snabberb::Layout
  def render
    h(:html, [
      h(:head, [
        h(:meta, props: { charset: 'utf-8' }),
        h(:title, 'Roda Demo'),
      ]),
      h(:body, [
        @application,
        h(:div, props: { innerHTML: @javascript_include_tags }),
        h(:script, props: { innerHTML: @attach_func }),
      ]),
    ])
  end
end
