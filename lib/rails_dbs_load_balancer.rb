# frozen_string_literal: true

require_relative "rails_dbs_load_balancer/version"
require_relative "rails_dbs_load_balancer/load_balancer"

module RailsDbsLoadBalancer
  class Error < StandardError; end

  def setup
    yield(LoadBalancer)
  end
  module_function :setup
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, LoadBalancer)
end
