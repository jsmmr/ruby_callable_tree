# frozen_string_literal: true

RSpec.describe CallableTree::Node::Hooks::Terminator do
  shared_context 'for before_terminator' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .caller { |input, **| input }
        .terminator { |output, *, **| output == 11 }
        .hookable
        .build
        .new
    end

    let(:output) { 0 }
    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    let(:callback1) { proc { |output, *, **| output + 1 } }
    let(:callback2) { proc { |output, *, **| output * 11 } }

    before do
      expect(callback1).to receive(:call).with(0, *inputs, **options, _node_: node).and_call_original
      expect(callback2).to receive(:call).with(1, *inputs, **options, _node_: node).and_call_original
    end
  end

  describe '#before_terminator' do
    subject { node.terminate?(output, *inputs, **options) }

    include_context 'for before_terminator'

    let(:node) do
      base_node
        .before_terminator(&callback1)
        .before_terminator(&callback2)
    end

    it { is_expected.to eq true }

    it 'should have different IDs for base_node and node' do
      subject
      expect(node).not_to be base_node
    end
  end

  describe '#before_terminator!' do
    subject { node.terminate?(output, *inputs, **options) }

    include_context 'for before_terminator'

    let(:node) do
      base_node
        .before_terminator!(&callback1)
        .before_terminator!(&callback2)
    end

    it { is_expected.to eq true }

    it 'should have the same IDs for base_node and node' do
      subject
      expect(node).to be base_node
    end
  end

  shared_context 'for around_terminator' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .caller { |input, **| input }
        .terminator { |output, *, **| output == 9 }
        .hookable
        .build
        .new
    end

    let(:output) { 0 }
    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    before do
      expect(callback1).to receive(:call).with(output, *inputs, **options, _node_: node).and_call_original
      expect(callback2).to receive(:call).with(output, *inputs, **options, _node_: node).and_call_original
    end
  end

  describe '#around_terminator' do
    subject { node.terminate?(output, *inputs, **options) }

    include_context 'for around_terminator'

    let(:node) do
      base_node
        .around_terminator(&callback1)
        .around_terminator(&callback2)
    end

    context 'when block is called' do
      let(:callback1) { proc { |*, **, &block| block.call == false } }
      let(:callback2) { proc { |*, **, &block| block.call == true } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).not_to be base_node
      end
    end

    context 'when block is not called' do
      let(:callback1) { proc { |*, **| true } }
      let(:callback2) { proc { |*, **, &block| block.call == true } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).not_to be base_node
      end
    end
  end

  describe '#around_terminator!' do
    subject { node.terminate?(output, *inputs, **options) }

    include_context 'for around_terminator'

    let(:node) do
      base_node
        .around_terminator!(&callback1)
        .around_terminator!(&callback2)
    end

    context 'when block is called' do
      let(:callback1) { proc { |*, **, &block| block.call == false } }
      let(:callback2) { proc { |*, **, &block| block.call == true } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).to be base_node
      end
    end

    context 'when block is not called' do
      let(:callback1) { proc { |*, **| true } }
      let(:callback2) { proc { |*, **, &block| block.call == true } }

      it { is_expected.to eq true }

      it 'should have different IDs for base_node and node' do
        subject
        expect(node).to be base_node
      end
    end
  end

  shared_context 'for after_terminator' do
    let(:base_node) do
      CallableTree::Node::External::Builder
        .new
        .caller { |input, **| input }
        .terminator { |output, *, **| output == 0 }
        .hookable
        .build
        .new
    end

    let(:output) { 0 }
    let(:inputs) { [1, 2, 3] }
    let(:options) { { x: 1, y: 2 } }

    let(:callback1) { proc { |terminated, **| !terminated } }
    let(:callback2) { proc { |terminated, **| !terminated } }

    before do
      expect(callback1).to receive(:call).with(true, **options, _node_: node).and_call_original
      expect(callback2).to receive(:call).with(false, **options, _node_: node).and_call_original
    end
  end

  describe '#after_terminator' do
    subject { node.terminate?(output, *inputs, **options) }

    include_context 'for after_terminator'

    let(:node) do
      base_node
        .after_terminator(&callback1)
        .after_terminator(&callback2)
    end

    it { is_expected.to eq true }

    it 'should have different IDs for base_node and node' do
      subject
      expect(node).not_to be base_node
    end
  end

  describe '#after_terminator!' do
    subject { node.terminate?(output, *inputs, **options) }

    include_context 'for after_terminator'

    let(:node) do
      base_node
        .after_terminator!(&callback1)
        .after_terminator!(&callback2)
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
        .before_terminator(&:before_callback)
        .around_terminator(&:around_callback)
        .after_terminator(&:after_callback)
    end

    it 'should generate new array' do
      expect(subject.before_terminator_callbacks).not_to be node.before_terminator_callbacks
      expect(subject.around_terminator_callbacks).not_to be node.around_terminator_callbacks
      expect(subject.after_terminator_callbacks).not_to be node.after_terminator_callbacks
    end
  end
end
