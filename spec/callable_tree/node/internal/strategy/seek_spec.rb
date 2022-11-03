# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategy::Seek do
  describe '#name' do
    subject { described_class.new.name }
    it { is_expected.to eq :seek }
  end

  describe '#==' do
    subject { described_class.new }

    context 'when strategies are the same' do
      it { is_expected.to eq described_class.new }
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Compose
        ].sample
      end
      it { is_expected.not_to eq other.new }
    end
  end

  describe '#eql?' do
    subject { described_class.new }

    context 'when strategies are the same' do
      it { is_expected.to eql described_class.new }
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Compose
        ].sample
      end
      it { is_expected.not_to eql other.new }
    end
  end

  describe '#hash' do
    subject { described_class.new.hash }

    context 'when strategies are the same' do
      it { is_expected.to eq described_class.new.hash }
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Broadcast,
          CallableTree::Node::Internal::Strategy::Compose
        ].sample
      end
      it { is_expected.not_to eq other.new.hash }
    end
  end

  describe '#call' do
    subject { described_class.new.call(tree.children, *inputs, **options) }

    let(:tree) do
      decorator = ->(input, *, prefix:, suffix:) { "#{prefix}#{input}#{suffix}" }

      CallableTree::Node::Root.new.seekable.append(
        build_less_than(10).new.compose.append(
          build_formatter('%03d').new,
          decorator
        ),
        build_less_than(20).new.compose.append(
          ->(*inputs, **) { inputs.sum },
          build_formatter('%04d').new,
          decorator
        )
      )
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
