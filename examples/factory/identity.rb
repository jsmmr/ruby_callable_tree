# frozen_string_literal: true

require_relative '../../lib/callable_tree'
require 'json'
require 'rexml/document'

# Identity example using Factory style with pre-defined procs
# Custom identity for each node - _node_: is used here

# === Behavior Definitions ===

json_matcher = ->(input, **) { File.extname(input) == '.json' }
json_caller = lambda do |input, **options, &block|
  File.open(input) do |file|
    json = JSON.parse(file.read)
    block.call(json, **options)
  end
end
json_identifier = ->(_node_:) { _node_.object_id }

xml_matcher = ->(input, **) { File.extname(input) == '.xml' }
xml_caller = lambda do |input, **options, &block|
  File.open(input) do |file|
    block.call(REXML::Document.new(file), **options)
  end
end
xml_identifier = ->(_node_:) { _node_.object_id }

animals_json_matcher = ->(input, **) { !input['animals'].nil? }
animals_json_caller = ->(input, **) { input['animals'].to_h { |e| [e['name'], e['emoji']] } }
animals_json_identifier = ->(_node_:) { _node_.object_id }

fruits_json_matcher = ->(input, **) { !input['fruits'].nil? }
fruits_json_caller = ->(input, **) { input['fruits'].to_h { |e| [e['name'], e['emoji']] } }
fruits_json_identifier = ->(_node_:) { _node_.object_id }

animals_xml_matcher = ->(input, **) { !input.get_elements('//animals').empty? }
animals_xml_caller = ->(input, **) { input.get_elements('//animals').first.to_h { |e| [e['name'], e['emoji']] } }
animals_xml_identifier = ->(_node_:) { _node_.object_id }

fruits_xml_matcher = ->(input, **) { !input.get_elements('//fruits').empty? }
fruits_xml_caller = ->(input, **) { input.get_elements('//fruits').first.to_h { |e| [e['name'], e['emoji']] } }
fruits_xml_identifier = ->(_node_:) { _node_.object_id }

terminator_true = ->(*) { true }

# === Tree Structure ===

tree = CallableTree::Node::Root.new.seekable.append(
  CallableTree::Node::Internal.create(
    matcher: json_matcher,
    caller: json_caller,
    terminator: terminator_true,
    identifier: json_identifier
  ).seekable.append(
    CallableTree::Node::External.create(
      matcher: animals_json_matcher,
      caller: animals_json_caller,
      identifier: animals_json_identifier
    ).verbosify,
    CallableTree::Node::External.create(
      matcher: fruits_json_matcher,
      caller: fruits_json_caller,
      identifier: fruits_json_identifier
    ).verbosify
  ),
  CallableTree::Node::Internal.create(
    matcher: xml_matcher,
    caller: xml_caller,
    terminator: terminator_true,
    identifier: xml_identifier
  ).seekable.append(
    CallableTree::Node::External.create(
      matcher: animals_xml_matcher,
      caller: animals_xml_caller,
      identifier: animals_xml_identifier
    ).verbosify,
    CallableTree::Node::External.create(
      matcher: fruits_xml_matcher,
      caller: fruits_xml_caller,
      identifier: fruits_xml_identifier
    ).verbosify
  )
)

# === Execution ===

Dir.glob("#{__dir__}/../docs/*") do |file|
  options = { foo: :bar }
  pp tree.call(file, **options)
  puts '---'
end
