# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal do
  module InternalSpec
    class AMatcher
      include CallableTree::Node::Internal

      def call(input, **options)
        super(input.to_s, **options)
      end
    end

    class BMatcher
      include CallableTree::Node::Internal

      def call(input, **options)
        super(input.to_s, **options)
      end
    end
  end

  describe '#append' do
    subject { node.append(*child_nodes) }

    let(:node) { InternalSpec::AMatcher.new }
    let(:child_nodes) { [InternalSpec::BMatcher.new.append!(->(input) { input })] }

    it { is_expected.not_to eq node }
    it { expect { subject }.not_to change { node.children.size } }

    it 'should generate new child nodes' do
      expect(subject.children[0].object_id).not_to eq child_nodes[0].object_id
      expect(subject.children[0].children[0].object_id).not_to eq child_nodes[0].children[0].object_id
    end
  end

  describe '#append!' do
    subject { node.append!(*child_nodes) }

    let(:node) { InternalSpec::AMatcher.new }
    let(:child_nodes) { [InternalSpec::BMatcher.new.append!(->(input) { input })] }

    it { is_expected.to eq node }
    it { expect { subject }.to change { node.children.size }.by(1) }

    it 'should generate new child nodes' do
      subject
      expect(node.children[0].object_id).not_to eq child_nodes[0].object_id
      expect(node.children[0].children[0].object_id).not_to eq child_nodes[0].children[0].object_id
    end
  end

  describe '#reject' do
    subject { node.reject(&block) }

    let(:node) { CallableTree::Node::Root.new.append(a_node, b_node) }
    let(:a_node) { InternalSpec::AMatcher.new }
    let(:b_node) { InternalSpec::BMatcher.new }

    context 'when AMatcher is rejected' do
      let(:block) do
        proc { |node| node.is_a?(InternalSpec::AMatcher) }
      end

      it 'returns a new node instance without rejected child nodes' do
        expect { subject }.not_to change { node.children.size }
        expect(subject).not_to eq node
        expect(subject.children.map(&:class)).to eq [InternalSpec::BMatcher]
      end
    end

    context 'when BMatcher is rejected' do
      let(:block) do
        proc { |node| node.is_a?(InternalSpec::BMatcher) }
      end

      it 'returns new node instance without rejected child nodes' do
        expect { subject }.not_to change { node.children.size }
        expect(subject).not_to eq node
        expect(subject.children.map(&:class)).to eq [InternalSpec::AMatcher]
      end
    end
  end

  describe '#reject!' do
    subject { node.reject!(&block) }

    let(:node) { CallableTree::Node::Root.new.append(a_node, b_node) }
    let(:a_node) { InternalSpec::AMatcher.new }
    let(:b_node) { InternalSpec::BMatcher.new }

    context 'when AMatcher is rejected' do
      let(:block) do
        proc { |node| node.is_a?(InternalSpec::AMatcher) }
      end

      it 'rejects child nodes from self and returns self' do
        expect { subject }.to change { node.children.size }.by(-1)
        expect(subject).to eq node
        expect(subject.children.map(&:class)).to eq [InternalSpec::BMatcher]
      end
    end

    context 'when BMatcher is rejected' do
      let(:block) do
        proc { |node| node.is_a?(InternalSpec::BMatcher) }
      end

      it 'rejects child nodes from self and returns self' do
        expect { subject }.to change { node.children.size }.by(-1)
        expect(subject).to eq node
        expect(subject.children.map(&:class)).to eq [InternalSpec::AMatcher]
      end
    end
  end

  describe '#match?' do
    subject { node.match? }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when node does not have child nodes' do
      it { is_expected.to eq false }
    end

    context 'when node has child nodes' do
      before { node.append!(->(input) { input }) }
      it { is_expected.to eq true }
    end
  end

  describe '#terminate?' do
    subject { node.terminate?(output) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

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

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new.append!(*child_nodes) }
    let(:child_nodes) { [->(input) { input }, ->(input) { input }] }

    let(:input) { 'input' }
    let(:options) { { foo: :bar } }

    let(:strategy) { double(:strategy) }

    before { node.send(:strategy=, strategy) }
    before { expect(strategy).to receive(:call).with(child_nodes, input: input, options: options).and_return('output') }

    it { is_expected.to eq 'output' }
  end

  describe '#identity' do
    subject { node.identity }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    before { expect(node).to receive(:identity).and_return('identity') }

    it { is_expected.to eq 'identity' }
  end

  shared_context 'for building tree' do
    let(:root_node) { CallableTree::Node::Root.new.append!(a_node) }
    let(:a_node) { InternalSpec::AMatcher.new.append!(b_node) }
    let(:b_node) { InternalSpec::BMatcher.new.append!(leaf_node) }
    let(:leaf_node) { ->(input) { input } }
  end

  describe '#parent' do
    subject { node.parent }

    include_context 'for building tree'

    context 'of root_node' do
      let(:node) { root_node }
      it { is_expected.to eq nil }
    end

    context 'of a_node' do
      let(:node) { root_node.children[0] }
      it { is_expected.to eq root_node }
    end

    context 'of b_node' do
      let(:node) { root_node.children[0].children[0] }
      it { is_expected.to eq root_node.children[0] }
    end

    context 'of leaf_node' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq root_node.children[0].children[0] }
    end
  end

  describe '#root?' do
    subject { node.root? }

    include_context 'for building tree'

    context 'of root_node' do
      let(:node) { root_node }
      it { is_expected.to be true }
    end

    context 'of a_node' do
      let(:node) { root_node.children[0] }
      it { is_expected.to be false }
    end

    context 'of b_node' do
      let(:node) { root_node.children[0].children[0] }
      it { is_expected.to be false }
    end

    context 'of leaf_node' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to be false }
    end
  end

  describe '#ancestors' do
    subject { node.ancestors.to_a }

    include_context 'for building tree'

    context 'of root_node' do
      let(:node) { root_node }
      it { is_expected.to eq [root_node] }
    end

    context 'of a_node' do
      let(:node) { root_node.children[0] }
      it { is_expected.to eq [node, root_node] }
    end

    context 'of b_node' do
      let(:node) { root_node.children[0].children[0] }
      it { is_expected.to eq [node, root_node.children[0], root_node] }
    end

    context 'of leaf_node' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq [node, root_node.children[0].children[0], root_node.children[0], root_node] }
    end
  end

  describe '#routes' do
    subject { node.routes }

    include_context 'for building tree'

    context 'of root_node' do
      let(:node) { root_node }
      it { is_expected.to eq [CallableTree::Node::Root] }
    end

    context 'of a_node' do
      let(:node) { root_node.children[0] }
      it { is_expected.to eq [InternalSpec::AMatcher, CallableTree::Node::Root] }
    end

    context 'of b_node' do
      let(:node) { root_node.children[0].children[0] }
      it { is_expected.to eq [InternalSpec::BMatcher, InternalSpec::AMatcher, CallableTree::Node::Root] }
    end

    context 'of leaf_node' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq [Proc, InternalSpec::BMatcher, InternalSpec::AMatcher, CallableTree::Node::Root] }
    end
  end

  describe '#depth' do
    subject { node.depth }

    include_context 'for building tree'

    context 'of root_node' do
      let(:node) { root_node }
      it { is_expected.to eq 0 }
    end

    context 'of a_node' do
      let(:node) { root_node.children[0] }
      it { is_expected.to eq 1 }
    end

    context 'of b_node' do
      let(:node) { root_node.children[0].children[0] }
      it { is_expected.to eq 2 }
    end

    context 'of leaf_node' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq 3 }
    end
  end

  shared_context 'with parent node' do
    let!(:parent_node) do
      CallableTree::Node::Root.new.tap do |root_node|
        root_node.children << node
        node.send(:parent=, root_node)
      end
    end
  end

  describe '#seek' do
    subject { node.seek }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when current strategy is `seek`' do
      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Seek }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Broadcast.new) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Seek }

      context 'when node has parent' do
        include_context 'with parent node'
        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Compose.new) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Seek }

      context 'when node has parent' do
        include_context 'with parent node'
        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end
  end

  describe '#seek!' do
    subject { node.seek! }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when current strategy is `seek`' do
      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Seek }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Broadcast.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Seek }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Compose.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Seek }
    end
  end

  describe '#broadcast' do
    subject { node.broadcast }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when current strategy is `seek`' do
      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Broadcast }

      context 'when node has parent' do
        include_context 'with parent node'
        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Broadcast.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Broadcast }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Compose.new) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Broadcast }

      context 'when node has parent' do
        include_context 'with parent node'
        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end
  end

  describe '#broadcast!' do
    subject { node.broadcast! }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when current strategy is `seek`' do
      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Broadcast }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Broadcast.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Broadcast }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Compose.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Broadcast }
    end
  end

  describe '#compose' do
    subject { node.compose }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when current strategy is `seek`' do
      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Compose }

      context 'when node has parent' do
        include_context 'with parent node'
        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Broadcast.new) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Compose }

      context 'when node has parent' do
        include_context 'with parent node'
        it { expect(subject.root?).to be true }
      end

      context 'when node does not have parent' do
        it { expect(subject.root?).to be true }
      end
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Compose.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Compose }
    end
  end

  describe '#compose!' do
    subject { node.compose! }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when current strategy is `seek`' do
      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Compose }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Broadcast.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Compose }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Strategy::Compose.new) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a CallableTree::Node::Internal::Strategy::Compose }
    end
  end
end
