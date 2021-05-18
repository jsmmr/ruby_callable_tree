require 'callable_tree'
require 'json'
require 'rexml/document'

module Node
  module Logging
    INDENT_SIZE = 2
    BLANK = ' '.freeze

    module Match
      LIST_STYLE = '*'.freeze

      def match?(_input, **)
        super.tap do |matched|
          prefix = LIST_STYLE.rjust(self.depth * INDENT_SIZE - INDENT_SIZE + LIST_STYLE.length, BLANK)
          puts "#{prefix} #{self.identity}: [matched: #{matched}]"
        end
      end
    end

    module Call
      INPUT_LABEL  = 'Input :'.freeze
      OUTPUT_LABEL = 'Output:'.freeze

      def call(input, **)
        super.tap do |output|
          input_prefix = INPUT_LABEL.rjust(self.depth * INDENT_SIZE + INPUT_LABEL.length, BLANK)
          puts "#{input_prefix} #{input}"
          output_prefix = OUTPUT_LABEL.rjust(self.depth * INDENT_SIZE + OUTPUT_LABEL.length, BLANK)
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

      def match?(input, **options)
        File.extname(input) == '.json'
      end

      def call(input, **options)
        File.open(input) do |file|
          json = ::JSON.load(file)
          super(json, **options)
        end
      end

      def terminate?(_output, **)
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

      def match?(input, **options)
        !!input[@type.to_s]
      end

      def call(input, **options)
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

      def match?(input, **options)
        File.extname(input) == '.xml'
      end

      def call(input, **options)
        File.open(input) do |file|
          super(REXML::Document.new(file), **options)
        end
      end

      def terminate?(_output, **)
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

      def match?(input, **options)
        !input.get_elements("//#{@type}").empty?
      end

      def call(input, **options)
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

Dir.glob(__dir__ + '/docs/*') do |file|
  options = { foo: :bar }
  puts tree.call(file, **options)
  puts '---'
end
