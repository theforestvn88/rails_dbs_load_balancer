module LoadBalancer
    class Algo
        include RedisLua
        attr_reader :database_configs, :redis, :key

        def initialize(database_configs, redis:, key:)
            @database_configs = database_configs
            @redis = redis
            @key = key
        end

        def warm_up
        end

        def next_db(**options)
            raise NotImplementedError, ""
        end

        def connected_to_next_db(**options)
            ::ActiveRecord::Base.connected_to(**next_db(**options)) do
                yield
            end
        end
    end
end
