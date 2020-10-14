# frozen_string_literal: true

require 'execjs'
require 'opal'
require 'spec_helper'

describe Snabberb do
  before :all do
    builder = Opal::Builder.new
    builder.build('opal')
    builder.build('snabberb')
    @js_context = ExecJS.compile(builder.to_s)
  end

  def evaluate(script)
    @js_context.eval(Opal.compile(script).strip.chomp(';'))
  end

  def elements_to_html(elements)
    script = <<-RUBY
      class Child < Snabberb::Component
        needs :value

        def render
          h(:div, "child with value \#{@value}")
        end
      end

      class Parent < Snabberb::Component
        def render
          #{elements}
        end
      end

      Parent.html
    RUBY

    evaluate(script)
  end

  it 'has a version number' do
    expect(Snabberb::VERSION).not_to be nil
  end

  describe '.prerender' do
    it 'generates the correct prerender script' do
      script = Snabberb.prerender_script(
        'layout',
        'app',
        'app_id',
        need: 'hello',
        array_need: [1, { x: 1, z: nil }],
        hash_need: { x: 1, y: [1], z: { a: 1 } },
      )

      # couldn't get the matchers to work
      # rubocop:disable Layout/LineLength
      expect(script.include?('Opal.$$.app.$attach(\"app_id\", Opal.hash(\"need\",\"hello\",\"array_need\",[1,Opal.hash(\"x\",1,\"z\",Opal.nil)],\"hash_need\",Opal.hash(\"x\",1,\"y\",[1],\"z\",Opal.hash(\"a\",1))))')).to be_truthy
      expect(script.include?('Opal.$$.layout.$html(Opal.hash({')).to be_truthy
      expect(script.include?('application: Opal.$$.app.$new(null, Opal.hash("need","hello","array_need",[1,Opal.hash("x",1,"z",Opal.nil)],"hash_need",Opal.hash("x",1,"y",[1],"z",Opal.hash("a",1)))).$render(),')).to be_truthy
      expect(script.include?("javascript_include_tags: '',")).to be_truthy
      expect(script.include?('')).to be_truthy
      # rubocop:enable Layout/LineLength
    end
  end

  describe '.html' do
    it 'renders a div' do
      html = elements_to_html(
        <<-RUBY
          h(:div, { style: { width: '100px' } }, 'Hello World')
        RUBY
      )

      expect(html).to eq('<div style="width: 100px">Hello World</div>')
    end

    it 'renders children' do
      html = elements_to_html(
        <<-RUBY
          h(:div, { style: { width: '100px' } }, [
            h(:div, { class: { active: true } }),
            h(:span, { style: { width: '100px' } }),
          ])
        RUBY
      )

      expect(html).to eq('<div style="width: 100px"><div class="active"></div><span style="width: 100px"></span></div>')
    end

    it 'renders components' do
      html = elements_to_html(
        <<-RUBY
          h(:div, [
            h(:span, 'a span'),
            h(Child, value: 2),
          ])
        RUBY
      )

      expect(html).to eq('<div><span>a span</span><div>child with value 2</div></div>')
    end

    it 'renders classes' do
      html = elements_to_html(
        <<-RUBY
          h('div.a.b.c', { class: { active: true, selected: false, b: true, c: false } }, 'foo')
        RUBY
      )

      expect(html).to eq('<div class="a b active">foo</div>')
    end

    it 'renders props' do
      html = elements_to_html(
        <<-RUBY
          h('div', { props: { href: '/', a: 1, checked: true, disabled: false } }, 'foo')
        RUBY
      )

      expect(html).to eq('<div href="/" a="1" checked="checked">foo</div>')
    end

    it 'renders attributes' do
      html = elements_to_html(
        <<-RUBY
          h('div#id', { attrs: { id: 'c', href: '/'} }, 'foo')
        RUBY
      )

      expect(html).to eq('<div id="c" href="/">foo</div>')
    end

    it 'renders dataset' do
      html = elements_to_html(
        <<-RUBY
          h('div', { dataset: { x: 'blue' } })
        RUBY
      )

      expect(html).to eq('<div data-x="blue"></div>')
    end

    it 'renders text' do
      expect(elements_to_html("h('div', 'hello')")).to eq('<div>hello</div>')
      expect(elements_to_html("h('div', 1)")).to eq('<div>1</div>')
      expect(elements_to_html("h('div')")).to eq('<div></div>')
      expect(elements_to_html("h('br')")).to eq('<br>')
    end

    it 'renders innerHTML' do
      expect(elements_to_html("h('div', props: { innerHTML: '<div></div>' } )")).to eq('<div><div></div></div>')
    end

    it 'escapes text' do
      html = elements_to_html("h('div.<', '>')")
      expect(html).to eq('<div class="&lt;">&gt;</div>')

      html = elements_to_html("h('div#<', '')")
      expect(html).to eq('<div id="&lt;"></div>')

      html = elements_to_html("h('div', { props: { '<': '>' } })")
      expect(html).to eq('<div &lt;="&gt;"></div>')

      html = elements_to_html("h('div', { attrs: { '<': '>' } })")
      expect(html).to eq('<div &lt;="&gt;"></div>')

      html = elements_to_html("h('div', { style: { '<': '>' } })")
      expect(html).to eq('<div style="&lt;: &gt;"></div>')

      html = elements_to_html("h('div', { dataset: { '<': '>' } })")
      expect(html).to eq('<div data-&lt;="&gt;"></div>')
    end

    it 'renders styles' do
      html = elements_to_html(
        <<-RUBY
          h('div', { style: { backgroundColor: 'blue', 'top-margin' => 1.1 } })
        RUBY
      )

      expect(html).to eq('<div style="background-color: blue; top-margin: 1.1"></div>')
    end

    it 'renders hyperscript' do
      expect(elements_to_html("h('div.a')")).to eq('<div class="a"></div>')
      expect(elements_to_html("h('div#id')")).to eq('<div id="id"></div>')
      expect(elements_to_html("h('div.a#id')")).to eq('<div id="id" class="a"></div>')
      expect(elements_to_html("h('div.a.b#id')")).to eq('<div id="id" class="a b"></div>')
    end

    it 'renders a file' do
      script = Snabberb.html_script('spec/test_component.rb', groceries: { 'apple': 1, 'sausage': 2 })
      expect(@js_context.eval(script)).to eq(
        '<div style="width: 100%"><div>apple - 1</div><div>sausage - 2</div></div>'
      )
    end
  end
end
