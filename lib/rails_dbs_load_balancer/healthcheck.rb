module Healthcheck
    cattr_reader :down_times

    def mark_failed(db_index)
        down_times[db_index] = Time.now.to_i + 300 # TODO: remove hardcode
    end

    def available?(db_index)
        down_times[db_index] < Time.now.to_i
    end

    private def down_times
       @@down_times ||= {}
       @@down_times["#{@key}:dt"] ||= Hash.new(0)
    end
end
