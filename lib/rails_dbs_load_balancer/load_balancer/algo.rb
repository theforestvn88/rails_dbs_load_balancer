module LoadBalancer
    class Algo
        attr_reader :database_configs, :redis, :key

        def initialize(database_configs, redis:, key:)
            @database_configs = database_configs
            @redis = redis
            @key = key
        end

        def eval_lua_script(script, sha1, *args, **kwargs)
            @redis.evalsha sha1, *args, **kwargs
        rescue ::Redis::CommandError => e
            if e.to_s =~ /^NOSCRIPT/
                @redis.eval script, *args, **kwargs
            else
                raise
            end
        end
    end
end
