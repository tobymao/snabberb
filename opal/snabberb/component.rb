# frozen_string_literal: true

module Snabberb
  class Component
    attr_accessor :node
    attr_reader :root

    %x{
      const VOID = new Set([
        'area',
        'base',
        'br',
        'col',
        'embed',
        'hr',
        'img',
        'input',
        'keygen',
        'link',
        'meta',
        'param',
        'source',
        'track',
        'wbr',
      ])

      const IGNORE = new Set([
        'attributes',
        'childElementCount',
        'children',
        'classList',
        'clientHeight',
        'clientLeft',
        'clientTop',
        'clientWidth',
        'currentStyle',
        'firstElementChild',
        'innerHTML',
        'lastElementChild',
        'nextElementSibling',
        'ongotpointercapture',
        'onlostpointercapture',
        'onwheel',
        'outerHTML',
        'previousElementSibling',
        'runtimeStyle',
        'scrollHeight',
        'scrollLeft',
        'scrollLeftMax',
        'scrollTop',
        'scrollTopMax',
        'scrollWidth',
        'tabStop',
        'tagName',
      ])

      const BOOLEAN = new Set([
        'disabled',
        'visible',
        'checked',
        'readonly',
        'required',
        'allowfullscreen',
        'autofocus',
        'autoplay',
        'compact',
        'controls',
        'default',
        'formnovalidate',
        'hidden',
        'ismap',
        'itemscope',
        'loop',
        'multiple',
        'muted',
        'noresize',
        'noshade',
        'novalidate',
        'nowrap',
        'open',
        'reversed',
        'seamless',
        'selected',
        'sortable',
        'truespeed',
        'typemustmatch',
      ])
    }

    %x{
      const PATCHER = snabbdom.init([
        snabbdom.attributesModule,
        snabbdom.classModule,
        snabbdom.datasetModule,
        snabbdom.eventListenersModule,
        snabbdom.propsModule,
        snabbdom.styleModule,
      ])
    }

    # You can define needs in each component. They are automatically set as instance variables
    #
    # For example:
    #   class Example < Component
    #     needs :value
    #     needs :name, default: 'Name', store: true
    #
    # Opts:
    #   :default - Sets the default value, if not passed the need is considered required.
    #   :store - Whether or not to store the need as state. The default is false.
    def self.needs(key, **opts)
      class_needs[key] = opts
    end

    def self.class_needs
      @class_needs ||= superclass.respond_to?(:class_needs) ? superclass.class_needs.clone : {}
    end

    # Attach the root component to a dom element by container id.
    def self.attach(container, **passed_needs)
      component = new(nil, passed_needs)
      component.node = `document.getElementById(#{container})`
      component.update!
    end

    # Render the component as an HTML string using snabbdom-to-html.
    def self.html(**passed_needs)
      component = new(nil, passed_needs)
      component.html
    end

    # You should not call initialize manually.
    def initialize(root, needs)
      @root = root || self
      @store = root? ? {} : @root.store

      unused = needs.keys - class_needs.keys
      raise "Unused needs passed to component: #{unused}." unless unused.empty?

      init_needs(needs)
    end

    def root?
      self == @root
    end

    # Subclasses should override this and return a single h (can be nested).
    def render
      raise NotImplementedError
    end

    def html
      node_to_s(render)
    end

    # Building block for dom elements using Snabbdom h and Snabberb components.
    #
    # Props are not required for HTML tags and children can be passed as the second argument.
    # Components do not take in children as they are already embeded within the class.
    #
    # For eaxmple:
    #   h(:div, 'Hello world')
    #   h(:div, { style: { width: '100%' }, 'Hello World!')
    #   h(:div, [h(:div), h(:div)])
    #   h(MyComponent, need1=1, need2=2)
    def h(element, props = {}, children = nil)
      if element.is_a?(Class)
        raise "Element '#{element}' must be a subclass of #{self.class}" unless element <= Component

        component = element.new(@root, **props)
        component.render
      else
        props_is_hash = props.is_a?(Hash)
        children = props if !children && !props_is_hash
        props = {} unless props_is_hash
        children = children.to_n if children.is_a?(String)
        `snabbdom.h(#{element}, #{Native.convert(props)}, #{children})`
      end
    end

    # Update the dom with the request animation frame queue.
    # Add to a queue of request_ids so we can track calls.
    def update
      request_ids << `window.requestAnimationFrame(function(timestamp) {#{update!}})`
    end

    # Update the dom immediately if this is the final animation request.
    def update!
      request_ids.shift
      return unless request_ids.empty?

      node = @root.render
      `PATCHER(#{root.node}, #{node})`
      @root.node = node
    end

    # Store a value and trigger and update unless skip is true.
    # If called with no arguments, return the store object.
    def store(key = nil, value = nil, skip: false)
      return @store if key.nil?
      raise "Cannot store key '#{key}' since it is not a stored need of #{self.class}." unless stores?(key)

      @store[key] = value

      ivar = "@#{key}"
      instance_variable_set(ivar, value)
      @root.instance_variable_set(ivar, value) if !root? && @root.stores?(key)

      update unless skip
    end

    def class_needs
      self.class.class_needs
    end

    def stores?(key)
      class_needs.dig(key, :store)
    end

    def request_ids
      root? ? @request_ids ||= [] : @root.request_ids
    end

    private

    def init_needs(needs)
      class_needs.each do |key, opts|
        ivar = "@#{key}"
        if @store.key?(key) && opts[:store]
          instance_variable_set(ivar, @store[key])
        elsif needs.key?(key)
          @store[key] = needs[key] if opts[:store] && !@store.key?(key)
          instance_variable_set(ivar, needs[key])
        elsif opts&.key?(:default)
          instance_variable_set(ivar, opts[:default])
        else
          raise "Needs '#{key}' required but not provided."
        end
      end
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def parse_sel(sel)
      %x{
        let tag = ''
        let id = ''
        const classes = {}
        const parts = sel.split(".")

        parts.forEach((part, index) => {
          if (index == 0) {
            part = part.split('#')
            if (part.length > 1) id = part[1]
            part = part[0]
            index == 0 ? tag = part : classes[part] = true
          } else if (!tag) {
            tag = part
          } else {
            classes[part] = true
          }
        })

        return {
          tag: tag,
          id: id,
          classes: classes,
        }
      }
    end

    def node_to_s(vnode)
      %x{
        if (!vnode.sel) return self.$escape(vnode.text)

        const sel = self.$parse_sel(vnode.sel)

        for (const key in vnode.data.class) {
          vnode.data.class[key] ? sel['classes'][key] = true : delete sel['classes'][key]
        }

        let attributes = {}
        if (sel['id'].length > 0) attributes['id'] = sel['id']

        const classes = Object.keys(sel['classes'])
        if (classes.length > 0) attributes['class'] = classes.join(' ')

        for (const key in vnode.data.attrs) {
          attributes[key] = vnode.data.attrs[key]
        }

        for (const key in vnode.data.dataset) {
          attributes['data-' + key] = vnode.data.dataset[key]
        }

        for (const key in vnode.data.props) {
          if (!IGNORE.has(key)) {
            const value = vnode.data.props[key]

            if (BOOLEAN.has(key)) {
              if (value) attributes[key] = key
            } else {
              attributes[key] = value
            }
          }
        }

        const styles = []

        for (let key in vnode.data.style) {
          const value = vnode.data.style[key]
          key = key.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase()
          styles.push(key + ': ' + value)
        }

        if (styles.length > 0) attributes['style'] = styles.join('; ')

        attributes = Object.keys(attributes).map(key =>
          self.$escape(key) + '="' + self.$escape(attributes[key]) + '"'
        )

        const tag = sel['tag']
        const elements = ['<' + tag]
        if (attributes.length > 0) elements.push(' ' + attributes.join(' '))
        elements.push('>')

        if (!VOID.has(tag)) {
          if (vnode.data.props && vnode.data.props.innerHTML) {
            elements.push(vnode.data.props.innerHTML)
          } else if (vnode.text) {
            elements.push(self.$escape(vnode.text))
          } else if (vnode.children) {
            vnode.children.forEach(child =>
              elements.push(self.$node_to_s(child))
            )
          }

          elements.push('</' + tag + '>')
        }

        return elements.join('')
      }
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def escape(html)
      ERB::Util.html_escape(html)
    end
  end

  # Sublcass this to prerender applications.
  class Layout < Snabberb::Component
    needs :application # the rendered application
    needs :attach_func # function to reattach the application after dom load
    needs :javascript_include_tags # all necessary javascript tags

    # Example render function.
    # def render
    #   h(:html, [
    #     h(:head, [
    #       h(:meta, { props: { charset: 'utf-8'} }),
    #     ]),
    #     h(:body, [
    #       @application,
    #       h(:div, { props:  { innerHTML: @javascript_include_tags } }),
    #       h(:script, { props:  { innerHTML: @attach_func} }),
    #     ]),
    #   ])
    # end
  end
end
