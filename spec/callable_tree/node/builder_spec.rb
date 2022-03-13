# frozen_string_literal: true

RSpec.describe CallableTree::Node::Builder do
  describe '#build' do
    let(:node_class) do
      ::Class
        .new do
          include CallableTree::Node::Builder

          def validate(matcher:, caller:, terminater:)
            true
          end
        end
        .new
        .hookable(hookable)
        .build(node_type: [
          CallableTree::Node::Internal,
          CallableTree::Node::External
        ].sample)
    end

    context '#new' do
      subject { node_class.new }
      let(:hookable) { [true, false].sample }
      it { is_expected.to be_a ::CallableTree::Node }

      context 'hookable: true' do
        let(:hookable) { true }

        it { is_expected.to respond_to(:before_call) }
        it { is_expected.to respond_to(:around_call) }
        it { is_expected.to respond_to(:after_call) }
      end

      context 'hookable: false' do
        let(:hookable) { false }

        it { is_expected.not_to respond_to(:before_call) }
        it { is_expected.not_to respond_to(:around_call) }
        it { is_expected.not_to respond_to(:after_call) }
      end
    end
  end
end
