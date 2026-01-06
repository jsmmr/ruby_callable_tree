# frozen_string_literal: true

require_relative '../../lib/callable_tree'
# require 'callable_tree'
require 'json'
require 'rexml/document'

# Logging example using Factory style with pre-defined procs
# Uses hooks to add logging to the tree - _node_: is used in hooks

# === Behavior Definitions ===

json_matcher = ->(input, **) { File.extname(input) == '.json' }
json_caller = lambda do |input, **options, &original|
  File.open(input) do |file|
    json = JSON.parse(file.read)
    original.call(json, **options)
  end
end

xml_matcher = ->(input, **) { File.extname(input) == '.xml' }
xml_caller = lambda do |input, **options, &original|
  File.open(input) do |file|
    original.call(REXML::Document.new(file), **options)
  end
end

animals_json_matcher = ->(input, **) { !input['animals'].nil? }
animals_json_caller = ->(input, **) { input['animals'].to_h { |e| [e['name'], e['emoji']] } }

fruits_json_matcher = ->(input, **) { !input['fruits'].nil? }
fruits_json_caller = ->(input, **) { input['fruits'].to_h { |e| [e['name'], e['emoji']] } }

animals_xml_matcher = ->(input, **) { !input.get_elements('//animals').empty? }
animals_xml_caller = ->(input, **) { input.get_elements('//animals').first.to_h { |e| [e['name'], e['emoji']] } }

fruits_xml_matcher = ->(input, **) { !input.get_elements('//fruits').empty? }
fruits_xml_caller = ->(input, **) { input.get_elements('//fruits').first.to_h { |e| [e['name'], e['emoji']] } }

terminator_true = ->(*) { true }

# === Logging Module (uses _node_:) ===

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

    return unless node.external?

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

loggable = Logging.method(:loggable)

# === Tree Structure ===

tree = CallableTree::Node::Root.new.seekable.append(
  CallableTree::Node::Internal.create(
    matcher: json_matcher,
    caller: json_caller,
    terminator: terminator_true,
    hookable: true
  ).tap(&loggable).seekable.append(
    CallableTree::Node::External.create(
      matcher: animals_json_matcher,
      caller: animals_json_caller,
      hookable: true
    ).tap(&loggable).verbosify,
    CallableTree::Node::External.create(
      matcher: fruits_json_matcher,
      caller: fruits_json_caller,
      hookable: true
    ).tap(&loggable).verbosify
  ),
  CallableTree::Node::Internal.create(
    matcher: xml_matcher,
    caller: xml_caller,
    terminator: terminator_true,
    hookable: true
  ).tap(&loggable).seekable.append(
    CallableTree::Node::External.create(
      matcher: animals_xml_matcher,
      caller: animals_xml_caller,
      hookable: true
    ).tap(&loggable).verbosify,
    CallableTree::Node::External.create(
      matcher: fruits_xml_matcher,
      caller: fruits_xml_caller,
      hookable: true
    ).tap(&loggable).verbosify
  )
)

# === Execution ===

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
