# frozen_string_literal: true

require 'active_job' unless defined?(::ActiveJob)

module Readymade
  class BackgroundJob < ::ActiveJob::Base
    queue_as { self.arguments[0].dig(:queue_as) || self.arguments[0].dig(:job_options, :queue_as) || :default }

    def perform(**args)
      args.delete(:class_name).to_s.constantize.send(callable_method, **args)
    end

    private

    def callable_method
      :call
    end
  end
end
