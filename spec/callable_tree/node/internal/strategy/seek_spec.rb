# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategy::Seek do
  describe '#call' do
    subject { described_class.new.call(nodes, *inputs, **options) }

    let(:nodes) do
      [
        LessThan.new(10).compose.append(
          proc { |input| format('%03d', input) },
          ->(input, *, prefix:, suffix:) { "#{prefix}#{input}#{suffix}" }
        ),
        LessThan.new(20).compose.append(
          ->(*inputs, **) { inputs.sum },
          proc { |input| format('%04d', input) },
          ->(input, *, prefix:, suffix:) { "#{prefix}#{input}#{suffix}" }
        )
      ]
    end

    context 'input: less than 10' do
      let(:inputs) { 9 }
      let(:options) { { prefix: '(', suffix: ')' } }
      it { is_expected.to eq '(009)' }
    end

    context 'inputs: less than 20' do
      let(:inputs) { [13, 4, 1] }
      let(:options) { { prefix: '[', suffix: ']' } }
      it { is_expected.to eq '[0018]' }
    end
  end
end
