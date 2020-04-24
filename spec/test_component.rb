# frozen_string_literal: true

class TestComponent < Snabberb::Component
  needs :groceries

  def render
    props = {
      style: { width: '100%' },
    }

    groceries = @groceries.map do |name, count|
      h(:div, "#{name} - #{count}")
    end

    h(:div, props, groceries)
  end
end
