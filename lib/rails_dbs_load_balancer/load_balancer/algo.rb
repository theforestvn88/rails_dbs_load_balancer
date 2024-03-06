module LoadBalancer
    class Algo
        include RedisLua
        include Healthcheck
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

        def after_connected
        end

        def after_executed
        end

        def connected_to_next_db(**options, &blk)
            candidate_db, db_index = next_db(**options)
            raise LoadBalancer::NotFoundDbError if candidate_db.nil?

            ::ActiveRecord::Base.connected_to(**candidate_db) do
                after_connected
                blk.call
            end
        rescue ActiveRecord::AdapterError
            mark_failed(db_index)
            @should_retry = true
        ensure
            after_executed
            if @should_retry
                @should_retry = false
                connected_to_next_db(**options, &blk)
            end
        end

        def fail_over(next_choices)
            candidate = next_choices.find do |i| 
                available?(i) 
            end

            if candidate
                [@database_configs[candidate], candidate]
            else
                [nil, -1]
            end
        end
    end
end
