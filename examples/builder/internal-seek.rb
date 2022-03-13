# frozen_string_literal: true

require 'callable_tree'
require 'json'
require 'rexml/document'

module JSONParser
  def self.build
    CallableTree::Node::Internal::Builder
      .new
      .matcher do |input, **_options|
        File.extname(input) == '.json'
      end
      .caller do |input, **options, &block|
        File.open(input) do |file|
          json = ::JSON.load(file)
          # The following block call is equivalent to calling `super` in the class style.
          block.call(json, **options)
        end
      end
      .terminater do
        true
      end
      .build
  end
end

module XMLParser
  def self.build
    CallableTree::Node::Internal::Builder
      .new
      .matcher do |input, **_options|
        File.extname(input) == '.xml'
      end
      .caller do |input, **options, &block|
        File.open(input) do |file|
          # The following block call is equivalent to calling `super` in the class style.
          block.call(REXML::Document.new(file), **options)
        end
      end
      .terminater do
        true
      end
      .build
  end
end

module JSONScraper
  def self.build(type)
    CallableTree::Node::External::Builder
      .new
      .matcher do |input, **_options|
        !!input[type.to_s]
      end
      .caller do |input, **_options|
        input[type.to_s]
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
      .build
  end
end

module XMLScraper
  def self.build(type)
    CallableTree::Node::External::Builder
      .new
      .matcher do |input, **_options|
        !input.get_elements("//#{type}").empty?
      end
      .caller do |input, **_options|
        input
          .get_elements("//#{type}")
          .first
          .map { |element| [element['name'], element['emoji']] }
          .to_h
      end
      .build
  end
end

tree = CallableTree::Node::Root.new.append(
  JSONParser.build.new.append(
    JSONScraper.build(:animals).new,
    JSONScraper.build(:fruits).new
  ),
  XMLParser.build.new.append(
    XMLScraper.build(:animals).new,
    XMLScraper.build(:fruits).new
  )
)

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
