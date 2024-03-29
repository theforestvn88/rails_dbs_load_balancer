require_relative "./algo"

module LoadBalancer
    class RoundRobin < Algo
        cattr_accessor :currents
        
        def warm_up
            @@currents ||= ::Hash.new(0)
        end

        def next_db(**options)
            @current = cas_current
            return @database_configs[@current], @current if db_available?(@current)
            
            next_dbs = (@current+1...@current+@database_configs.size).map { |i| i % @database_configs.size }
            fail_over(next_dbs)
        end

        private

            CAS_NEXT_SCRIPT = <<~LUA
                local curr = redis.call("get", KEYS[1])
                if curr then
                    local next = (tonumber(curr) + 1) % ARGV[1]
                    redis.call("set", KEYS[1], next)
                    return next
                else
                    redis.call("set", KEYS[1], 0)
                    return 0
                end
            LUA
            CAS_NEXT_SCRIPT_SHA1 = ::Digest::SHA1.hexdigest CAS_NEXT_SCRIPT

            def current_cached_key
                "#{@key}:rr:current"
            end

            def cas_current
                return local_current unless redis_available?
                eval_lua_script(CAS_NEXT_SCRIPT, CAS_NEXT_SCRIPT_SHA1, [current_cached_key], [@database_configs.size])
            rescue => error
                # in case of redis failed
                mark_redis_down if error.is_a?(Redis::CannotConnectError)
                # random local server current
                @@currents[current_cached_key] = rand(0...@database_configs.size)
            end

            def local_current
                @@currents[current_cached_key] = (@@currents[current_cached_key] + 1) % @database_configs.size
            end
    end
end
