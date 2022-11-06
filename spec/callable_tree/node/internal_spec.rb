# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal do
  describe '.included' do
    subject do
      ::Class
        .new do
          include CallableTree::Node::External
          include CallableTree::Node::Internal
        end
        .new
    end

    it {
      expect { subject }.to raise_error(
        ::CallableTree::Error,
        /.+ cannot include CallableTree::Node::Internal together with CallableTree::Node::External/
      )
    }
  end

  describe '#children' do
    subject { node.children }

    let(:node) do
      CallableTree::Node::Root.new.append(
        IdLeaf.new(:a),
        IdLeaf.new(:b)
      )
    end

    it { is_expected.not_to be node.children }
  end

  describe '#children!' do
    subject { node.children! }

    let(:node) do
      CallableTree::Node::Root.new.append(
        IdLeaf.new(:a),
        IdLeaf.new(:b)
      )
    end

    it { is_expected.to be node.children! }
  end

  describe '#[]' do
    subject { node[nth] }

    let(:node) do
      CallableTree::Node::Root.new.append!(
        IdLeaf.new(:a),
        IdLeaf.new(:b)
      )
    end

    context 'when index: 0' do
      let(:nth) { 0 }
      it { is_expected.to eq node.children[nth] }
    end

    context 'when index: 1' do
      let(:nth) { 1 }
      it { is_expected.to eq node.children[nth] }
    end
  end

  describe '#append' do
    subject { node.append(*child_nodes) }

    let(:node) { CallableTree::Node::Root.new }
    let(:child_nodes) do
      [
        IdNode.new(:a1).append!(IdLeaf.new(:a2)),
        IdNode.new(:b1).append!(IdLeaf.new(:b2))
      ]
    end

    it { is_expected.not_to be node }
    it { expect { subject }.not_to change { node.children.size } }

    it 'should generate new child nodes' do
      expect(subject[0]).not_to be child_nodes[0]
      expect(subject[0][0]).not_to be child_nodes[0][0]
      expect(subject[1]).not_to be child_nodes[1]
      expect(subject[1][0]).not_to be child_nodes[1][0]
    end
  end

  describe '#append!' do
    subject { node.append!(*child_nodes) }

    let(:node) { CallableTree::Node::Root.new }
    let(:child_nodes) do
      [
        IdNode.new(:a1).append!(IdLeaf.new(:a2)),
        IdNode.new(:b1).append!(IdLeaf.new(:b2))
      ]
    end

    it { is_expected.to eq node }
    it { expect { subject }.to change { node.children.size }.by(2) }

    it 'should generate new child nodes' do
      subject
      expect(node[0]).not_to be child_nodes[0]
      expect(node[0][0]).not_to be child_nodes[0][0]
      expect(subject[1]).not_to be child_nodes[1]
      expect(subject[1][0]).not_to be child_nodes[1][0]
    end
  end

  describe '#find' do
    subject { node.find(recursive: recursive, &block) }

    let(:node) do
      IdNode.new(8).append(
        IdNode.new(3).append(
          IdLeaf.new(1),
          IdNode.new(6).append(
            IdNode.new(4),
            IdLeaf.new(7)
          )
        ),
        IdNode.new(10).append(
          IdNode.new(14).append(
            IdLeaf.new(13)
          )
        )
      )
    end

    context 'target identity: 10' do
      let(:recursive) { [true, false].sample }
      let(:block) do
        proc { |node| node.identity == 10 }
      end

      it { is_expected.to be node[1] }
    end

    context 'target identity: 1' do
      let(:block) do
        proc { |node| node.identity == 1 }
      end

      context 'recursive: true' do
        let(:recursive) { true }
        it { is_expected.to be node[0][0] }
      end

      context 'recursive: false' do
        let(:recursive) { false }
        it { is_expected.to be nil }
      end
    end

    context 'target identity: 7' do
      let(:block) do
        proc { |node| node.identity == 7 }
      end

      context 'recursive: true' do
        let(:recursive) { true }
        it { is_expected.to be node[0][1][1] }
      end

      context 'recursive: false' do
        let(:recursive) { false }
        it { is_expected.to be nil }
      end
    end

    context 'target identity: 14' do
      let(:block) do
        proc { |node| node.identity == 14 }
      end

      context 'recursive: true' do
        let(:recursive) { true }
        # before { pp node[1][0].identity }
        it { is_expected.to be node[1][0] }
      end

      context 'recursive: false' do
        let(:recursive) { false }
        it { is_expected.to be nil }
      end
    end

    context 'target identity: 99' do
      let(:recursive) { [true, false].sample }
      let(:block) do
        proc { |node| node.identity == 99 }
      end

      it { is_expected.to be nil }
    end
  end

  describe '#reject' do
    subject { node.reject(recursive: recursive, &block) }

    let(:node) do
      IdNode.new(8).append(
        IdNode.new(3).append(
          IdLeaf.new(1),
          IdNode.new(6).append(
            IdNode.new(4),
            IdLeaf.new(7)
          )
        ),
        IdNode.new(10).append(
          IdNode.new(14).append(
            IdLeaf.new(13)
          )
        )
      )
    end

    context 'when ID 3 node is rejected' do
      let(:recursive) { [true, false].sample }
      let(:block) do
        proc { |node| node.identity == 3 }
      end

      it { is_expected.not_to be node }

      it 'does not reject children from the source node' do
        expect { subject }.not_to change { node.children.size }
      end

      it 'returns a node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              10 => {
                14 => {
                  13 => nil
                }
              }
            }
          }
        )
      end
    end

    context 'when ID 10 node is rejected' do
      let(:recursive) { [true, false].sample }
      let(:block) do
        proc { |node| node.identity == 10 }
      end

      it { is_expected.not_to be node }

      it 'does not reject children from the source node' do
        expect { subject }.not_to change { node.children.size }
      end

      it 'returns a node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              3 => {
                1 => nil,
                6 => {
                  4 => {},
                  7 => nil
                }
              }
            }
          }
        )
      end
    end

    context 'when nodes has odd ID are rejected' do
      let(:recursive) { true }
      let(:block) do
        proc { |node| node.identity.odd? }
      end

      it { is_expected.not_to be node }

      it 'does not reject children from the source node' do
        expect { subject }.not_to change { node.children.size }
      end

      it 'returns the node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              10 => {
                14 => {}
              }
            }
          }
        )
      end
    end

    context 'when nodes has even ID are rejected' do
      let(:recursive) { true }
      let(:block) do
        proc { |node| node.identity.even? }
      end

      it { is_expected.not_to be node }

      it 'does not reject children from the source node' do
        expect { subject }.not_to change { node.children.size }
      end

      it 'returns the node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              3 => {
                1 => nil
              }
            }
          }
        )
      end
    end
  end

  describe '#reject!' do
    subject { node.reject!(recursive: recursive, &block) }

    let(:node) do
      IdNode.new(8).append(
        IdNode.new(3).append(
          IdLeaf.new(1),
          IdNode.new(6).append(
            IdNode.new(4),
            IdLeaf.new(7)
          )
        ),
        IdNode.new(10).append(
          IdNode.new(14).append(
            IdLeaf.new(13)
          )
        )
      )
    end

    context 'when ID 3 node is rejected' do
      let(:recursive) { [true, false].sample }
      let(:block) do
        proc { |node| node.identity == 3 }
      end

      it { is_expected.to be node }

      it 'rejects children from the source node' do
        expect { subject }.to change { node.children.size }.by(-1)
      end

      it 'returns a node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              10 => {
                14 => {
                  13 => nil
                }
              }
            }
          }
        )
      end
    end

    context 'when ID 10 node is rejected' do
      let(:recursive) { [true, false].sample }
      let(:block) do
        proc { |node| node.identity == 10 }
      end

      it { is_expected.to be node }

      it 'rejects children from the source node' do
        expect { subject }.to change { node.children.size }.by(-1)
      end

      it 'returns the node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              3 => {
                1 => nil,
                6 => {
                  4 => {},
                  7 => nil
                }
              }
            }
          }
        )
      end
    end

    context 'when nodes has odd ID are rejected' do
      let(:recursive) { true }
      let(:block) do
        proc { |node| node.identity.odd? }
      end

      it { is_expected.to be node }

      it 'rejects children from the source node' do
        expect { subject }.to change { node.children.size }.by(-1)
      end

      it 'returns the node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              10 => {
                14 => {}
              }
            }
          }
        )
      end
    end

    context 'when nodes has even ID are rejected' do
      let(:recursive) { true }
      let(:block) do
        proc { |node| node.identity.even? }
      end

      it { is_expected.to be node }

      it 'rejects children from the source node' do
        expect { subject }.to change { node.children.size }.by(-1)
      end

      it 'returns the node instance without rejected child nodes' do
        expect(subject.outline).to eq(
          {
            8 => {
              3 => {
                1 => nil
              }
            }
          }
        )
      end
    end
  end

  describe '#shake' do
    subject { node.shake(&block) }

    let(:node) do
      IdNode.new(8).append(
        IdNode.new(3).append(
          IdLeaf.new(1),
          IdNode.new(6).append(
            IdNode.new(4),
            IdLeaf.new(7)
          )
        ),
        IdNode.new(10).append(
          IdNode.new(14).append(
            IdLeaf.new(13)
          )
        )
      )
    end

    context 'when no block is given' do
      let(:block) { nil }

      it { is_expected.not_to be node }

      let(:outline) do
        {
          8 => {
            3 => {
              1 => nil,
              6 => {
                7 => nil
              }
            },
            10 => {
              14 => {
                13 => nil
              }
            }
          }
        }
      end

      it 'returns the node instance that is rejected internal nodes that have no child nodes' do
        expect(subject.outline).to eq outline
      end
    end

    context 'when nodes with depth of 3 are rejected' do
      let(:block) do
        proc { |node| node.depth == 3 }
      end

      it { is_expected.not_to be node }

      let(:outline) do
        {
          8 => {
            3 => {
              1 => nil
            }
          }
        }
      end

      it 'returns the node instance that is rejected internal nodes that have no child nodes' do
        expect(subject.outline).to eq outline
      end
    end

    context 'when nodes with odd identity are rejected' do
      let(:block) do
        proc { |node| node.identity.odd? }
      end

      it { is_expected.not_to be node }

      let(:outline) do
        {
          8 => {}
        }
      end

      it 'returns the node instance that is rejected internal nodes that have no child nodes' do
        expect(subject.outline).to eq outline
      end
    end
  end

  describe '#shake!' do
    subject { node.shake!(&block) }

    let(:node) do
      IdNode.new(8).append(
        IdNode.new(3).append(
          IdLeaf.new(1),
          IdNode.new(6).append(
            IdNode.new(4),
            IdLeaf.new(7)
          )
        ),
        IdNode.new(10).append(
          IdNode.new(14).append(
            IdLeaf.new(13)
          )
        )
      )
    end

    context 'when no block is given' do
      let(:block) { nil }

      it { is_expected.to be node }

      let(:outline) do
        {
          8 => {
            3 => {
              1 => nil,
              6 => {
                7 => nil
              }
            },
            10 => {
              14 => {
                13 => nil
              }
            }
          }
        }
      end

      it 'returns the node instance that is rejected internal nodes that have no child nodes' do
        expect(subject.outline).to eq outline
      end
    end

    context 'when nodes with depth of 3 are rejected' do
      let(:block) do
        proc { |node| node.depth == 3 }
      end

      it { is_expected.to be node }

      let(:outline) do
        {
          8 => {
            3 => {
              1 => nil
            }
          }
        }
      end

      it 'returns the node instance that is rejected internal nodes that have no child nodes' do
        expect(subject.outline).to eq outline
      end
    end

    context 'when nodes with odd identity are rejected' do
      let(:block) do
        proc { |node| node.identity.odd? }
      end

      it { is_expected.to be node }

      let(:outline) do
        {
          8 => {}
        }
      end

      it 'returns the node instance that is rejected internal nodes that have no child nodes' do
        expect(subject.outline).to eq outline
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
    subject { node.call(*inputs, **options) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new.append!(*child_nodes) }
    let(:child_nodes) { [->(input) { input }, ->(input) { input }] }

    let(:inputs) { %i[input1 input2 input3] }
    let(:options) { { foo: :bar } }

    let(:strategy) { double(:strategy) }

    before { node.send(:strategy=, strategy) }
    before { expect(strategy).to receive(:call).with(child_nodes, *inputs, **options).and_return(:output) }

    it { is_expected.to eq :output }
  end

  describe '#identity' do
    subject { node.identity }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    before { expect(node).to receive(:identity).and_return('identity') }

    it { is_expected.to eq 'identity' }
  end

  describe '#parent' do
    subject { node.parent }

    let(:tree) do
      CallableTree::Node::Root.new.append!(
        IdNode.new(:a).append!(
          IdNode.new(:b).append!(
            IdLeaf.new(:c)
          )
        )
      )
    end

    context 'of root_node' do
      let(:node) { tree }
      it { is_expected.to eq nil }
    end

    context 'of a_node' do
      let(:node) { tree[0] }
      it { is_expected.to eq tree }
    end

    context 'of b_node' do
      let(:node) { tree[0][0] }
      it { is_expected.to eq tree[0] }
    end

    context 'of c_node' do
      let(:node) { tree[0][0][0] }
      it { is_expected.to eq tree[0][0] }
    end
  end

  describe '#root?' do
    subject { node.root? }

    let(:tree) do
      CallableTree::Node::Root.new.append!(
        IdNode.new(:a).append!(
          IdNode.new(:b).append!(
            IdLeaf.new(:c)
          )
        )
      )
    end

    context 'of root_node' do
      let(:node) { tree }
      it { is_expected.to be true }
    end

    context 'of a_node' do
      let(:node) { tree[0] }
      it { is_expected.to be false }
    end

    context 'of b_node' do
      let(:node) { tree[0][0] }
      it { is_expected.to be false }
    end

    context 'of c_node' do
      let(:node) { tree[0][0][0] }
      it { is_expected.to be false }
    end
  end

  describe '#ancestors' do
    subject { node.ancestors.to_a }

    let(:tree) do
      CallableTree::Node::Root.new.append!(
        IdNode.new(:a).append!(
          IdNode.new(:b).append!(
            IdLeaf.new(:c)
          )
        )
      )
    end

    context 'of root_node' do
      let(:node) { tree }
      it { is_expected.to eq [tree] }
    end

    context 'of a_node' do
      let(:node) { tree[0] }
      it { is_expected.to eq [node, tree] }
    end

    context 'of b_node' do
      let(:node) { tree[0][0] }
      it { is_expected.to eq [node, tree[0], tree] }
    end

    context 'of c_node' do
      let(:node) { tree[0][0][0] }
      it { is_expected.to eq [node, tree[0][0], tree[0], tree] }
    end
  end

  describe '#routes' do
    subject { node.routes }

    let(:tree) do
      CallableTree::Node::Root.new.append!(
        IdNode.new(:a).append!(
          IdNode.new(:b).append!(
            IdLeaf.new(:c)
          )
        )
      )
    end

    context 'of root_node' do
      let(:node) { tree }
      it { is_expected.to eq [CallableTree::Node::Root] }
    end

    context 'of a_node' do
      let(:node) { tree[0] }
      it { is_expected.to eq [:a, CallableTree::Node::Root] }
    end

    context 'of b_node' do
      let(:node) { tree[0][0] }
      it { is_expected.to eq [:b, :a, CallableTree::Node::Root] }
    end

    context 'of c_node' do
      let(:node) { tree[0][0][0] }
      it { is_expected.to eq [:c, :b, :a, CallableTree::Node::Root] }
    end
  end

  describe '#depth' do
    subject { node.depth }

    let(:tree) do
      CallableTree::Node::Root.new.append!(
        IdNode.new(:a).append!(
          IdNode.new(:b).append!(
            IdLeaf.new(:c)
          )
        )
      )
    end

    context 'of root_node' do
      let(:node) { tree }
      it { is_expected.to eq 0 }
    end

    context 'of a_node' do
      let(:node) { tree[0] }
      it { is_expected.to eq 1 }
    end

    context 'of b_node' do
      let(:node) { tree[0][0] }
      it { is_expected.to eq 2 }
    end

    context 'of c_node' do
      let(:node) { tree[0][0][0] }
      it { is_expected.to eq 3 }
    end
  end

  describe '#seek?' do
    subject { node.seek? }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when strategy is `seek`' do
      before { node.send(:strategy=, described_class::Strategy::Seek.new) }
      it { is_expected.to be true }
    end

    context 'when strategy is not `seek`' do
      before do
        node.send(:strategy=, [
          described_class::Strategy::Broadcast.new,
          described_class::Strategy::Compose.new
        ].sample)
      end
      it { is_expected.to be false }
    end
  end

  describe '#seek' do
    subject { node.seek(terminable: terminable) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    let(:terminable) { [true, false].sample }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, described_class::Strategy::Seek.new(terminable: current_terminable)) }

      context 'when options are the same' do
        let(:current_terminable) { terminable }

        it { is_expected.to be node }
        it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Seek }
      end

      context 'when options are not the same' do
        let(:current_terminable) { !terminable }

        it { is_expected.not_to be node }
        it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Seek }
      end
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, described_class::Strategy::Broadcast.new(terminable: [true, false].sample)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Seek }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, described_class::Strategy::Compose.new(terminable: [true, false].sample)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Seek }
    end
  end

  describe '#seek!' do
    subject { node.seek!(terminable: terminable) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    let(:terminable) { [true, false].sample }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, described_class::Strategy::Seek.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Seek }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, described_class::Strategy::Broadcast.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Seek }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, described_class::Strategy::Compose.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Seek }
    end
  end

  describe '#broadcast?' do
    subject { node.broadcast? }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when strategy is `broadcast`' do
      before { node.send(:strategy=, described_class::Strategy::Broadcast.new) }
      it { is_expected.to be true }
    end

    context 'when strategy is not `broadcast`' do
      before do
        node.send(:strategy=, [
          described_class::Strategy::Seek.new,
          described_class::Strategy::Compose.new
        ].sample)
      end
      it { is_expected.to be false }
    end
  end

  describe '#broadcast' do
    subject { node.broadcast(terminable: terminable) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    let(:terminable) { [true, false].sample }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, described_class::Strategy::Seek.new(terminable: [true, false].sample)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Broadcast }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, described_class::Strategy::Broadcast.new(terminable: current_terminable)) }

      context 'when options are the same' do
        let(:current_terminable) { terminable }

        it { is_expected.to be node }
        it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Broadcast }
      end

      context 'when options are not the same' do
        let(:current_terminable) { !terminable }

        it { is_expected.not_to be node }
        it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Broadcast }
      end
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, described_class::Strategy::Compose.new(terminable: [true, false].sample)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Broadcast }
    end
  end

  describe '#broadcast!' do
    subject { node.broadcast!(terminable: terminable) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    let(:terminable) { [true, false].sample }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, described_class::Strategy::Seek.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Broadcast }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, described_class::Strategy::Broadcast.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Broadcast }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, described_class::Strategy::Compose.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Broadcast }
    end
  end

  describe '#compose?' do
    subject { node.compose? }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }

    context 'when strategy is `compose`' do
      before { node.send(:strategy=, described_class::Strategy::Compose.new) }
      it { is_expected.to be true }
    end

    context 'when strategy is not `compose`' do
      before do
        node.send(:strategy=, [
          described_class::Strategy::Seek.new,
          described_class::Strategy::Broadcast.new
        ].sample)
      end
      it { is_expected.to be false }
    end
  end

  describe '#compose' do
    subject { node.compose(terminable: terminable) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    let(:terminable) { [true, false].sample }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, described_class::Strategy::Seek.new(terminable: [true, false].sample)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Compose }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, described_class::Strategy::Broadcast.new(terminable: [true, false].sample)) }

      it { is_expected.not_to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Compose }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, described_class::Strategy::Compose.new(terminable: current_terminable)) }

      context 'when options are the same' do
        let(:current_terminable) { terminable }

        it { is_expected.to be node }
        it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Compose }
      end

      context 'when options are not the same' do
        let(:current_terminable) { !terminable }

        it { is_expected.not_to be node }
        it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Compose }
      end
    end
  end

  describe '#compose!' do
    subject { node.compose!(terminable: terminable) }

    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    let(:terminable) { [true, false].sample }

    context 'when current strategy is `seek`' do
      before { node.send(:strategy=, described_class::Strategy::Seek.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Compose }
    end

    context 'when current strategy is `broadcast`' do
      before { node.send(:strategy=, described_class::Strategy::Broadcast.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Compose }
    end

    context 'when current strategy is `compose`' do
      before { node.send(:strategy=, described_class::Strategy::Compose.new(terminable: [true, false].sample)) }

      it { is_expected.to be node }
      it { expect(subject.send(:strategy)).to be_a described_class::Strategy::Compose }
    end
  end

  describe '#outline' do
    subject { node.outline }

    let(:node) do
      IdNode.new(8).append(
        IdNode.new(3).append(
          IdLeaf.new(1),
          IdNode.new(6).append(
            IdNode.new(4),
            IdLeaf.new(7)
          )
        ),
        IdNode.new(10).append(
          IdNode.new(14).append(
            IdLeaf.new(13)
          )
        )
      )
    end

    let(:result) do
      {
        8 => {
          3 => {
            1 => nil,
            6 => {
              4 => {},
              7 => nil
            }
          },
          10 => {
            14 => {
              13 => nil
            }
          }
        }
      }
    end

    it { is_expected.to eq result }
  end

  describe '#internal?' do
    subject { node.internal? }
    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    it { is_expected.to be true }
  end

  describe '#external?' do
    subject { node.external? }
    let(:node) { ::Class.new { include CallableTree::Node::Internal }.new }
    it { is_expected.to be false }
  end

  describe '#clone' do
    subject { node.clone }

    let(:tree) do
      CallableTree::Node::Root.new.append!(
        IdNode.new(:a).append!(
          IdLeaf.new(:b)
        )
      )
    end

    context 'of root_node' do
      let(:node) { tree }
      it { is_expected.not_to be tree }

      it 'should have cloned child nodes' do
        expect(subject[0]).not_to be node[0]
      end

      it 'should be linked from child node as parent node' do
        expect(subject[0].parent).to be subject
      end
    end

    context 'of a_node' do
      let(:node) { tree[0] }
      it { is_expected.not_to be tree[0] }

      it 'should have not parent node' do
        expect(subject.parent).to be nil
      end

      it 'should have cloned child nodes' do
        expect(subject[0]).not_to be node[0]
      end

      it 'should be linked from child node as parent node' do
        expect(subject[0].parent).to be subject
      end
    end

    context 'of b_node' do
      let(:node) { tree[0][0] }
      it { is_expected.not_to be tree[0][0] }

      it 'should have not parent node' do
        expect(subject.parent).to be nil
      end
    end
  end
end
