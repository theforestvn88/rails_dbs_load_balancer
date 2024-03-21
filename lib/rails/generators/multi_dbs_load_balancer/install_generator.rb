# frozen_string_literal: true
require "rails/generators"

module MultiDbsLoadBalancer
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)
    
    def create_initializer
      copy_file "initializer.rb", "config/initializers/multi_dbs_load_balancer.rb"
    end
  end
end
