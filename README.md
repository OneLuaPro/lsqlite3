# lsqlite3

`lsqlite3` is a thin wrapper around the public domain **SQLite3** database engine. Most SQLite3 functions are accessible via an object-oriented interface to either database or SQL statement objects. This specific `lsqlite3` for [OneLuaPro](https://github.com/OneLuaPro) bundle provides a modernized, high-performance build of the SQLite3 Lua bindings, integrating cutting-edge extensions and security features. It currently comprises:

- [LuaSQLite3](https://lua.sqlite.org/home/index) v0.9.6
- [SQLite](https://www.sqlite.org/) v3.51.2
- [SQLean](https://github.com/OneLuaPro/sqlean) v0.28.0

## Project Scope & Architecture

- **Core Engine**: Rebuilt from the ground up using the latest LuaSQLite3 sources as a foundation, ensuring full compatibility with **Lua 5.4** and upwards.
- **Modern SQLite**: Powered by most recent SQLite, offering the latest performance optimizations, security patches, and advanced SQL features.
- **SQLean Integration**: Fully integrated with the SQLean ecosystem. Users have access to both standard SQLite commands and a vast "extended standard library," including modules for Crypto, FileIO**, **Regexp**, **Fuzzy matching, and more.
- **Thread-Safety**: Compiled with native thread-safety support, making it suitable for multi-threaded Lua environments and complex application architectures.
- **Dual-Tier Testing**:
  - **Legacy Reliability**: Verified against the historical **lsqlite3 test bench** (porting 1,024 assertions to a modern environment) to ensure 100% backward compatibility.
  - **Modern Validation**: Includes a new [busted](https://github.com/OneLuaPro/busted) test suite specifically designed to verify extended SQLean functionality and cross-check it against native libraries such as [LuaFileSystem](https://github.com/OneLuaPro/luafilesystem) or [lua-openssl](https://github.com/OneLuaPro/lua-openssl).

## License

For licensing information, see `https://github.com/OneLuaPro/lsqlite3/blob/master/LICENSE`.

