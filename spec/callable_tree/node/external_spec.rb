# frozen_string_literal: true

RSpec.describe CallableTree::Node::External do
  describe '.included' do
    subject do
      ::Class
        .new do
          include CallableTree::Node::Internal
          include CallableTree::Node::External
        end
        .new
    end

    it {
      expect { subject }.to raise_error(
        ::CallableTree::Error,
        /.+ cannot include CallableTree::Node::External together with CallableTree::Node::Internal/
      )
    }
  end

  shared_context 'with parent node' do
    let!(:parent_node) do
      CallableTree::Node::Root.new.tap do |root_node|
        root_node.append!(node)
        node.send(:parent=, root_node)
      end
    end
  end

  context 'when node is not proxified' do
    module ExternalSpec
      class Stringifier
        include CallableTree::Node::External

        def call(input, *, **)
          input.to_s
        end
      end
    end

    let(:node) { ExternalSpec::Stringifier.new }

    describe '#parent' do
      subject { node.parent }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.not_to be_nil }
      end

      context 'when node does not have parent' do
        it { is_expected.to be_nil }
      end
    end

    describe '#root?' do
      subject { node.root? }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to be false }
      end

      context 'when node does not have parent' do
        it { is_expected.to be true }
      end
    end

    describe '#ancestors' do
      subject { node.ancestors.to_a }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to eq [node, parent_node] }
      end

      context 'when node does not have parent' do
        it { is_expected.to eq [node] }
      end
    end

    describe '#routes' do
      subject { node.routes }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to eq [ExternalSpec::Stringifier, CallableTree::Node::Root] }
      end

      context 'when node does not have parent' do
        it { is_expected.to eq [ExternalSpec::Stringifier] }
      end
    end

    describe '#depth' do
      subject { node.depth }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to eq 1 }
      end

      context 'when node does not have parent' do
        it { is_expected.to eq 0 }
      end
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
        include_context 'with parent node'
        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    describe '#verbosify!' do
      subject { node.verbosify! }
      it { expect { subject }.to change { node.verbosified? }.from(false).to(true) }
      it { is_expected.to eq node }

      context 'when node has parent' do
        include_context 'with parent node'
        it { expect(subject.root?).to be false }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    describe '#identity' do
      subject { node.identity }
      it { is_expected.to eq ExternalSpec::Stringifier }
    end

    describe '#outline' do
      subject { node.outline }
      it { is_expected.to eq({ ExternalSpec::Stringifier => nil }) }
    end
  end

  context 'when node is proxified' do
    let(:node) { described_class.proxify(->(input, **) { input.to_s }) }

    describe '#parent' do
      subject { node.parent }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.not_to be_nil }
      end

      context 'when node does not have parent' do
        it { is_expected.to be_nil }
      end
    end

    describe '#root?' do
      subject { node.root? }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to be false }
      end

      context 'when node does not have parent' do
        it { is_expected.to be true }
      end
    end

    describe '#ancestors' do
      subject { node.ancestors.to_a }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to eq [node, parent_node] }
      end

      context 'when node does not have parent' do
        it { is_expected.to eq [node] }
      end
    end

    describe '#routes' do
      subject { node.routes }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to eq [Proc, CallableTree::Node::Root] }
      end

      context 'when node does not have parent' do
        it { is_expected.to eq [Proc] }
      end
    end

    describe '#depth' do
      subject { node.depth }

      context 'when node has parent' do
        include_context 'with parent node'
        it { is_expected.to eq 1 }
      end

      context 'when node does not have parent' do
        it { is_expected.to eq 0 }
      end
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
          parent_node = ::Class.new { include CallableTree::Node::Internal }.new
          parent_node.append!(node)
          node.send(:parent=, parent_node)
        end

        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    describe '#verbosify!' do
      subject { node.verbosify! }
      it { expect { subject }.to change { node.verbosified? }.from(false).to(true) }
      it { is_expected.to eq node }

      context 'when node has parent' do
        before do
          parent_node = ::Class.new { include CallableTree::Node::Internal }.new
          parent_node.append!(node)
          node.send(:parent=, parent_node)
        end

        it { expect(subject.root?).to be false }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    describe '#identity' do
      subject { node.identity }
      it { is_expected.to eq Proc }
    end

    describe '#outline' do
      subject { node.outline }
      it { is_expected.to eq({ Proc => nil }) }
    end
  end
end
