require "active_support"
require_relative "./load_balancer/round_robin"

module LoadBalancer
    extend ::ActiveSupport::Concern

    mattr_reader :lb, default: {}

    module ClassMethods
        def load_balancing(name, db_configs, algorithm: :round_robin, redis:)
            lb_algo_clazz = "LoadBalancer::#{algorithm.to_s.classify}".constantize
            LoadBalancer.lb[name] = lb_algo_clazz.new(db_configs, redis: redis, key: name)
        end

        def connected_through_load_balancer(name)
            raise ArgumentError, "not found #{name} load balancer" unless LoadBalancer.lb.has_key?(name)
            
            db_config = LoadBalancer.lb[name].next
            ::ActiveRecord::Base.connected_to(**db_config) do
                yield
            end
        end
    end
end
