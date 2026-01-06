# frozen_string_literal: true

require_relative '../../lib/callable_tree'
# require 'callable_tree'
require 'json'
require 'rexml/document'

module Node
  module JSON
    class Parser
      include CallableTree::Node::Internal

      def match?(input, **_options)
        File.extname(input) == '.json'
      end

      def call(input, **options)
        File.open(input) do |file|
          json = ::JSON.parse(file.read)
          super(json, **options)
        end
      end

      def terminate?(_output, *_inputs, **_options)
        true
      end
    end

    class Scraper
      include CallableTree::Node::External

      def initialize(type:)
        @type = type
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

      def initialize(type:)
        @type = type
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

tree = CallableTree::Node::Root.new.seekable.append(
  Node::JSON::Parser.new.seekable.append(
    Node::JSON::Scraper.new(type: :animals),
    Node::JSON::Scraper.new(type: :fruits)
  ),
  Node::XML::Parser.new.seekable.append(
    Node::XML::Scraper.new(type: :animals),
    Node::XML::Scraper.new(type: :fruits)
  )
)

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
