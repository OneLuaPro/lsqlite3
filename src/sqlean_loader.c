/*
 * Copyright (c) 2026 The OneLuaPro project authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Custom loader to inject SQLean extensions into lsqlite3.
 */

#include <lua.h>
#include <lauxlib.h>
#include "sqlite3.h"

/* Function exported by static sqlean.lib */
int sqlite3_sqlean_init(sqlite3 *db, char **pzErrMsg, const void *pApi);

/* The original lsqlite3 entry point, renamed via CMake compiler flags */
LUALIB_API int luaopen_lsqlite3_original(lua_State *L);

/* 
 * Official entry point Lua looks for when calling require("lsqlite3").
 * This function registers SQLean as an auto-extension before 
 * initializing the standard lsqlite3 module.
 */
LUALIB_API int luaopen_lsqlite3(lua_State *L) {
  /* 
   * Register SQLean to be automatically loaded for every new 
   * database connection opened by this Lua instance.
   */
  sqlite3_auto_extension((void*)sqlite3_sqlean_init);
  
  /* Hand over control to the original lsqlite3 implementation */
  return luaopen_lsqlite3_original(L);
}
