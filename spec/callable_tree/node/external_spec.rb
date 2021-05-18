# frozen_string_literal: true

RSpec.describe CallableTree::Node::External do
  module ExternalSpec
    class Stringifier
      include CallableTree::Node::External

      def call(input, **)
        input.to_s
      end
    end
  end

  let(:node) { ExternalSpec::Stringifier.new }
  let(:verbose) { [true, false].sample }

  before do
    node.verbosify if verbose
  end

  describe '.new' do
    subject { node }
    it { is_expected.to be_a ::CallableTree::Node::External }
  end

  describe '#parent' do
    subject { node.parent }
    it { is_expected.to be_nil }
  end

  describe '#ancestors' do
    subject { node.ancestors.to_a }
    it { is_expected.to eq [node] }
  end

  describe '#routes' do
    subject { node.routes }
    it { is_expected.to eq [ExternalSpec::Stringifier] }
  end

  describe '#depth' do
    subject { node.depth }
    it { is_expected.to eq 0 }
  end

  describe '#match?' do
    subject { node.match? }
    it { is_expected.to eq true }
  end

  describe '#terminate?' do
    subject { node.terminate?(output) }

    context 'when return value of call method is nil' do
      let(:output) { nil }
      it { is_expected.to eq false }
    end

    context 'when return value of call method is not nil' do
      let(:output) { 'output' }
      it { is_expected.to eq true }
    end
  end

  describe '#call' do
    subject { node.call(input, **options) }

    let(:input) { :input }
    let(:options) { { foo: :bar } }

    context 'when verbose: false' do
      let(:verbose) { false }
      it { is_expected.to eq 'input' }
    end

    context 'when verbose: true' do
      let(:verbose) { true }
      it 'returns verbose output' do
        expect(subject.value).to eq 'input'
        expect(subject.options).to eq({ foo: :bar })
        expect(subject.routes).to eq [ExternalSpec::Stringifier]
      end
    end
  end
end
