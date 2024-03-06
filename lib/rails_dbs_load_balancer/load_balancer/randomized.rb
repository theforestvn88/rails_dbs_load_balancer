require_relative "./algo"

module LoadBalancer
    class Randomized < Algo
        def next_db(**options)
            r = random_index
            return @database_configs[r], r if available?(r)

            next_dbs = (r+1...r+@database_configs.size).map { |i| i % @database_configs.size }
            fail_over(next_dbs)
        end

        private

            def random_index
                rand(0...@database_configs.size)
            end
    end
end
