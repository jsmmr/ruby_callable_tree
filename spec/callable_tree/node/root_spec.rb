# frozen_string_literal: true

RSpec.describe CallableTree::Node::Root do
  let(:node) { described_class.new }

  describe '.new' do
    subject { node }
    it { is_expected.to be_a ::CallableTree::Node::Internal }
  end
end
