# frozen_string_literal: true

RSpec.describe Readymade::Config do
  describe 'configure' do
    context 'with valid values' do
      context 'when no configuration has been set' do

        before do
          Readymade.configure do |config|
            # nothing
          end
        end

        it 'does not change anything' do
          expect(Readymade.config.lock_jobs).to be_falsey
          expect(Readymade.config.lock_type).to eq(:until_executed)
          expect(Readymade.config.lock_ttl).to eq(1.day)
          expect(Readymade.config.locked_queues).to eq([:default])
        end
      end

      context 'when configuration has been set' do
        before do
          Readymade.configure do |config|
            config.lock_jobs = true
            config.lock_type = :while_executing
            config.lock_ttl = 1.week
            config.locked_queues = [:mailers]
          end
        end

        it 'changes configuration' do
          expect(Readymade.config.lock_jobs).to be_truthy
          expect(Readymade.config.lock_type).to eq(:while_executing)
          expect(Readymade.config.lock_ttl).to eq(1.week)
          expect(Readymade.config.locked_queues).to eq([:mailers])
        end
      end
    end
  end

  context 'with invalid values' do
    context 'when lock_jobs is not boolean' do
      it 'raises an error during configuration' do
        expect do
          Readymade.configure do |config|
            config.lock_jobs = 'true'
          end
        end.to raise_error(ArgumentError, 'Lock jobs must be a boolean')
      end
    end

    context 'when lock_type is not a symbol' do
      it 'raises an error during configuration' do
        expect do
          Readymade.configure do |config|
            config.lock_type = 'until_executed'
          end
        end.to raise_error(ArgumentError, 'Lock type must be a symbol')
      end
    end

    context 'when lock_type is not allowed' do
      it 'raises an error during configuration' do
        expect do
          Readymade.configure do |config|
            config.lock_type = :invalid
          end
        end.to raise_error(ArgumentError, "Lock type must be one of: #{described_class::ALLOWED_LOCK_TYPES}")
      end
    end

    context 'when lock_ttl is not an integer' do
      it 'raises an error during configuration' do
        expect do
          Readymade.configure do |config|
            config.lock_ttl = '1.week'
          end
        end.to raise_error(ArgumentError, 'Lock ttl must be an integer')
      end
    end

    context 'when locked_queues is not array' do
      it 'raises an error during configuration' do
        expect do
          Readymade.configure do |config|
            config.locked_queues = :mailers
          end
        end.to raise_error(ArgumentError, 'Locked queues must be an array')
      end
    end
  end
end
