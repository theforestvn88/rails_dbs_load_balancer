require_relative "../min_heap"

module LoadBalancer
    class LeastResponseTime < Algo
        cattr_reader :mutexes, default: {}
        cattr_reader :response_times, default: {}

        def warm_up
            pq_mutex.synchronize do
                begin
                    unless @redis.exists?(db_conns_pq_key)
                        @database_configs.size.times do |i|
                            @redis.zincrby(db_conns_pq_key, 0, i)
                        end
                    end
                rescue => e
                    # p e
                ensure
                    return if @@response_times.has_key?(db_conns_pq_key)

                    @@response_times[db_conns_pq_key] = MinHeap.new
                    @database_configs.size.times do |i|
                        @@response_times[db_conns_pq_key].push([0, i])
                    end
                end
            end
        end

        def next_db(**options)
            @database_configs[least.to_i]
        end

        def connected_to_next_db(**options)
            @start_time = Time.now
            super
            update_response_time(Time.now - @start_time)
        end

        private
            
            CAS_TOP_SCRIPT = <<~LUA
                local top = unpack(redis.call("zrange", KEYS[1], 0, 0))
                redis.call("zincrby", KEYS[1], 0.1, top)
                return top
            LUA
            CAS_TOP_SCRIPT_SHA1 = ::Digest::SHA1.hexdigest CAS_TOP_SCRIPT

            def db_conns_pq_key
                "#{@key}:lrt:pq"
            end

            def pq_mutex
                @@mutexes[db_conns_pq_key] ||= Mutex.new
            end

            def least
                @least ||= eval_lua_script(CAS_TOP_SCRIPT, CAS_TOP_SCRIPT_SHA1, [db_conns_pq_key], [])
            rescue
                @least ||= local_least
            end

            def local_least(action = :extract, **options)
                pq_mutex.synchronize do
                    case action
                    when :extract
                        t, x = @@response_times[db_conns_pq_key].pop
                        @@response_times[db_conns_pq_key].push([t + 0.1, x])
                        x
                    when :update_response_time
                        @@response_times[db_conns_pq_key].replace(@least, options[:time])
                    end
                end
            end

            def update_response_time(t)
                unless @redis.nil?
                    @redis.zadd(db_conns_pq_key, t, least)
                else
                    local_least(:update_response_time, time: t)
                end
            end
    end
end
