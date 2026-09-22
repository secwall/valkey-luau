#ifndef _FUNCTION_LUAU_H_
#define _FUNCTION_LUAU_H_

#include "script_luau.h"

ValkeyModuleScriptingEngineCompiledFunction **
luauFunctionLibraryCreate(luauEngineCtx *engine_ctx,
                          ValkeyModuleCtx *module_ctx,
                          const char *code,
                          size_t code_len,
                          size_t timeout,
                          size_t *out_num_compiled_functions,
                          ValkeyModuleString **err);

void luauLibraryRelease(luauEngineCtx *engine_ctx, luauLibrary *lib);

#endif
