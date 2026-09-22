start_server {tags {"scripting-sandbox"}} {
    test {Creating a global raises the stock error} {
        catch {r eval "x = 1 return x" 0} e
        assert_match {*Attempt to modify a readonly table*} $e
    }

    test {Reading an unknown global raises the stock error} {
        catch {r eval "return nosuchvar" 0} e
        assert_match {*Script attempted to access nonexistent global variable 'nosuchvar'*} $e
    }

    test {Reading an unknown global from inside a function still raises} {
        catch {r eval "local function f() return nosuchglobal end return f()" 0} e
        assert_match {*nonexistent global variable 'nosuchglobal'*} $e
    }

    test {Reassigning KEYS hits the readonly check} {
        catch {r eval "KEYS = 1 return 'no'" 0} e
        assert_match {*readonly table*} $e
    }

    test {Assigning _G is rejected} {
        catch {r eval "_G = {} return 'no'" 0} e
        assert_match {*Attempt to modify a readonly table*} $e
    }

    test {Assigning the server table is rejected} {
        catch {r eval "redis = function() return 1 end return 'no'" 0} e
        assert_match {*Attempt to modify a readonly table*} $e
    }

    test {Shadowing a library errors as readonly} {
        catch {r eval "math = nil return 'no'" 0} e
        assert_match {*Attempt to modify a readonly table*} $e
    }

    test {Errors carry source and line like stock} {
        catch {r eval "local t = nil return t.x" 0} e
        assert_match {*script: on @user_script:*} $e
    }

    test {Standard libraries cannot be mutated} {
        catch {r eval "string.rep = nil return 'no'" 0} e
        assert_match {*readonly*} $e
    }

    test {The string metatable cannot be mutated} {
        catch {r eval "getmetatable('').__index = {} return 'no'" 0} e
        assert_match {*readonly*} $e
    }

    test {The server table cannot be mutated} {
        catch {r eval "server.call = nil return 'no'" 0} e
        assert_match {*readonly*} $e
    }

    test {rawset on _G is rejected} {
        catch {r eval "rawset(_G, 'leak', 1) return 'no'" 0} e
        assert_match {*readonly*} $e
    }

    test {Nothing leaks between invocations} {
        catch {r eval "leaked = 'yes'" 0} e
        assert_equal [r eval "return type(rawget(_G, 'leaked'))" 0] {nil}
        assert_equal [r eval "return type(rawget(string, 'leak'))" 0] {nil}
    }

    test {Locals are unaffected by the sandbox} {
        r eval "local x = 0 for i = 1, 10 do x = x + i end return x" 0
    } {55}

    test {KEYS and ARGV are present} {
        r eval "return KEYS\[1\] .. ':' .. ARGV\[1\]" 1 mykey myarg
    } {mykey:myarg}

    test {server.call works through the frozen environment} {
        r del sandbox_key
        r eval "server.call('SET', KEYS\[1\], ARGV\[1\]) return server.call('GET', KEYS\[1\])" 1 sandbox_key sandbox_val
    } {sandbox_val}

    test {redis alias is the same table as server} {
        r eval "return tostring(rawequal(server, redis))" 0
    } {true}

    test {math.random advances across invocations} {
        set a [r eval "return string.format('%.6f', math.random())" 0]
        set b [r eval "return string.format('%.6f', math.random())" 0]
        assert {$a ne $b}
    }

    test {math.randomseed makes a sequence reproducible} {
        set a [r eval "math.randomseed(12345) return string.format('%.6f', math.random())" 0]
        set b [r eval "math.randomseed(12345) return string.format('%.6f', math.random())" 0]
        assert_equal $a $b
    }

    test {loadstring and load are not available} {
        catch {r eval "return loadstring('return 1')()" 0} e
        assert_match {*nonexistent global variable 'loadstring'*} $e
        catch {r eval "return load('return 1')()" 0} e
        assert_match {*nonexistent global variable 'load'*} $e
    }

    test {print, dofile, loadfile, setfenv, getfenv are not available} {
        foreach fn {print dofile loadfile setfenv getfenv newproxy} {
            catch {r eval "return $fn" 0} e
            assert_match "*nonexistent global variable '$fn'*" $e
        }
    }

    test {os is limited to clock} {
        assert_equal [r eval "return type(os.clock)" 0] {function}
        assert_equal [r eval "return type(rawget(os, 'time'))" 0] {nil}
    }
}
