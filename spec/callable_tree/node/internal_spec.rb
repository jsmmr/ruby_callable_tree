# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal do
  module InternalSpec
    class AMatcher
      include CallableTree::Node::Internal

      def match?(input, **)
        super && input.to_s.start_with?('a')
      end

      def call(input, **options)
        super(input.to_s, **options)
      end
    end

    class BMatcher
      include CallableTree::Node::Internal

      def match?(input, **)
        super && input.to_s.start_with?('b')
      end

      def call(input, **options)
        super(input.to_s, **options)
      end
    end
  end

  describe '#<<' do
    subject { node << child_node }

    let(:root_node) { CallableTree::Node::Root.new }
    let(:a_node) { InternalSpec::AMatcher.new }
    let(:b_node) { InternalSpec::BMatcher.new }
    let(:leaf) { ->(input) { input } }

    context 'of root_node' do
      let(:node) { root_node }
      let(:child_node) { a_node << b_node }

      it { expect { subject }.to change { node.children.size }.by(1) }

      it 'should generate new node' do
        subject
        expect(node.children[0].object_id).not_to eq child_node.object_id
      end

      it 'should generate new child nodes' do
        subject
        expect(node.children[0].children.map(&:object_id)).not_to eq child_node.children.map(&:object_id)
      end
    end

    context 'of a_node' do
      let(:node) { a_node }
      let(:child_node) { b_node << leaf }

      it { expect { subject }.to change { node.children.size }.by(1) }

      it 'should generate new node' do
        subject
        expect(node.children[0].object_id).not_to eq child_node.object_id
      end

      it 'should generate new child nodes' do
        subject
        expect(node.children[0].children.map(&:object_id)).not_to eq child_node.children.map(&:object_id)
      end
    end

    context 'of b_node' do
      let(:node) { b_node }
      let(:child_node) { leaf }

      it { expect { subject }.to change { node.children.size }.by(1) }

      it 'should generate new node' do
        subject
        expect(node.children[0].object_id).not_to eq child_node.object_id
      end
    end
  end

  describe '#append' do
    subject { node.append(*child_nodes) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    let(:child_nodes) { [->(input) { input }, ->(input) { input }] }

    it { expect { subject }.to change { node.children.size }.by(2) }
  end

  describe '#match?' do
    subject { node.match? }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when node does not have child nodes' do
      it { is_expected.to eq false }
    end

    context 'when node has child nodes' do
      before { node << ->(input) { input } }
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

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new.append(*child_nodes) }
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
    let(:node) { InternalSpec::AMatcher.new  }
    it { is_expected.to eq InternalSpec::AMatcher }
  end

  describe '#parent' do
    subject { node.parent }

    let(:root_node) { CallableTree::Node::Root.new << a_node }
    let(:a_node) { InternalSpec::AMatcher.new << b_node }
    let(:b_node) { InternalSpec::BMatcher.new << leaf }
    let(:leaf) { ->(input) { input } }

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

    context 'of leaf' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq root_node.children[0].children[0] }
    end
  end

  describe '#ancestors' do
    subject { node.ancestors.to_a }

    let(:root_node) { CallableTree::Node::Root.new << a_node }
    let(:a_node) { InternalSpec::AMatcher.new << b_node }
    let(:b_node) { InternalSpec::BMatcher.new << leaf }
    let(:leaf) { ->(input) { input } }

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

    context 'of leaf' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq [node, root_node.children[0].children[0], root_node.children[0], root_node] }
    end
  end

  describe '#routes' do
    subject { node.routes }

    let(:root_node) { CallableTree::Node::Root.new << a_node }
    let(:a_node) { InternalSpec::AMatcher.new << b_node }
    let(:b_node) { InternalSpec::BMatcher.new << leaf }
    let(:leaf) { ->(input) { input } }

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

    context 'of leaf' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq [Proc, InternalSpec::BMatcher, InternalSpec::AMatcher, CallableTree::Node::Root] }
    end
  end

  describe '#depth' do
    subject { node.depth }

    let(:root_node) { CallableTree::Node::Root.new << a_node }
    let(:a_node) { InternalSpec::AMatcher.new << b_node }
    let(:b_node) { InternalSpec::BMatcher.new << leaf }
    let(:leaf) { ->(input) { input } }

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

    context 'of leaf' do
      let(:node) { root_node.children[0].children[0].children[0] }
      it { is_expected.to eq 3 }
    end
  end

  describe '#seek' do
    subject { node.seek }

    let(:node) { CallableTree::Node::Root.new }

    context 'when current strategy is `seek`' do
      it { is_expected.to be node }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Broadcast.new) }
      it { is_expected.not_to be node }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Compose.new) }
      it { is_expected.not_to be node }
    end
  end

  describe '#broadcast' do
    subject { node.broadcast }

    let(:node) { CallableTree::Node::Root.new }

    context 'when current strategy is `seek`' do
      it { is_expected.not_to be node }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Broadcast.new) }
      it { is_expected.to be node }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Compose.new) }
      it { is_expected.not_to be node }
    end
  end

  describe '#compose' do
    subject { node.compose }

    let(:node) { CallableTree::Node::Root.new }

    context 'when current strategy is `seek`' do
      it { is_expected.not_to be node }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Broadcast.new) }
      it { is_expected.not_to be node }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, CallableTree::Node::Internal::Compose.new) }
      it { is_expected.to be node }
    end
  end
end
