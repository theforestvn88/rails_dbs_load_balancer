require_relative "./algo"

module LoadBalancer
    class IpHash < Algo
        def next_db(**options)
            @database_configs[ip_hash_to_index(**options)]
        end

        private

        def ip_hash_to_index(**options)
            rand(0...@database_configs.size) if options[:ip].nil?

            h = hashcode(options[:ip])
            h % @database_configs.size
        end

        def hashcode(str)
            # NOTE:
            # Ruby 1.9 and Ruby 2.0 initialize MurmurHash using a random seed value which is reinitialized each time you restart Ruby.
            str.hash
        end
    end
end
