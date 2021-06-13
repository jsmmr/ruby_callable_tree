# frozen_string_literal: true

RSpec.describe CallableTree::Node::Root do
  let(:node) { described_class.new }

  describe '.new' do
    subject { node }
    it { is_expected.to be_a ::CallableTree::Node::Internal }
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
    it { is_expected.to eq [CallableTree::Node::Root] }
  end

  describe '#depth' do
    subject { node.depth }
    it { is_expected.to eq 0 }
  end

  describe '#append' do
    subject { node.append(*child_nodes) }
    let(:child_nodes) { [->(input) { input }, ->(input) { input }] }
    it { is_expected.not_to eq node }
    it { expect { subject }.not_to change { node.children.size } }
    it { expect(subject.children.map(&:object_id)).not_to match_array child_nodes.map(&:object_id) }
  end

  describe '#append!' do
    subject { node.append!(*child_nodes) }
    let(:child_nodes) { [->(input) { input }, ->(input) { input }] }
    it { is_expected.to eq node }
    it { expect { subject }.to change { node.children.size }.by(2) }
    it { expect(subject.children.map(&:object_id)).not_to match_array child_nodes.map(&:object_id) }
  end

  describe '#match?' do
    subject { node.match? }

    context 'when root node does not have child nodes' do
      it { is_expected.to eq false }
    end

    context 'when root node has child nodes' do
      before { node.append!(->(input) { input }) }
      it { is_expected.to eq true }
    end
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
    subject { node.call(input) }

    let(:input) { 'input' }

    context 'when root node does not have child nodes' do
      it { is_expected.to eq nil }
    end

    context 'when root node has child nodes' do
      before { node.append!(->(input, **) { input }) }
      it { is_expected.to eq input }
    end
  end
end
