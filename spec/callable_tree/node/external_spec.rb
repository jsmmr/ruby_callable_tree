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

  context 'when node is not proxified' do
    let(:node) { ExternalSpec::Stringifier.new }

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

      context 'when node has not been verbosified' do
        let(:verbose) { false }
        it { is_expected.to eq 'input' }
      end

      context 'when node has been verbosified' do
        before { node.verbosify! }
        it 'returns verbose output' do
          expect(subject.value).to eq 'input'
          expect(subject.options).to eq({ foo: :bar })
          expect(subject.routes).to eq [ExternalSpec::Stringifier]
        end
      end
    end

    describe '#proxified?' do
      subject { node.proxified? }
      it { is_expected.to eq false }
    end

    describe '#verbosified?' do
      subject { node.verbosified? }

      context 'when node has not been verbosified' do
        it { is_expected.to be false }
      end

      context 'when node has been verbosified' do
        before { node.verbosify! }
        it { is_expected.to be true }
      end
    end

    describe '#verbosify' do
      subject { node.verbosify }
      it { expect { subject }.not_to change { node.verbosified? } }
      it { is_expected.not_to eq node }
      it { is_expected.to be_verbosified }

      context 'when node has parent' do
        before do
          parent = CallableTree::Node::Root.new
          parent.children << node
          node.send(:parent=, parent)
        end

        it { expect(subject.parent).to be_nil }
      end

      context 'when node does not have parent' do
        it { expect(subject.parent).to be_nil }
      end
    end

    describe '#verbosify!' do
      subject { node.verbosify! }
      it { expect { subject }.to change { node.verbosified? }.from(false).to(true) }
      it { is_expected.to eq node }

      context 'when node has parent' do
        before do
          parent = CallableTree::Node::Root.new
          parent.children << node
          node.send(:parent=, parent)
        end

        it { expect(subject.parent).not_to be_nil }
      end

      context 'when node does not have parent' do
        it { expect(subject.parent).to be_nil }
      end
    end

    describe '#identity' do
      subject { node.identity }
      it { is_expected.to eq ExternalSpec::Stringifier }
    end
  end

  context 'when node is proxified' do
    let(:node) { described_class.proxify(->(input, **options) { input.to_s }) }

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
      it { is_expected.to eq [Proc] }
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

      context 'when node has not been verbosified' do
        let(:verbose) { false }
        it { is_expected.to eq 'input' }
      end

      context 'when node has been verbosified' do
        before { node.verbosify! }
        it 'returns verbose output' do
          expect(subject.value).to eq 'input'
          expect(subject.options).to eq({ foo: :bar })
          expect(subject.routes).to eq [Proc]
        end
      end
    end

    describe '#proxified?' do
      subject { node.proxified? }
      it { is_expected.to eq true }
    end

    describe '#verbosified?' do
      subject { node.verbosified? }

      context 'when node has not been verbosified' do
        it { is_expected.to be false }
      end

      context 'when node has been verbosified' do
        before { node.verbosify! }
        it { is_expected.to be true }
      end
    end

    describe '#verbosify' do
      subject { node.verbosify }
      it { expect { subject }.not_to change { node.verbosified? } }
      it { is_expected.not_to eq node }
      it { is_expected.to be_verbosified }

      context 'when node has parent' do
        before do
          parent = ::Class.new { include CallableTree::Node::Internal }.new
          parent.children << node
          node.send(:parent=, parent)
        end

        it { expect(subject.parent).to be_nil }
      end

      context 'when node does not have parent' do
        it { expect(subject.parent).to be_nil }
      end
    end

    describe '#verbosify!' do
      subject { node.verbosify! }
      it { expect { subject }.to change { node.verbosified? }.from(false).to(true) }
      it { is_expected.to eq node }

      context 'when node has parent' do
        before do
          parent = ::Class.new { include CallableTree::Node::Internal }.new
          parent.children << node
          node.send(:parent=, parent)
        end

        it { expect(subject.parent).not_to be_nil }
      end

      context 'when node does not have parent' do
        it { expect(subject.parent).to be_nil }
      end
    end

    describe '#identity' do
      subject { node.identity }
      it { is_expected.to eq Proc }
    end
  end
end
