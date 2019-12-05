# frozen_string_literal: true

module Snabberb
  class Component
    attr_accessor :node
    attr_reader :root

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
      @class_needs ||= {}
      @class_needs[key] = opts
    end

    def self.class_needs
      @class_needs || {}
    end

    # Attach the root component to a dom element by container id.
    def self.attach(container, **passed_needs)
      component = new(nil, passed_needs)
      component.node = `document.getElementById(#{container})`
      component.update
    end

    # You should not call initialize manually.
    def initialize(root, needs)
      @root = root || self
      @store = root? ? {} : @root.store

      unused = needs.keys - self.class.class_needs.keys
      raise "Unused needs passed to component: #{unused}." unless unused.empty?

      init_needs(needs)
    end

    def root?
      self == @root
    end

    def render
      raise NotImplementedError
    end

    # Building block for dom elements using Snabbdom h.
    #
    # Props are not required and children can be passed as the second argument.
    #
    # For eaxmple:
    #   h(:div, 'Hello world')
    #   h(:div, { style: { width: '100%' }, 'Hello World!')
    #   h(:div, [h(:div), h(:div)])
    def h(tag, props = {}, children = nil)
      props_is_hash = props.is_a?(Hash)
      children = props if !children && !props_is_hash
      props = {} unless props_is_hash
      `snabbdom.h(#{tag}, #{Native.convert(props)}, #{children})`
    end

    # Used to instantiate nested components.
    def c(component, props = {})
      component = component.new(@root, **props) if component.is_a?(Class)
      component.render
    end

    def update
      `window.requestAnimationFrame(function(timestamp) {#{update!}})`
    end

    def update!
      @@patcher ||= %x{snabbdom.init([
        snabbdom_attributes.default,
        snabbdom_class.default,
        snabbdom_eventlisteners.default,
        snabbdom_props.default,
        snabbdom_style.default,
      ])}
      node = @root.render
      @@patcher.call(@root.node, node)
      @root.node = node
    end

    def store(key = nil)
      key.nil? ? @store : @store[key]
    end

    def set_store(key, value)
      @store[key] = value
      update
    end

    private

    def init_needs(needs)
      self.class.class_needs.each do |key, opts|
        if needs.key?(key)
          instance_variable_set("@#{key}", needs[key])
        elsif opts&.key?(:default)
          instance_variable_set("@#{key}", opts[:default])
        else
          raise "Needs '#{key}' required but not provided."
        end

        @store[key] ||= needs[key] if opts[:store]
      end
    end
  end
end
