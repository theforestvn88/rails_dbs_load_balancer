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
            @least_db_index = top_least.to_i
            return @database_configs[@least_db_index], @least_db_index if available?(@least_db_index)
            
            # fail over
            fail_over(next_dbs)
        end

        def after_connected
            @start_time = Time.now
        end

        def after_executed
            update_response_time(Time.now - @start_time) if @start_time
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

            def top_least
                eval_lua_script(CAS_TOP_SCRIPT, CAS_TOP_SCRIPT_SHA1, [db_conns_pq_key], [])
            rescue
                local_least
            end

            def local_least(action = :extract, **options)
                pq_mutex.synchronize do
                    case action
                    when :extract
                        t, x = @@response_times[db_conns_pq_key].peak
                        x
                    when :update_response_time
                        @@response_times[db_conns_pq_key].replace(@least_db_index, options[:time])
                    end
                end
            end

            def update_response_time(t)
                @redis.zadd(db_conns_pq_key, t, @least_db_index)
            rescue
                local_least(:update_response_time, time: t)
            end

            def next_dbs
                @redis.zrange(db_conns_pq_key, 0, -1).map(&:to_i)
            rescue
                @@response_times[db_conns_pq_key].order
            end
    end
end
