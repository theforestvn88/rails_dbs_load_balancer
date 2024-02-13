require "active_support"
require_relative "./load_balancer/round_robin"
require_relative "./load_balancer/least_connection"

module LoadBalancer
    extend ::ActiveSupport::Concern

    mattr_reader :lb, default: {}

    module ClassMethods
        def load_balancing(name, db_configs, algorithm: :round_robin, redis:)
            lb_algo_clazz = "LoadBalancer::#{algorithm.to_s.classify}".constantize
            LoadBalancer.lb[name] = {
                clazz: lb_algo_clazz,
                db_configs: db_configs,
                redis: redis,
                key: name
            }
        end

        def connected_through_load_balancer(name, &blk)
            raise ArgumentError, "not found #{name} load balancer" unless LoadBalancer.lb.has_key?(name)
            
            configs = LoadBalancer.lb[name]
            lb = configs[:clazz].new(configs[:db_configs], redis: configs[:redis], key: configs[:key])
            lb.connected_to_next_db(&blk)
        end
    end
end
