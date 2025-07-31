# frozen_string_literal: true

require 'active_job' unless defined?(::ActiveJob)

module Readymade
  class BackgroundBangJob < ::Readymade::BackgroundJob
    queue_as { self.arguments[0].dig(:queue_as) || self.arguments[0].dig(:job_options, :queue_as) || :default }

    private

    def callable_method
      :call!
    end
  end
end