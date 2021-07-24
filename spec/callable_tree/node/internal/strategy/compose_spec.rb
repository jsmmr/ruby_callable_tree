# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategy::Compose do
  module InternalComposeSpec
    class AMatcher
      include CallableTree::Node::Internal

      def match?(input, **)
        super && input < 10
      end
    end

    class BMatcher
      include CallableTree::Node::Internal

      def match?(input, **)
        super && input < 20
      end
    end
  end

  describe '#call' do
    subject { described_class.new.call(nodes, input: input, options: options) }

    let(:nodes) do
      [
        InternalComposeSpec::AMatcher.new.append(->(input, **) { input * 2 }),
        InternalComposeSpec::BMatcher.new.append(->(input, **) { input * 3 })
      ]
    end

    context 'input: less than 10' do
      let(:input) { 9 }
      let(:options) { {} }
      it { is_expected.to eq 54 }
    end

    context 'input: less than 20' do
      let(:input) { 13 }
      let(:options) { {} }
      it { is_expected.to eq 39 }
    end
  end
end
