module LoadBalancer
    class LeastConnection < Algo
        cattr_accessor :mutex

        def warm_up
            (@@mutex ||= Mutex.new).synchronize do
                unless @redis.exists?(db_conns_pq_key)
                    @database_configs.size.times do |i|
                        @redis.zincrby(db_conns_pq_key, 1, i)
                    end
                end
            end
        end

        def next_db
            @database_configs[least.to_i]
        end

        def connected_to_next_db
            super

            # decrease
            @redis.zincrby(db_conns_pq_key, -1, least)
        end

        private
            
            CAS_TOP_SCRIPT = <<~LUA
                local top = unpack(redis.call("zrange", KEYS[1], 0, 0))
                redis.call("zincrby", KEYS[1], 2, top)
                return top
            LUA
            CAS_TOP_SCRIPT_SHA1 = ::Digest::SHA1.hexdigest CAS_TOP_SCRIPT

            def db_conns_pq_key
                "#{@key}:pq"
            end

            def least
                @least ||= eval_lua_script(CAS_TOP_SCRIPT, CAS_TOP_SCRIPT_SHA1, [db_conns_pq_key], [])
            end
    end
end
