# frozen_string_literal: true

require 'callable_tree'
require 'json'
require 'rexml/document'

JSONParser =
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
  .terminator do
    true
  end
  .build

XMLParser =
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
  .terminator do
    true
  end
  .build

def build_json_scraper(type)
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

AnimalsJSONScraper = build_json_scraper(:animals)
FruitsJSONScraper = build_json_scraper(:fruits)

def build_xml_scraper(type)
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

AnimalsXMLScraper = build_xml_scraper(:animals)
FruitsXMLScraper = build_xml_scraper(:fruits)

tree = CallableTree::Node::Root.new.seekable.append(
  JSONParser.new.seekable.append(
    AnimalsJSONScraper.new,
    FruitsJSONScraper.new
  ),
  XMLParser.new.seekable.append(
    AnimalsXMLScraper.new,
    FruitsXMLScraper.new
  )
)

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
