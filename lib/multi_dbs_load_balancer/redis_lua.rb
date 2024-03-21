module RedisLua
    def eval_lua_script(script, sha1, *args, redis: @redis,**kwargs)
        redis.evalsha sha1, *args, **kwargs
    rescue ::Redis::CommandError => e
        if e.to_s =~ /^NOSCRIPT/
            redis.eval script, *args, **kwargs
        else
            raise
        end
    end
    module_function :eval_lua_script
end
