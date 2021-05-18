# frozen_string_literal: true

RSpec.describe CallableTree::Node::Hooks::Call do
  module HooksCallSpec
    class Reverser
      include CallableTree::Node::External
      prepend CallableTree::Node::Hooks::Call

      def call(input, **)
        input.reverse
      end
    end
  end

  let(:node) { HooksCallSpec::Reverser.new }

  describe '#before_call' do
    subject { node.call(input, **options) }

    let(:input) { 'abc' }
    let(:options) { { foo: '*', bar: '!' } }

    before do
      node
        .before_call { |input, foo:, bar:| input.ljust(5, foo) }
        .before_call { |input, foo:, bar:| input.ljust(7, bar) }
    end

    it { is_expected.to eq '!!**cba' }
  end

  describe '#around_call' do
    subject { node.call(input, **options) }

    let(:input) { 'abc' }
    let(:options) { { foo: '*', bar: '!' } }

    before do
      node
        .around_call do |_input, foo:, bar:, &block|
          output = block.call
          "#{foo}: #{output}"
        end
        .around_call do |input, foo:, bar:, &block|
          output = block.call
          "#{bar}: #{input}, #{output}"
        end
    end

    it { is_expected.to eq '!: abc, *: cba' }
  end

  describe '#after_call' do
    subject { node.call(input, **options) }

    let(:input) { 'abc' }
    let(:options) { { foo: '*', bar: '!' } }

    before do
      node
        .after_call { |output, foo:, bar:| output.ljust(5, foo) }
        .after_call { |output, foo:, bar:| output.ljust(7, bar) }
    end

    it { is_expected.to eq 'cba**!!' }
  end

  describe '#clone' do
    subject { node.clone }

    let(:before_callback) { proc { |input, **| input } }
    let(:around_callback) { proc { |_input, **, &block| block.call } }
    let(:after_callback) { proc { |output, **| output } }

    before do
      node
        .before_call(&:before_callback)
        .around_call(&:around_callback)
        .after_call(&:after_callback)
    end

    it 'should generate new array' do
      expect(subject.before_callbacks.object_id).not_to eq node.before_callbacks.object_id
      expect(subject.around_callbacks.object_id).not_to eq node.around_callbacks.object_id
      expect(subject.after_callbacks.object_id).not_to eq node.after_callbacks.object_id
    end
  end
end
