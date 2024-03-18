require_relative "./algo"

module LoadBalancer
    class Hash < Algo
        def next_db(**options)
            db_index = hash_to_index(**options)
            return @database_configs[db_index], db_index if db_available?(db_index)
            
            # fail over
            next_dbs = (db_index+1...db_index+@database_configs.size).map { |i| i % @database_configs.size }
            fail_over(next_dbs)
        end

        private

        def hash_to_index(**options)
            rand(0...@database_configs.size) if options[:source].nil?

            h = options[:hash_func]&.respond_to?(:call) ? options[:hash_func].call(options[:source]) : hashcode(options[:source])
            h % @database_configs.size
        end

        def hashcode(source)
            # NOTE:
            # From Ruby 2.0 initialize MurmurHash using a random seed value which is reinitialized each time you restart Ruby.
            # So `source.hash` will not be deterministic across servers.
            # Therefore, this method uses java hashcode algorithm (Apache Harmony) instead.
            h = 0
            multipler = 1
            (source.size-1).downto(0) do |i|
                h = source[i].ord * multipler
                multipler = (multipler << 5) - multipler
            end
            h
        end
    end
end
