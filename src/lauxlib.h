/*
 * Luau compatibility shim.
 */

#ifndef _VALKEY_LUAU_LAUXLIB_SHIM_H_
#define _VALKEY_LUAU_LAUXLIB_SHIM_H_

#include <stdio.h>

#include "lua.h"
#include "lualib.h"

#undef lua_pushcfunction
#define lua_pushcfunction(L, f, ...) lua_pushcclosurek(L, (f), #f, 0, NULL)

#undef lua_pushcclosure
#define lua_pushcclosure(L, f, nup, ...) lua_pushcclosurek(L, (f), #f, (nup), NULL)

#undef luaL_error
#define luaL_error(L, ...) (luaL_errorL(L, __VA_ARGS__), 0)

#undef luaL_argerror
#define luaL_argerror(L, narg, msg) (luaL_argerrorL(L, (narg), (msg)), 0)
#define lua_error(L) (lua_error(L), 0)
#define lua_rawlen(L, i) lua_objlen(L, (i))

static inline void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup) {
    luaL_checkstack(L, nup + 1, "too many upvalues");
    for (; l->name != NULL; l++) {
        for (int i = 0; i < nup; i++) lua_pushvalue(L, -nup);
        lua_pushcclosurek(L, l->func, l->name, nup, NULL);
        lua_setfield(L, -(nup + 2), l->name);
    }
    lua_pop(L, nup);
}

#define luaL_newlib(L, l) (lua_newtable(L), luaL_setfuncs(L, (l), 0))

#endif
