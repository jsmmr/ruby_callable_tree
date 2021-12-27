# frozen_string_literal: true

require 'callable_tree'
require 'json'
require 'rexml/document'

module Node
  module Logging
    INDENT_SIZE = 2
    BLANK = ' '

    module Match
      LIST_STYLE = '*'

      def match?(_input, **_options)
        super.tap do |matched|
          prefix = LIST_STYLE.rjust(depth * INDENT_SIZE - INDENT_SIZE + LIST_STYLE.length, BLANK)
          puts "#{prefix} #{identity}: [matched: #{matched}]"
        end
      end
    end

    module Call
      INPUT_LABEL  = 'Input :'
      OUTPUT_LABEL = 'Output:'

      def call(input, **_options)
        super.tap do |output|
          input_prefix = INPUT_LABEL.rjust(depth * INDENT_SIZE + INPUT_LABEL.length, BLANK)
          puts "#{input_prefix} #{input}"
          output_prefix = OUTPUT_LABEL.rjust(depth * INDENT_SIZE + OUTPUT_LABEL.length, BLANK)
          puts "#{output_prefix} #{output}"
        end
      end
    end
  end

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
      prepend Logging::Match

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
      prepend Logging::Match
      prepend Logging::Call

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
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
    end
  end

  module XML
    class Parser
      include CallableTree::Node::Internal
      prepend Logging::Match

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
      prepend Logging::Match
      prepend Logging::Call

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
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
    end
  end
end

tree = CallableTree::Node::Root.new.append(
  Node::JSON::Parser.new.append(
    Node::JSON::Scraper.new(type: :animals).verbosify,
    Node::JSON::Scraper.new(type: :fruits).verbosify
  ),
  Node::XML::Parser.new.append(
    Node::XML::Scraper.new(type: :animals).verbosify,
    Node::XML::Scraper.new(type: :fruits).verbosify
  )
)

Dir.glob("#{__dir__}/docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
