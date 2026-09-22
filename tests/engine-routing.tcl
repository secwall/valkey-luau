proc get_function_code {engine library_name function_name body} {
    return [format "#!%s name=%s\nserver.register_function('%s', function(KEYS, ARGV)\n %s \nend)" $engine $library_name $function_name $body]
}

start_server {tags {"engine-routing"}} {
    test {No-shebang EVAL routes to Luau (default engine)} {
        r eval "return _VERSION" 0
    } {Luau}

    test {#!lua shebang routes to Luau} {
        r eval "#!lua
return _VERSION" 0
    } {Luau}

    test {Luau-only globals are present} {
        assert_equal [r eval "return type(bit32)" 0] {table}
        assert_equal [r eval "return type(buffer)" 0] {table}
        assert_equal [r eval "return type(table.clone)" 0] {function}
    }

    test {FUNCTION with #!lua shebang uses Luau} {
        r function flush
        r function load [get_function_code lua lib_routing get_version {return _VERSION}]
        r fcall get_version 0
    } {Luau}

    test {server.* and redis.* aliases both work} {
        r set routing_key val
        set v1 [r eval "return server.call('GET', KEYS\[1\])" 1 routing_key]
        set v2 [r eval "return redis.call('GET', KEYS\[1\])" 1 routing_key]
        assert_equal $v1 $v2
        assert_equal $v1 {val}
    }
}
