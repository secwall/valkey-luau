proc get_function_code {engine library_name function_name body} {
    return [format "#!%s name=%s\nserver.register_function('%s', function(KEYS, ARGV)\n %s \nend)" $engine $library_name $function_name $body]
}

start_server {tags {"function-coexistence"} overrides {luau.engine-name "luau"}} {
    test {Both engines can be used simultaneously} {
        r function flush
        r function load [get_function_code lua simlib1 from_lua {return 'from-Lua'}]
        r function load [get_function_code luau simlib2 from_luau {return 'from-Luau'}]

        assert_equal [r fcall from_lua 0] {from-Lua}
        assert_equal [r fcall from_luau 0] {from-Luau}
    }

    test {Both engines can interact with the same keys} {
        r function flush
        r function load [get_function_code lua writelib lua_write {return server.call('set', KEYS[1], ARGV[1])}]
        r function load [get_function_code luau readlib luau_read {return server.call('get', KEYS[1])}]

        r fcall lua_write 1 mykey hello
        assert_equal [r fcall luau_read 1 mykey] {hello}
    }

    test {Built-in Lua function reads data written by a Luau function} {
        r function flush
        r function load [get_function_code luau wlib3 luau_set {return server.call('set', KEYS[1], ARGV[1])}]
        r function load [get_function_code lua rlib3 lua_get {return server.call('get', KEYS[1])}]

        r fcall luau_set 1 crosskey2 crossvalue2
        assert_equal [r fcall lua_get 1 crosskey2] {crossvalue2}
    }

    test {An error in one engine does not affect the other} {
        r function flush
        r function load [get_function_code lua oklib lua_ok {return 'lua-ok'}]
        r function load [get_function_code luau errlib luau_err {return server.call('invalid_command')}]
        r function load [get_function_code luau oklib2 luau_ok {return 'luau-ok'}]

        catch {r fcall luau_err 0} e
        assert_match {*} $e

        assert_equal [r fcall lua_ok 0] {lua-ok}
        assert_equal [r fcall luau_ok 0] {luau-ok}
    }

    test {Both engines can use cjson in functions} {
        r function flush
        r function load [get_function_code lua jsonlib1 lua_json {return cjson.encode({a = 1})}]
        r function load [get_function_code luau jsonlib2 luau_json {return cjson.encode({a = 1})}]

        assert_match {*"a":1*} [r fcall lua_json 0]
        assert_match {*"a":1*} [r fcall luau_json 0]
    }

    test {Library state persists across FCALLs} {
        r function flush
        r function load "#!luau name=statelib
local counter = 0
server.register_function('bump', function(KEYS, ARGV)
  counter = counter + 1
  return counter
end)"
        assert_equal [r fcall bump 0] 1
        assert_equal [r fcall bump 0] 2
        assert_equal [r fcall bump 0] 3
    }
}
