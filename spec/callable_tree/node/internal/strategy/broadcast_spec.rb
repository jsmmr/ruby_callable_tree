# frozen_string_literal: true

RSpec.describe CallableTree::Node::Internal::Strategy::Broadcast do
  describe '#name' do
    subject { described_class.new.name }
    it { is_expected.to eq :broadcast }
  end

  describe '#==' do
    subject { described_class.new(matchable: matchable, terminable: terminable) }

    let(:matchable) { [true, false].sample }
    let(:terminable) { [true, false].sample }

    context 'when strategies are the same' do
      context 'when options are the same' do
        it { is_expected.to eq described_class.new(matchable: matchable, terminable: terminable) }
      end

      context 'when options are not the same' do
        it { is_expected.not_to eq described_class.new(matchable: !matchable, terminable: terminable) }
        it { is_expected.not_to eq described_class.new(matchable: matchable, terminable: !terminable) }
      end
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Compose,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eq other.new(matchable: matchable, terminable: terminable) }
    end
  end

  describe '#eql?' do
    subject { described_class.new(matchable: matchable, terminable: terminable) }

    let(:matchable) { [true, false].sample }
    let(:terminable) { [true, false].sample }

    context 'when strategies are the same' do
      context 'when options are the same' do
        it { is_expected.to eql described_class.new(matchable: matchable, terminable: terminable) }
      end

      context 'when options are not the same' do
        it { is_expected.not_to eq described_class.new(matchable: !matchable, terminable: terminable) }
        it { is_expected.not_to eq described_class.new(matchable: matchable, terminable: !terminable) }
      end
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Compose,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eql other.new(matchable: matchable, terminable: terminable) }
    end
  end

  describe '#hash' do
    subject { described_class.new(matchable: matchable, terminable: terminable).hash }

    let(:matchable) { [true, false].sample }
    let(:terminable) { [true, false].sample }

    context 'when strategies are the same' do
      context 'when options are the same' do
        it { is_expected.to eq described_class.new(matchable: matchable, terminable: terminable).hash }
      end

      context 'when options are not the same' do
        it { is_expected.not_to eq described_class.new(matchable: !matchable, terminable: terminable).hash }
        it { is_expected.not_to eq described_class.new(matchable: matchable, terminable: !terminable).hash }
      end
    end

    context 'when strategies are not the same' do
      let(:other) do
        [
          CallableTree::Node::Internal::Strategy::Compose,
          CallableTree::Node::Internal::Strategy::Seek
        ].sample
      end
      it { is_expected.not_to eq other.new(matchable: matchable, terminable: terminable).hash }
    end
  end

  describe '#matchable?' do
    subject { described_class.new(matchable: matchable).matchable? }

    context 'matchable: true' do
      let(:matchable) { true }
      it { is_expected.to be true }
    end

    context 'matchable: false' do
      let(:matchable) { false }
      it { is_expected.to be false }
    end
  end

  describe '#terminable?' do
    subject { described_class.new(terminable: terminable).terminable? }

    context 'terminable: true' do
      let(:terminable) { true }
      it { is_expected.to be true }
    end

    context 'terminable: false' do
      let(:terminable) { false }
      it { is_expected.to be false }
    end
  end

  describe '#call' do
    subject do
      described_class.new(matchable: matchable, terminable: terminable).call(tree.children, *inputs, **options)
    end

    let(:tree) do
      decorator = ->(input, *, prefix:, suffix:, **) { "#{prefix}#{input}#{suffix}" }

      CallableTree::Node::Root.new.broadcastable.append(
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

    let(:matchable) { true }
    let(:terminable) { false }

    context 'matchable: true' do
      let(:matchable) { true }

      context 'input: less than 10' do
        let(:inputs) { 9 }
        let(:options) { { prefix: '(', suffix: ')' } }
        it { is_expected.to eq ['(009)', '(0009)'] }
      end

      context 'input: greater than 10' do
        let(:inputs) { [13, 4, 1] }
        let(:options) { { prefix: '[', suffix: ']' } }
        it { is_expected.to eq [nil, '[0018]'] }
      end
    end

    context 'matchable: false' do
      let(:matchable) { false }

      context 'input: less than 10' do
        let(:inputs) { 9 }
        let(:options) { { prefix: '(', suffix: ')' } }
        it { is_expected.to eq [nil, nil] }
      end

      context 'input: greater than 10' do
        let(:inputs) { [13, 4, 1] }
        let(:options) { { prefix: '[', suffix: ']' } }
        it { is_expected.to eq [nil, nil] }
      end
    end

    context 'terminable: true' do
      let(:terminable) { true }

      context 'input: less than 10' do
        let(:inputs) { 9 }
        let(:options) { { prefix: '(', suffix: ')' } }
        it { is_expected.to eq ['(009)'] }
      end

      context 'input: greater than 10' do
        let(:inputs) { [13, 4, 1] }
        let(:options) { { prefix: '[', suffix: ']' } }
        it { is_expected.to eq [nil, '[0018]'] }
      end
    end

    context 'terminable: false' do
      let(:terminable) { false }

      context 'input: less than 10' do
        let(:inputs) { 9 }
        let(:options) { { prefix: '(', suffix: ')' } }
        it { is_expected.to eq ['(009)', '(0009)'] }
      end

      context 'input: greater than 10' do
        let(:inputs) { [13, 4, 1] }
        let(:options) { { prefix: '[', suffix: ']' } }
        it { is_expected.to eq [nil, '[0018]'] }
      end
    end
  end
end
