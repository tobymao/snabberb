# frozen_string_literal: true

module Snabberb
  class Component
    attr_accessor :node
    attr_reader :root

    VOID = %i[
      area base br col embed hr img input keygen
      link meta param source track wbr
    ].map { |elm| [elm, true] }.to_h

    IGNORE = %i[
      attributes childElementCount children classList clientHeight clientLeft
      clientTop clientWidth currentStyle firstElementChild innerHTML lastElementChild
      nextElementSibling ongotpointercapture onlostpointercapture onwheel outerHTML
      previousElementSibling runtimeStyle scrollHeight scrollLeft scrollLeftMax scrollTop
      scrollTopMax scrollWidth tabStop tagName
    ].map { |elm| [elm, true] }.to_h

    BOOLEAN = %i[
      disabled visible checked readonly required allowfullscreen autofocus
      autoplay compact controls default formnovalidate hidden ismap itemscope
      loop multiple muted noresize noshade novalidate nowrap open reversed
      seamless selected sortable truespeed typemustmatch
    ].map { |elm| [elm, true] }.to_h

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
      component.update
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
      node_to_s(Native(render))
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

      @@patcher ||= %x{snabbdom.init([
        snabbdom.attributesModule,
        snabbdom.classModule,
        snabbdom.eventListenersModule,
        snabbdom.propsModule,
        snabbdom.styleModule,
      ])}
      node = @root.render
      @@patcher.call(@root.node, node)
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

    def parse_sel(sel)
      tag = nil
      id = nil
      classes = {}
      parts = (sel || '').split('.')
      last = parts.size - 1

      parts.each_with_index do |part, index|
        if index == last
          part, id = part.split('#')
          index.zero? ? tag = part : classes[part] = true
        elsif !tag
          tag = part
        else
          classes[part] = true
        end
      end

      {
        tag: tag.empty? ? 'div' : tag,
        id: id || '',
        classes: classes,
      }
    end

    def node_to_s(vnode)
      return vnode.text if !vnode.sel && vnode.text.is_a?(String)

      sel = parse_sel(vnode.sel)

      vnode.data[:class]&.each do |key, value|
        value ? sel[:classes][key] = true : sel[:classes].delete(key)
      end

      attributes = {
        id: sel[:id],
        class: sel[:classes].keys.join(' '),
      }.reject { |_, v| v.empty? }

      vnode.data[:attrs]&.each do |key, value|
        attributes[key] = escape(value)
      end

      vnode.data[:dataset]&.each do |key, value|
        attributes["data-#{key}"] = escape(value)
      end

      vnode.data[:props]&.each do |key, value|
        next if IGNORE[key]

        if BOOLEAN[key]
          attributes[key] = key if value
        else
          attributes[key] = escape(value)
        end
      end

      # styles is an object and doesn't respond to map
      styles = []
      vnode.data[:style]&.each do |key, value|
        key = `key.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase()` # rubocop:disable Lint/ShadowedArgument
        styles << "#{key}: #{escape(value)}"
      end
      attributes[:style] = styles.join(';') unless styles.empty?

      attributes = attributes.map do |key, value|
        "#{key}=\"#{value}\""
      end.join(' ')

      tag = sel[:tag]
      elements = []
      elements << "<#{tag}"
      elements << ' ' + attributes unless attributes.empty?
      elements << '>'

      unless VOID[tag]
        if (html = vnode.data.props&.innerHTML)
          elements << html
        elsif (text = vnode.text)
          elements << escape(text)
        elsif (children = vnode.children)
          children.each do |child|
            elements << node_to_s(child)
          end
        end

        elements << "</#{tag}>"
      end

      elements.join
    end

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
