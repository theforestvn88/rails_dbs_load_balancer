require_relative "./algo"

module LoadBalancer
    class RoundRobin < Algo
        cattr_accessor :currents
        
        def next_db(**options)
            @current = cas_current
            return @database_configs[@current], @current if available?(@current)
            
            # fail over
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
                return local_current if @redis.nil?
                eval_lua_script(CAS_NEXT_SCRIPT, CAS_NEXT_SCRIPT_SHA1, [current_cached_key], [@database_configs.size])
            rescue
                # in case of redis failed
                # round-robin local server current
                local_current
            end

            def local_current
                @@currents ||= ::Hash.new(0)
                @@currents[current_cached_key] = ((@@currents[current_cached_key] || 0) + 1) % @database_configs.size
            end
    end
end
