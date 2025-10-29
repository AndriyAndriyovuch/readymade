# frozen_string_literal: true

Readymade.configure do |config|
  # Change to true to enable job locking
  config.lock_jobs = false

  # Define lock strategy
  # Strategy	                    The job is locked	              The job is unlocked
  #
  # until_executing	              when pushed to the queue      	when processing starts
  # until_executed	              when pushed to the queue      	when the job is processed successfully
  # until_expired	                when pushed to the queue      	when the lock is expired
  # until_and_while_executing	    when pushed to the queue      	when processing starts a runtime lock is acquired to prevent simultaneous jobs
  # while_executing	              when processing starts        	when the job is processed with any result including an error

  # config.lock_type = :until_executed

  # new jobs with the same args will be logged within 1.day or until existing one is being executing
  # config.lock_ttl = 1.day

  # Array of queues to apply job locking to
  # config.locked_queues = [:default]
end
