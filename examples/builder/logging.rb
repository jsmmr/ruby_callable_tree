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
  .hookable
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
  .hookable
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
    .hookable
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
    .hookable
    .build
end

AnimalsXMLScraper = build_xml_scraper(:animals)
FruitsXMLScraper = build_xml_scraper(:fruits)

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

tree = CallableTree::Node::Root.new.seekable.append(
  JSONParser.new.tap(&loggable).seekable.append(
    AnimalsJSONScraper.new.tap(&loggable).verbosify,
    FruitsJSONScraper.new.tap(&loggable).verbosify
  ),
  XMLParser.new.tap(&loggable).seekable.append(
    AnimalsXMLScraper.new.tap(&loggable).verbosify,
    FruitsXMLScraper.new.tap(&loggable).verbosify
  )
)

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
