# frozen_string_literal: true

require 'callable_tree'
require 'json'
require 'rexml/document'

module Node
  class Identity
    attr_reader :klass, :type

    def initialize(klass:, type:)
      @klass = klass
      @type = type
    end

    def to_s
      "#{klass}(#{type})"
    end
  end

  module JSON
    class Parser
      include CallableTree::Node::Internal
      prepend CallableTree::Node::Hooks::Matcher

      def match?(input, **_options)
        File.extname(input) == '.json'
      end

      def call(input, **options)
        File.open(input) do |file|
          json = ::JSON.load(file)
          super(json, **options)
        end
      end

      def terminate?(_output, *_inputs, **_options)
        true
      end
    end

    class Scraper
      include CallableTree::Node::External
      prepend CallableTree::Node::Hooks::Matcher
      prepend CallableTree::Node::Hooks::Caller

      def initialize(type:)
        @type = type
      end

      def identity
        Identity.new(klass: super, type: @type)
      end

      def match?(input, **_options)
        !!input[@type.to_s]
      end

      def call(input, **_options)
        input[@type.to_s]
          .to_h { |element| [element['name'], element['emoji']] }
      end
    end
  end

  module XML
    class Parser
      include CallableTree::Node::Internal
      prepend CallableTree::Node::Hooks::Matcher

      def match?(input, **_options)
        File.extname(input) == '.xml'
      end

      def call(input, **options)
        File.open(input) do |file|
          super(REXML::Document.new(file), **options)
        end
      end

      def terminate?(_output, *_inputs, **_options)
        true
      end
    end

    class Scraper
      include CallableTree::Node::External
      prepend CallableTree::Node::Hooks::Matcher
      prepend CallableTree::Node::Hooks::Caller

      def initialize(type:)
        @type = type
      end

      def identity
        Identity.new(klass: super, type: @type)
      end

      def match?(input, **_options)
        !input.get_elements("//#{@type}").empty?
      end

      def call(input, **_options)
        input
          .get_elements("//#{@type}")
          .first
          .to_h { |element| [element['name'], element['emoji']] }
      end
    end
  end
end

module Logging
  INDENT_SIZE = 2
  BLANK = ' '
  LIST_STYLE = '*'
  INPUT_LABEL  = 'Input :'
  OUTPUT_LABEL = 'Output:'

  def self.loggable(node)
    node.after_matcher! do |matched, _node_:, **|
      prefix = LIST_STYLE.rjust((_node_.depth * INDENT_SIZE) - INDENT_SIZE + LIST_STYLE.length, BLANK)
      puts "#{prefix} #{_node_.identity}: [matched: #{matched}]"
      matched
    end

    if node.external?
      node
        .before_caller! do |input, *, _node_:, **|
          input_prefix = INPUT_LABEL.rjust((_node_.depth * INDENT_SIZE) + INPUT_LABEL.length, BLANK)
          puts "#{input_prefix} #{input}"
          input
        end
        .after_caller! do |output, _node_:, **|
          output_prefix = OUTPUT_LABEL.rjust((_node_.depth * INDENT_SIZE) + OUTPUT_LABEL.length, BLANK)
          puts "#{output_prefix} #{output}"
          output
        end
    end
  end
end

loggable = Logging.method(:loggable)

tree = CallableTree::Node::Root.new.append(
  Node::JSON::Parser.new.tap(&loggable).append(
    Node::JSON::Scraper.new(type: :animals).tap(&loggable).verbosify,
    Node::JSON::Scraper.new(type: :fruits).tap(&loggable).verbosify
  ),
  Node::XML::Parser.new.tap(&loggable).append(
    Node::XML::Scraper.new(type: :animals).tap(&loggable).verbosify,
    Node::XML::Scraper.new(type: :fruits).tap(&loggable).verbosify
  )
)

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
