# frozen_string_literal: true

require 'active_job' unless defined?(::ActiveJob)
require 'active_job/uniqueness'
require 'pry-byebug'

module Readymade
  class BackgroundJob < ::ActiveJob::Base
    queue_as do
      if (q = self.arguments[0][:queue_as]).present?
        logger.warn "DEPRECATED: `queue_as` is deprecated. Use `job_options.queue_as` instead."
      end

      self.arguments[0].dig(:job_options, :queue_as).presence || q || 'default'
    end
    rescue_from StandardError, with: :handle_rescue_from

    class << self
      def apply_uniqueness!
        return unless Readymade.config.lock_jobs?

        unique Readymade.config.lock_type,
               lock_ttl: Readymade.config.lock_ttl,
               on_conflict: ->(job) { handle_duplication(job) }

      end

      def handle_duplication(job)
        return job.perform(*job.arguments) unless Readymade.config.locked_queues.include?(job.queue_name.to_sym)
      end
    end

    def perform(**args)
      args.delete(:class_name).to_s.constantize.send(:call, **args)
    end

    private

    def handle_rescue_from(exception)
      raise exception if job_options.blank? || job_options['discard_on'].blank?

      discard_on = job_options['discard_on'].map { |d| d['value'] }

      if discard_on.include?(exception.class.name)
        logger.warn "Discarding job due to deserialization error: #{exception.message}"
        # Discard the job without raising an error
      else
        logger.error "Job failed with deserialization error: #{exception.message}"
        raise exception
      end
    end

    private

    def job_options
      @job_options ||= self.instance_variable_get('@serialized_arguments')[0]['job_options'] || {}
    end
  end
end

if defined?(::ActiveSupport)
  ActiveSupport.on_load(:after_initialize) do
    Readymade::BackgroundJob.apply_uniqueness!
  end
end