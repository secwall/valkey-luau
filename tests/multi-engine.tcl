start_server {tags {"multi-engine"} overrides {luau.engine-name "lua,luau,foobar"}} {
    test {Engine registered with 'lua' name} {
        r eval "#!lua
return _VERSION" 0
    } {Luau}

    test {Engine registered with 'luau' name} {
        r eval "#!luau
return _VERSION" 0
    } {Luau}

    test {Engine registered with 'foobar' name} {
        r eval "#!foobar
return _VERSION" 0
    } {Luau}

    test {SCRIPT LOAD and EVALSHA with 'lua' engine} {
        set sha [r script load "#!lua
return 'test-lua'"]
        r evalsha $sha 0
    } {test-lua}

    test {SCRIPT LOAD and EVALSHA with 'luau' engine} {
        set sha [r script load "#!luau
return 'test-luau'"]
        r evalsha $sha 0
    } {test-luau}

    test {SCRIPT LOAD and EVALSHA with 'foobar' engine} {
        set sha [r script load "#!foobar
return 'test-foobar'"]
        r evalsha $sha 0
    } {test-foobar}

    test {'lua' 'luau' 'foobar' all point at the same engine} {
        set a [r eval "#!lua
return _VERSION" 0]
        set b [r eval "#!luau
return _VERSION" 0]
        set c [r eval "#!foobar
return _VERSION" 0]
        assert_equal $a $b
        assert_equal $b $c
    }
}
