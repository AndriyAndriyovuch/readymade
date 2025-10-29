# frozen_string_literal: true

  module Readymade
    module Generators
      class InstallGenerator < Rails::Generators::Base
        desc 'Copy Readymade default files'
        source_root File.expand_path('templates', __dir__)

        def copy_config
          template 'config/initializers/readymade.rb'
        end
      end
    end
  end
