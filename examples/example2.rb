require 'callable_tree'
require 'json'
require 'rexml/document'

module Node
  module JSON
    class Parser
      include CallableTree::Node::Internal

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

      def initialize(type:)
        @type = type
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

      def initialize(type:)
        @type = type
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
  pp tree.call(file, **options)
  puts '---'
end
