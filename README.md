# Snabberb

Snabberb is a simple Ruby view framework built on [Opal](https://github.com/opal/opal) and [Snabbdom](https://github.com/snabbdom/snabbdom).

You can write reactive views in plain Ruby that compile to efficient Javascript.

## Inline Example

```ruby
require 'opal'
require 'snabberb'

class TextBox < Snabberb::Component
  needs :text
  needs :selected, default: false, store: true

  def render
    onclick = lambda do
      store(:selected, !@selected)
    end

    style = {
      cursor: 'pointer',
      border: 'solid 1px rgba(0,0,0,0.2)',
    }

    style['background-color'] = 'lightblue' if @selected

    h(:div, { style: style, on: { click: onclick } }, [
      h(:div, @text)
    ])
  end
end


# Assuming you have a DOM element with ID=app
TextBox.attach('app', text: 'hello world')

# Or you can get the HTML string for isomorphic applications
TextBox.html(text: 'hello world')
```

## Examples
[Rack App](examples/rack)

[Roda App with HTML Prerendering](examples/roda)

[18xx Board Game Engine](https://github.com/tobymao/18xx)

## Usage

### Creating DOM Elements With h

Subclass Snabberb::Component and override #render to build divs using \#h.

Render should only return one root element.

\#h takes either a DOM symbol (:div, :span, :a, ...) or another Snabberb::Component class.

```ruby
...
class DomExample < Snabberb::Component
  def render
    h(:div)
  end
end

class ComponentExample < Snabberb::Component
  def render
    h(OtherComponent)
  end
end
```

Like Snabbdom, \#h with DOM elements can take props which take the form of a dict.

```ruby
...
class PropsExample < Snabberb::Component
  def render
    h(:div, { style: { display: 'inline-block' }, class: { selected: true } })
  end
end
```

Components do not take props, instead they take [needs](#Needs) which are dependent arguments.

```ruby
...
class PassingNeedsExample < Snabberb::Component
  def render
    h(ChildComponent, need1: 1, need2: 2)
  end
end
```

\#h can also be nested with a child or multiple children.

```ruby
...
class NestedExample < Snabberb::Component
  def render
    h(:div, [
      h(ChildComponent, need1: 1, need2: 2),
      h(:div, { style: { width: '100px' } }, [
        h(:div, 'hello'),
      ])
    ](
  end
end
```

### Needs

Components can define needs which allow parent components to pass down arguments. They can also be stateful which allows changes to propogate easily throughout the application.

Needs are by default required. They can be set with default values. Needs are accesible with instance variables that are automatically set.

```ruby
...
class NeedsExample < Snabberb::Component
  needs :name
  needs :value, default: 0, store: true

  def render
    onclick = lambda do
      store(:value, @value + 1)
    end

    h(:div, [
      h(:div, @name),
      h(:div, { on: { click: onclick} }, @value),
    ])
  end
end
```

When simple state changes must be tracked, a need can define store: true. This will use the stored value of this key which is set on the root node.
The precedence of need values is stored > passed needs > default value.

Needs can be set with #store which will trigger a view update. Snabberb uses Snabbdom to update the DOM, so only the differences in the DOM are changed.

### Prerendering

You can prerender your HTML by calling

```ruby
Snabberb.prerender_script('LayoutClass', 'ApplicationClass', 'application_id', javascript_include_tags: '', **needs)
```

A detailed example can be found [in the Roda example](examples/roda).

### Generating HTML from a File

You can generate HTML from a component with a file.

Snabberb.html('path/to/my\_component.rb', **needs)

This reads in the ruby file at the path and calls html on the CamelCased version of the file name.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'snabberb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snabberb

## Development

```
bundle install
bundle exec rake
```
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tobymao/snabberb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
