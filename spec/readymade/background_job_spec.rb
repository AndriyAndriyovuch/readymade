# frozen_string_literal: true

require 'byebug'
RSpec.describe Readymade::BackgroundJob do
  class Dummy < Readymade::Action
  end

  let(:dummy_class) { Dummy }
  let(:args) do
    {
      string: 'some string',
      integer: rand(1..10),
      array: Array,
    }
  end

  describe '#perform_later' do
    context 'without queue name' do
      it 'creates instance variables from arguments' do
        allow_any_instance_of(Dummy).to receive(:call_async).with(**args)

        res = described_class.perform_later(**args.merge!(class_name: dummy_class.name))

        expect(res.job_id.size).to eq(36)
        expect(res.queue_name).to eq('default')
      end
    end

    context 'with queue name' do
      it 'creates instance variables from arguments' do
        allow_any_instance_of(Dummy).to receive(:call_async).with(**args.merge!(queue_as: :test))

        res = described_class.perform_later(**args.merge!(class_name: dummy_class.name))

        expect(res.job_id.size).to eq(36)
        expect(res.queue_name).to eq('test')
      end

      context 'when as job options provided' do
        it 'uses the provided job options' do
          job_options = { queue_as: :test }
          allow_any_instance_of(Dummy).to receive(:call_async).with(**args.merge!(job_options: job_options))

          res = described_class.perform_later(**args.merge!(class_name: dummy_class.name, job_options: job_options))
          expect(res.job_id.size).to eq(36)
          expect(res.queue_name).to eq('test')
          expect(res.arguments.first[:job_options]).to eq(job_options)
        end
      end
    end


    context 'when queue lock has been applied' do
      let(:unique_job_class) do
        Class.new(described_class) do
          def self.name
            'TestUniqueBackgroundJob'
          end
        end
      end

      context 'when lock_jobs is true' do
        before do
          allow(Readymade).to receive_message_chain(:config, :lock_jobs?).and_return(true)
          allow(Readymade).to receive_message_chain(:config, :lock_type).and_return(:until_executed)
          allow(Readymade).to receive_message_chain(:config, :lock_ttl).and_return(5)
          allow(Readymade).to receive_message_chain(:config, :locked_queues).and_return([:default])

          unique_job_class.apply_uniqueness!
        end

        it 'creates instance variables from arguments' do
          allow_any_instance_of(Dummy).to receive(:call_async).with(**args)

          res = unique_job_class.perform_later(**args.merge!(class_name: dummy_class.name))
          res2 = unique_job_class.perform_later(**args.merge!(class_name: dummy_class.name))

          expect([res, res2].reject(&:!).first.job_id.size).to eq(36)
          expect([res, res2].reject(&:!).first.queue_name).to eq('default')

          expect([res, res2].select(&:!).first).to be_falsey
        end
      end

      context 'when lock_jobs is false' do
        before do
          allow(Readymade).to receive_message_chain(:config, :lock_jobs?).and_return(false)
          unique_job_class.apply_uniqueness!
        end

        it 'creates instance variables from arguments' do
          allow_any_instance_of(Dummy).to receive(:call_async).with(**args)

          res3 = unique_job_class.perform_later(**args.merge!(class_name: dummy_class.name))
          res4 = unique_job_class.perform_later(**args.merge!(class_name: dummy_class.name))

          expect(res3.job_id.size).to eq(36)
          expect(res3.queue_name).to eq('default')

          expect(res4.job_id.size).to eq(36)
          expect(res4.queue_name).to eq('default')
        end
      end
    end
  end
end