# frozen_string_literal: true

require 'active_job' unless defined?(::ActiveJob)

module Readymade
  class BackgroundJob < ::ActiveJob::Base
    queue_as { self.arguments[0].dig(:queue_as) || self.arguments[0].dig(:job_options, :queue_as) || :default }

    class << self
      def apply_uniqueness!
        return unless Readymade.config&.lock_jobs?

        begin
          require "active_job/uniqueness"

          unique Readymade.config.lock_type,
                 lock_ttl: Readymade.config.lock_ttl,
                 on_conflict: ->(job) { handle_duplication(job) }
        rescue LoadError
          warn uniqueness_not_loaded_warning
        end
      end

      def handle_duplication(job)
        return if Readymade.config.locked_queues.include?(job.queue_name.to_sym)

        ActiveJob::Uniqueness.unlock!(job_class_name: job.class.name)
      end

      def uniqueness_not_loaded_warning
        <<~MSG

          ======== READYMADE WARNING ========

          The `activejob-uniqueness` gem is not installed, but `lock_jobs` is enabled.
          Please add the following to your Gemfile:

              gem "activejob-uniqueness", "~> 0.4.0"

          ===================================

        MSG
      end

    end

    def perform(**args)
      args.delete(:class_name).to_s.constantize.send(callable_method, **args)
    end

    private

    def callable_method
      :call
    end
  end
end

if defined?(::ActiveSupport)
  ActiveSupport.on_load(:after_initialize) do
    Readymade::BackgroundJob.apply_uniqueness!
  end
end
