# frozen_string_literal: true

RSpec.describe CallableTree::Node::Hooks::Call do
  module HooksCallSpec
    class Reverser
      include CallableTree::Node::External
      prepend CallableTree::Node::Hooks::Call

      def call(input, a, b, x:, y:)
        "#{a}#{x}#{input}#{y}#{b}".reverse
      end
    end
  end

  describe '#before_call' do
    subject { node.call(*inputs, **options) }

    let(:node) do
      HooksCallSpec::Reverser
        .new
        .before_call { |input, *, x:, y:, **| "#{x}#{input}#{y}" }
        .before_call { |input, a, b, *, **| "#{a}#{input}#{b}" }
    end

    let(:inputs) { %w[foobar ( )] }
    let(:options) { { x: '[', y: ']' } }

    it { is_expected.to eq ')])]raboof[([(' }
  end

  describe '#before_call!' do
    subject { node.call(*inputs, **options) }

    let(:node) { HooksCallSpec::Reverser.new }

    before do
      node
        .before_call! { |input, *, x:, y:, **| "#{x}#{input}#{y}" }
        .before_call! { |input, a, b, *, **| "#{a}#{input}#{b}" }
    end

    let(:inputs) { %w[foobar ( )] }
    let(:options) { { x: '[', y: ']' } }

    it { is_expected.to eq ')])]raboof[([(' }
    it { expect { subject }.not_to change { node.object_id } }
  end

  describe '#around_call' do
    subject { node.call(*inputs, **options) }

    let(:node) do
      HooksCallSpec::Reverser
        .new
        .around_call do |*, x:, y:, &block|
          output = block.call
          "#{x}#{output}#{y}"
        end
        .around_call do |input, a, b, *, **, &block|
          output = block.call
          "#{a}#{input}#{b} -> #{a}#{output}#{b}"
        end
    end

    let(:inputs) { %w[foobar ( )] }
    let(:options) { { x: '[', y: ']' } }

    it { is_expected.to eq '(foobar) -> ([)]raboof[(])' }
  end

  describe '#around_call!' do
    subject { node.call(*inputs, **options) }

    let(:node) { HooksCallSpec::Reverser.new }

    before do
      node
        .around_call! do |*, x:, y:, &block|
          output = block.call
          "#{x}#{output}#{y}"
        end
        .around_call! do |input, a, b, *, **, &block|
          output = block.call
          "#{a}#{input}#{b} -> #{a}#{output}#{b}"
        end
    end

    let(:inputs) { %w[foobar ( )] }
    let(:options) { { x: '[', y: ']' } }

    it { is_expected.to eq '(foobar) -> ([)]raboof[(])' }
    it { expect { subject }.not_to change { node.object_id } }
  end

  describe '#after_call' do
    subject { node.call(*inputs, **options) }

    let(:node) do
      HooksCallSpec::Reverser
        .new
        .after_call { |output, *, x:, y:| "#{x}#{output}#{y}" }
        .after_call { |output, *, x:, y:| "#{x}#{output}#{y}" }
    end

    let(:inputs) { %w[foobar ( )] }
    let(:options) { { x: '[', y: ']' } }

    it { is_expected.to eq '[[)]raboof[(]]' }
  end

  describe '#after_call!' do
    subject { node.call(*inputs, **options) }

    let(:node) { HooksCallSpec::Reverser.new }

    before do
      node
        .after_call! { |output, *, x:, y:| "#{x}#{output}#{y}" }
        .after_call! { |output, *, x:, y:| "#{x}#{output}#{y}" }
    end

    let(:inputs) { %w[foobar ( )] }
    let(:options) { { x: '[', y: ']' } }

    it { is_expected.to eq '[[)]raboof[(]]' }
    it { expect { subject }.not_to change { node.object_id } }
  end

  describe '#clone' do
    subject { node.clone }

    let(:before_callback) { proc { |input, *, **| input } }
    let(:around_callback) { proc { |_input, *, **, &block| block.call } }
    let(:after_callback) { proc { |output, **| output } }

    let(:node) do
      HooksCallSpec::Reverser
        .new
        .before_call(&:before_callback)
        .around_call(&:around_callback)
        .after_call(&:after_callback)
    end

    it 'should generate new array' do
      expect(subject.before_callbacks).not_to be node.before_callbacks
      expect(subject.around_callbacks).not_to be node.around_callbacks
      expect(subject.after_callbacks).not_to be node.after_callbacks
    end
  end
end
