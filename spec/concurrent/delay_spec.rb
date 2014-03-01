require 'spec_helper'
require_relative 'dereferenceable_shared'

module Concurrent

  describe Delay do

    context 'behavior' do

      # dereferenceable

      def dereferenceable_subject(value, opts = {})
        Delay.new(opts){ value }.force
      end

      it_should_behave_like :dereferenceable
    end

    context 'obligation' do

      let!(:fulfilled_value) { 10 }
      let!(:rejected_reason) { StandardError.new('mojo jojo') }

      let(:pending_subject) do
        Delay.new{ fulfilled_value }
      end

      let(:fulfilled_subject) do
        Delay.new{ fulfilled_value }.force
      end

      let(:rejected_subject) do
        Delay.new{ raise rejected_reason }.force
      end

      context '#state' do

        it 'is :pending when first created' do
          f = pending_subject
          f.state.should == :pending
          f.should be_pending
        end

        it 'is :fulfilled when the handler completes' do
          f = fulfilled_subject
          f.state.should == :fulfilled
          f.should be_fulfilled
        end

        it 'is :rejected when the handler raises an exception' do
          f = rejected_subject
          f.state.should == :rejected
          f.should be_rejected
        end
      end

      context '#value' do

        it 'is nil when :rejected' do
          expected = rejected_subject.value
          expected.should be_nil
        end

        it 'is set to the return value of the block when :fulfilled' do
          expected = fulfilled_subject.value
          expected.should eq fulfilled_value
        end
      end

      context '#reason' do

        it 'is nil when :pending' do
          pending_subject.reason.should be_nil
        end

        it 'is nil when :fulfilled' do
          fulfilled_subject.reason.should be_nil
        end

        it 'is set to error object of the exception when :rejected' do
          rejected_subject.reason.should be_a(Exception)
          rejected_subject.reason.to_s.should =~ /#{rejected_reason}/
        end
      end
    end

    context '#initialize' do

      it 'sets the state to :pending' do
        Delay.new{ nil }.should be_pending
      end

      it 'raises an exception when no block given' do
        expect {
          Delay.new
        }.to raise_error(ArgumentError)
      end
    end

    context '#value' do

      let(:task){ proc{ nil } }

      it 'does not call the block before #value is called' do
        task.should_not_receive(:call).with(any_args)
        Delay.new(&task)
      end

      it 'calls the block when #value is called' do
        task.should_receive(:call).once.with(any_args).and_return(nil)
        Delay.new(&task).value
      end

      it 'only calls the block once no matter how often #value is called' do
        task.should_receive(:call).once.with(any_args).and_return(nil)
        delay = Delay.new(&task)
        5.times{ delay.value }
      end

      it 'blocks indefinitely when #value is called'
    end

    context '#force' do

      let(:task){ proc{ nil } }

      it 'calls the block if it has not been called' do
        task.should_receive(:call).once.with(any_args).and_return(nil)
        Delay.new(&task).force
      end

      it 'only calls the block once no matter how often it is called' do
        task.should_receive(:call).once.with(any_args).and_return(nil)
        delay = Delay.new(&task)
        5.times{ delay.force }
      end

      it 'returns self' do
        delay = Delay.new(&task)
        delay.force.should eq delay
      end
    end
  end
end
