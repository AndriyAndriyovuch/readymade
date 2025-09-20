# frozen_string_literal: true

require 'readymade/model/api_attachable'
require 'readymade/model/filterable'
require 'readymade/controller/serialization'
require 'readymade/background_job'
require 'readymade/background_bang_job'
require 'readymade/action'
require 'readymade/form'
require 'readymade/instant_form'
require 'readymade/operation'
require 'readymade/response'
require 'readymade/version'

module Readymade
  class Error < StandardError; end

  class << self
    attr_accessor :config

    def configure
      self.config ||= Config.new
      yield(config)
    end
  end

  class Config
    attr_reader :lock_jobs, :lock_type, :lock_ttl, :locked_queues

    ALLOWED_LOCK_TYPES = %i[until_executing until_executed until_expired until_and_while_executing while_executing].freeze

    def initialize
      @lock_jobs = false
      @lock_type = :until_executed
      @lock_ttl = 1.days
      @locked_queues = [:default]
    end

    def lock_jobs=(bool)
      raise ArgumentError, 'Lock jobs must be a boolean' unless [TrueClass, FalseClass, NilClass].include?(bool.class)

      @lock_jobs = bool
    end

    def lock_type=(lock_type)
      raise ArgumentError, 'Lock type must be a symbol' unless lock_type.is_a?(symbol)
      raise ArgumentError, "Lock type must be one of: #{ALLOWED_LOCK_TYPES}" unless ALLOWED_LOCK_TYPES.include?(lock_type)

      @lock_type = lock_type
    end

    def lock_ttl=(ttl)
      raise ArgumentError, 'Lock ttl must be an integer' unless ttl.is_a?(Integer)

      @lock_ttl = ttl
    end

    def locked_queues=(queues)
      raise ArgumentError, 'Locked queues must be an array' unless queues.is_a?(Array)

      @locked_queues = queues
    end

    def lock_jobs?
      lock_jobs
    end
  end
end

initializer = './config/initializers/readymade.rb'
require initializer if File.exist?(initializer)
