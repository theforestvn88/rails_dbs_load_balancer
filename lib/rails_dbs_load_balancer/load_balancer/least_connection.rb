require_relative "../min_heap"

module LoadBalancer
    class LeastConnection < Algo
        cattr_reader :mutexes, default: {}
        cattr_reader :leasts, default: {}

        def warm_up
            (@@mutexes[db_conns_pq_key] ||= Mutex.new).synchronize do
                begin
                    unless @redis.exists?(db_conns_pq_key)
                        @database_configs.size.times do |i|
                            @redis.zincrby(db_conns_pq_key, 1, i)
                        end
                    end
                rescue => e
                    # p e
                ensure
                    return if @@leasts.has_key?(db_conns_pq_key)

                    @@leasts[db_conns_pq_key] = MinHeap.new
                    @database_configs.size.times do |i|
                        @@leasts[db_conns_pq_key].push([i, 1])
                    end
                end
            end
        end

        def next_db
            @database_configs[least.to_i]
        end

        def connected_to_next_db
            super
            decrease
        end

        private
            
            CAS_TOP_SCRIPT = <<~LUA
                local top = unpack(redis.call("zrange", KEYS[1], 0, 0))
                redis.call("zincrby", KEYS[1], 1, top)
                return top
            LUA
            CAS_TOP_SCRIPT_SHA1 = ::Digest::SHA1.hexdigest CAS_TOP_SCRIPT

            def db_conns_pq_key
                "#{@key}:pq"
            end

            def least
                return local_least if @redis.nil?
                @least ||= eval_lua_script(CAS_TOP_SCRIPT, CAS_TOP_SCRIPT_SHA1, [db_conns_pq_key], [])
            rescue
                local_least
            end

            def local_least
                x, count = @@leasts[db_conns_pq_key].pop
                @@leasts[db_conns_pq_key].push([x, count + 1])
                x
            end

            def decrease
                unless @redis.nil?
                    @redis.zincrby(db_conns_pq_key, -1, least)
                else
                    @@leasts[db_conns_pq_key].update(least, -1)
                end
            end
    end
end
