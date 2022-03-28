# frozen_string_literal: true

RSpec.describe CallableTree::Node::Hooks::Matcher do
  shared_context 'for before_matcher' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .matcher { |input, **| input == 4 }
        .caller { |input, **| input }
        .hookable
        .build
        .new
    end

    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    let(:matcher1) { proc { |input, *, **| input + 1 } }
    let(:matcher2) { proc { |input, *, **| input * 2 } }

    before do
      expect(matcher1).to receive(:call).with(*inputs, _node_: node, **options).and_call_original
      expect(matcher2).to receive(:call).with(2, *inputs.slice(1, 2), _node_: node, **options).and_call_original
    end
  end

  describe '#before_matcher' do
    subject { node.match?(*inputs, **options) }

    include_context 'for before_matcher'

    let(:node) do
      base_node
        .before_matcher(&matcher1)
        .before_matcher(&matcher2)
    end

    it { is_expected.to eq true }

    it 'should have different IDs for base_node and node' do
      subject
      expect(node).not_to be base_node
    end
  end

  describe '#before_matcher!' do
    subject { node.match?(*inputs, **options) }

    include_context 'for before_matcher'

    let(:node) do
      base_node
        .before_matcher!(&matcher1)
        .before_matcher!(&matcher2)
    end

    it { is_expected.to eq true }

    it 'should have the same IDs for base_node and node' do
      subject
      expect(node).to be base_node
    end
  end

  shared_context 'for around_matcher' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .matcher { |*inputs, **| inputs.reduce(0, &:+) == 6 }
        .caller { |input, **| input }
        .hookable
        .build
        .new
    end

    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    before do
      expect(matcher1).to receive(:call).with(*inputs, _node_: node, **options).and_call_original
      expect(matcher2).to receive(:call).with(*inputs, _node_: node, **options).and_call_original
    end
  end

  describe '#around_matcher' do
    subject { node.match?(*inputs, **options) }

    include_context 'for around_matcher'

    let(:node) do
      base_node
        .around_matcher(&matcher1)
        .around_matcher(&matcher2)
    end

    context 'when block is called' do
      let(:matcher1) { proc { |*, **, &block| !block.call } }
      let(:matcher2) { proc { |*, **, &block| block.call == false } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).not_to be base_node
      end
    end

    context 'when block is not called' do
      let(:matcher1) { proc { |*, **| 1 } }
      let(:matcher2) { proc { |*, **, &block| block.call == 1 } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).not_to be base_node
      end
    end
  end

  describe '#around_matcher!' do
    subject { node.match?(*inputs, **options) }

    include_context 'for around_matcher'

    let(:node) do
      base_node
        .around_matcher!(&matcher1)
        .around_matcher!(&matcher2)
    end

    context 'when block is called' do
      let(:matcher1) { proc { |*, **, &block| !block.call } }
      let(:matcher2) { proc { |*, **, &block| block.call == false } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).to be base_node
      end
    end

    context 'when block is not called' do
      let(:matcher1) { proc { |*, **| 1 } }
      let(:matcher2) { proc { |*, **, &block| block.call == 1 } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).to be base_node
      end
    end
  end

  shared_context 'for after_matcher' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .matcher { |*inputs, **| inputs.reduce(0, &:+) == 6 }
        .caller { |input, **| input }
        .hookable
        .build
        .new
    end

    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    let(:matcher1) { proc { |matched, *, **| !matched } }
    let(:matcher2) { proc { |matched, *, **| !matched } }

    before do
      expect(matcher1).to receive(:call).with(true, _node_: node, **options).and_call_original
      expect(matcher2).to receive(:call).with(false, _node_: node, **options).and_call_original
    end
  end

  describe '#after_matcher' do
    subject { node.match?(*inputs, **options) }

    include_context 'for after_matcher'

    let(:node) do
      base_node
        .after_matcher(&matcher1)
        .after_matcher(&matcher2)
    end

    it { is_expected.to eq true }

    it 'should have different IDs for base_node and node' do
      subject
      expect(node).not_to be base_node
    end
  end

  describe '#after_matcher!' do
    subject { node.match?(*inputs, **options) }

    include_context 'for after_matcher'

    let(:node) do
      base_node
        .after_matcher!(&matcher1)
        .after_matcher!(&matcher2)
    end

    it { is_expected.to eq true }

    it 'should have the same IDs for base_node and node' do
      subject
      expect(node).to be base_node
    end
  end

  describe '#clone' do
    subject { node.clone }

    let(:before_callback) { proc { |input, *, **| input } }
    let(:around_callback) { proc { |_input, *, **, &block| block.call } }
    let(:after_callback) { proc { |output, **| output } }

    let(:node) do
      CallableTree::Node::External::Builder
        .new
        .caller { |input, **| input }
        .hookable
        .build
        .new
        .before_matcher(&:before_callback)
        .around_matcher(&:around_callback)
        .after_matcher(&:after_callback)
    end

    it 'should generate new array' do
      expect(subject.before_matcher_callbacks).not_to be node.before_matcher_callbacks
      expect(subject.around_matcher_callbacks).not_to be node.around_matcher_callbacks
      expect(subject.after_matcher_callbacks).not_to be node.after_matcher_callbacks
    end
  end
end
