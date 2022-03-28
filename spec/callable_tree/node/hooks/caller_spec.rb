# frozen_string_literal: true

RSpec.describe CallableTree::Node::Hooks::Caller do
  shared_context 'for before_call' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .caller { |input, **| input - 5 }
        .hookable
        .build
        .new
    end

    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    let(:caller1) { proc { |input, *, **| input + 1 } }
    let(:caller2) { proc { |input, *, **| input * 2 } }

    before do
      expect(caller1).to receive(:call).with(*inputs, _node_: node, **options).and_call_original
      expect(caller2).to receive(:call).with(2, *inputs.slice(1, 2), _node_: node, **options).and_call_original
    end
  end

  describe '#before_call' do
    subject { node.call(*inputs, **options) }

    include_context 'for before_call'

    let(:node) do
      base_node
        .before_call(&caller1)
        .before_call(&caller2)
    end

    it { is_expected.to eq(-1) }

    it 'should have different IDs for base_node and node' do
      subject
      expect(node).not_to be base_node
    end
  end

  describe '#before_call!' do
    subject { node.call(*inputs, **options) }

    include_context 'for before_call'

    let(:node) do
      base_node
        .before_call!(&caller1)
        .before_call!(&caller2)
    end

    it { is_expected.to eq(-1) }

    it 'should have the same IDs for base_node and node' do
      subject
      expect(node).to be base_node
    end
  end

  shared_context 'for around_call' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .caller { |*inputs, **| inputs.reduce(0, &:+) }
        .hookable
        .build
        .new
    end

    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    before do
      expect(caller1).to receive(:call).with(*inputs, _node_: node, **options).and_call_original
      expect(caller2).to receive(:call).with(*inputs, _node_: node, **options).and_call_original
    end
  end

  describe '#around_call' do
    subject { node.call(*inputs, **options) }

    include_context 'for around_call'

    let(:node) do
      base_node
        .around_call(&caller1)
        .around_call(&caller2)
    end

    context 'when block is called' do
      let(:caller1) { proc { |*, **, &block| block.call / 2 } }
      let(:caller2) { proc { |*, **, &block| block.call - 3 } }

      it { is_expected.to eq 0 }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).not_to be base_node
      end
    end

    context 'when block is not called' do
      let(:caller1) { proc { |*, **| 1 } }
      let(:caller2) { proc { |*, **, &block| block.call - 1 } }

      it { is_expected.to eq 0 }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).not_to be base_node
      end
    end
  end

  describe '#around_call!' do
    subject { node.call(*inputs, **options) }

    include_context 'for around_call'

    let(:node) do
      base_node
        .around_call!(&caller1)
        .around_call!(&caller2)
    end

    context 'when block is called' do
      let(:caller1) { proc { |*, **, &block| block.call / 2 } }
      let(:caller2) { proc { |*, **, &block| block.call - 3 } }

      it { is_expected.to eq 0 }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).to be base_node
      end
    end

    context 'when block is not called' do
      let(:caller1) { proc { |*, **| 1 } }
      let(:caller2) { proc { |*, **, &block| block.call - 1 } }

      it { is_expected.to eq 0 }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).to be base_node
      end
    end
  end

  shared_context 'for after_call' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .caller { |*inputs, **| inputs.reduce(0, &:+) }
        .hookable
        .build
        .new
    end

    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    let(:caller1) { proc { |output, *, **| output * 2 } }
    let(:caller2) { proc { |output, *, **| output % 5 } }

    before do
      expect(caller1).to receive(:call).with(6, _node_: node, **options).and_call_original
      expect(caller2).to receive(:call).with(12, _node_: node, **options).and_call_original
    end
  end

  describe '#after_call' do
    subject { node.call(*inputs, **options) }

    include_context 'for after_call'

    let(:node) do
      base_node
        .after_call(&caller1)
        .after_call(&caller2)
    end

    it { is_expected.to eq 2 }

    it 'should have different IDs for base_node and node' do
      subject
      expect(node).not_to be base_node
    end
  end

  describe '#after_call!' do
    subject { node.call(*inputs, **options) }

    include_context 'for after_call'

    let(:node) do
      base_node
        .after_call!(&caller1)
        .after_call!(&caller2)
    end

    it { is_expected.to eq 2 }

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
        .before_call(&:before_callback)
        .around_call(&:around_callback)
        .after_call(&:after_callback)
    end

    it 'should generate new array' do
      expect(subject.before_caller_callbacks).not_to be node.before_caller_callbacks
      expect(subject.around_caller_callbacks).not_to be node.around_caller_callbacks
      expect(subject.after_caller_callbacks).not_to be node.after_caller_callbacks
    end
  end
end
