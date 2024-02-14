require "active_support"
require 'digest'
require_relative "./redis_lua"
require_relative "./distribute_lock"
require_relative "./load_balancer/round_robin"

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

            DistributeLock.new(redis).synchronize(name) do
                lb = lb_algo_clazz.new(db_configs, redis: redis, key: name)
                lb.warm_up
            end
        end

        def connected_through_load_balancer(name, &blk)
            raise ArgumentError, "not found #{name} load balancer" unless LoadBalancer.lb.has_key?(name)
            
            configs = LoadBalancer.lb[name]
            lb = configs[:clazz].new(configs[:db_configs], redis: configs[:redis], key: configs[:key])
            lb.connected_to_next_db(&blk)
        end
    end
end
