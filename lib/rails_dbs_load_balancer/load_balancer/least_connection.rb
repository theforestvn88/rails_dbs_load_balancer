require_relative "../min_heap"

module LoadBalancer
    class LeastConnection < Algo
        cattr_reader :mutexes, default: {}
        cattr_reader :leasts, default: {}

        def warm_up
            pq_mutex.synchronize do
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
                        @@leasts[db_conns_pq_key].push([1, i])
                    end
                end
            end
        end

        def next_db(**options)
            @least_db_index = top_least
            return @database_configs[@least_db_index], @least_db_index if available?(@least_db_index)
            
            # fail over
            fail_over(next_dbs)
        end

        def after_connected
            increase
        end

        def after_executed
            decrease
        end

        private
            
            # CAS_TOP_SCRIPT = <<~LUA
            #     local top = unpack(redis.call("zrange", KEYS[1], 0, 0))
            #     redis.call("zincrby", KEYS[1], 1, top)
            #     return top
            # LUA
            # CAS_TOP_SCRIPT_SHA1 = ::Digest::SHA1.hexdigest CAS_TOP_SCRIPT

            def db_conns_pq_key
                "#{@key}:lc:pq"
            end

            def pq_mutex
                @@mutexes[db_conns_pq_key] ||= Mutex.new
            end

            def top_least
                # eval_lua_script(CAS_TOP_SCRIPT, CAS_TOP_SCRIPT_SHA1, [db_conns_pq_key], [])
                @redis.zrange(db_conns_pq_key, 0, 0).first.to_i
            rescue
                local_least(:extract)
            end

            def local_least(action = :extract)
                pq_mutex.synchronize do
                    case action
                    when :extract
                        count, x = @@leasts[db_conns_pq_key].peak
                        x
                    when :decrease
                        @@leasts[db_conns_pq_key].decrease(@least_db_index, 1) if @least_db_index
                    when :increase
                        @@leasts[db_conns_pq_key].increase(@least_db_index, 1) if @least_db_index
                    end
                end
            end

            def decrease
                return unless @least_db_index

                @redis.zincrby(db_conns_pq_key, -1, @least_db_index)
            rescue
                local_least(:decrease)
            end

            def increase
                return unless @least_db_index

                @redis.zincrby(db_conns_pq_key, 1, @least_db_index)
            rescue
                local_least(:increase)
            end

            def next_dbs
                @redis.zrange(db_conns_pq_key, 0, -1).map(&:to_i)
            rescue
                @@leasts[db_conns_pq_key].order
            end
    end
end
