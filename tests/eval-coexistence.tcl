start_server {tags {"eval-coexistence"} overrides {luau.engine-name "luau"}} {
    test {No-shebang EVAL routes to built-in Lua} {
        assert_match {Lua 5.*} [r eval "return _VERSION" 0]
    }

    test {lua shebang routes to built-in Lua} {
        assert_match {Lua 5.*} [r eval "#!lua
return _VERSION" 0]
    }

    test {luau shebang routes to Luau} {
        r eval "#!luau
return _VERSION" 0
    } {Luau}

    test {LUAU (uppercase) routes to Luau} {
        r eval "#!LUAU
return _VERSION" 0
    } {Luau}

    test {Luau-only globals are absent from the built-in engine} {
        assert_equal [r eval "#!luau
return type(bit32)" 0] {table}
        catch {r eval "return bit32.band(1,1)" 0} e
        assert_match {*global variable 'bit32'*} $e
    }

    test {lua shebang: server.call works in built-in Lua} {
        r set coex_probe_key coex_probe_val
        r eval "#!lua
return server.call('get', KEYS\[1\])" 1 coex_probe_key
    } {coex_probe_val}

    test {SCRIPT LOAD no-shebang registers with built-in Lua engine} {
        set sha [r script load "return _VERSION"]
        assert_match {Lua 5.*} [r evalsha $sha 0]
    }

    test {SCRIPT LOAD luau registers with the Luau engine} {
        set sha [r script load "#!luau
return _VERSION"]
        r evalsha $sha 0
    } {Luau}

    test {EVALSHA reuses the engine chosen at SCRIPT LOAD time} {
        set sha_luau [r script load "#!luau
return _VERSION"]
        set sha_lua  [r script load "#!lua
return _VERSION"]
        assert_equal [r evalsha $sha_luau 0] {Luau}
        assert_match {Lua 5.*} [r evalsha $sha_lua 0]
        assert_equal [r evalsha $sha_luau 0] {Luau}
    }

    test {EVAL luau: server.call SET and GET work} {
        r eval "#!luau
server.call('set', KEYS\[1\], ARGV\[1\])
return server.call('get', KEYS\[1\])" 1 coex_luau_key coex_luau_val
    } {coex_luau_val}

    test {Luau script reads a key written by built-in Lua} {
        r eval "#!lua
return server.call('set', KEYS\[1\], ARGV\[1\])" 1 shared_coex_key lua-wrote-this
        r eval "#!luau
return server.call('get', KEYS\[1\])" 1 shared_coex_key
    } {lua-wrote-this}

    test {Built-in Lua reads a key written by Luau} {
        r eval "#!luau
return server.call('set', KEYS\[1\], ARGV\[1\])" 1 shared_coex_key2 luau-wrote-this
        r eval "#!lua
return server.call('get', KEYS\[1\])" 1 shared_coex_key2
    } {luau-wrote-this}

    test {An error in one engine does not affect the other} {
        catch {r eval "#!luau
return server.call('nosuchcommand')" 0} e
        assert_match {*Unknown command*} $e
        assert_equal [r eval "#!luau
return 'luau-ok'" 0] {luau-ok}
        assert_match {Lua 5.*} [r eval "return _VERSION" 0]
    }

    test {SCRIPT EXISTS sees scripts from both engines} {
        set a [r script load "#!luau
return 'exists-luau'"]
        set b [r script load "#!lua
return 'exists-lua'"]
        assert_equal [r script exists $a $b] {1 1}
    }

    test {SCRIPT FLUSH removes scripts from both engines} {
        set a [r script load "#!luau
return 'flush-luau'"]
        set b [r script load "#!lua
return 'flush-lua'"]
        r script flush
        assert_equal [r script exists $a $b] {0 0}
        catch {r evalsha $a 0} e
        assert_match {NOSCRIPT*} $e
    }

    test {Both engines can use cjson} {
        assert_match {*"a":1*} [r eval "#!luau
return cjson.encode({a = 1})" 0]
        assert_match {*"a":1*} [r eval "#!lua
return cjson.encode({a = 1})" 0]
    }
}
