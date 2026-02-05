# MIT License
#
# Copyright (c) 2026 The OneLuaPro project authors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

cmake_minimum_required(VERSION 3.31)
project(lsqlite3 VERSION 0.9.6 LANGUAGES C)

# ------------------------------------------------------------------------------
# Other settings
set(CMAKE_C_STANDARD 99)
set(CMAKE_VERBOSE_MAKEFILE ON)

# ------------------------------------------------------------------------------
# Dependencies: Lua & SQLean
# find liblua installation and version info
if(NOT LUA_HINTS)
  if(WIN32)
    set(LUA_HINTS "c:/Apps")
  endif()
endif()
find_package(liblua REQUIRED CONFIG HINTS ${LUA_HINTS})
if(liblua_FOUND)
  message(STATUS "liblua version        : ${liblua_VERSION}")
  message(STATUS "liblua install prefix : ${LIBLUA_INSTALLDIR}")
  message(STATUS "liblua include dir    : ${LIBLUA_INCLUDEDIR}")
  message(STATUS "liblua lib dir        : ${LIBLUA_LIBDIR}")
else()
  message(FATAL_ERROR "Unable to find liblua version ${liblua_VERSION}.")
endif()
# Path to custom SQLean installation from previous steps
set(SQLEAN_DIR ${LUA_HINTS} CACHE PATH "Path to sqlean installation")

# ------------------------------------------------------------------------------
# Setup GNU-alike installatin directories
include (GNUInstallDirs)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})
set(INSTALL_LIBDIR
  ${CMAKE_INSTALL_LIBDIR} CACHE PATH "Installation directory for libraries")
set(INSTALL_BINDIR
  ${CMAKE_INSTALL_BINDIR} CACHE PATH "Installation directory for executables")
set(INSTALL_INCLUDEDIR
  ${CMAKE_INSTALL_INCLUDEDIR} CACHE PATH "Installation directory for header files")
set(INSTALL_DOCDIR
  ${CMAKE_INSTALL_DOCDIR} CACHE PATH "Installation directory for documentation")
set(INSTALL_MANDIR
  ${CMAKE_INSTALL_MANDIR} CACHE PATH "Installation directory for manpages")
set(INSTALL_DATAROOTDIR
  ${CMAKE_INSTALL_DATAROOTDIR} CACHE PATH "Installation directory for data")
# Lua-specific installation dirs
set(INSTALL_TOP_CDIR
  ${INSTALL_LIBDIR}/lua/${liblua_VERSION_MAJOR}.${liblua_VERSION_MINOR})
set(INSTALL_TOP_LDIR
  ${INSTALL_DATAROOTDIR}/lua/${liblua_VERSION_MAJOR}.${liblua_VERSION_MINOR})

# ------------------------------------------------------------------------------
# Fetch external Source: lsqlite3
include(FetchContent)
set(FETCHCONTENT_QUIET ON)
message(STATUS "Fetching lsqlite3 source from lua.sqlite.org...")
set(ZIP_VERSION "v${PROJECT_VERSION_MAJOR}${PROJECT_VERSION_MINOR}${PROJECT_VERSION_PATCH}")
FetchContent_Declare(
  lsqlite3_source
  URL "https://lua.sqlite.org/home/zip/lsqlite3_${ZIP_VERSION}.zip"
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(lsqlite3_source)
FetchContent_GetProperties(lsqlite3_source SOURCE_DIR LSQLITE3_DIR)

# ------------------------------------------------------------------------------
# The Library Target
# Build the DLL using our custom loader and the downloaded lsqlite3.c
add_library(lsqlite3 SHARED 
  src/sqlean_loader.c 
  "${LSQLITE3_DIR}/lsqlite3.c"
)

# ------------------------------------------------------------------------------
# Include Directories
# We use BEFORE to prioritize our new SQLite headers over the ones in LSQLITE3_DIR
target_include_directories(lsqlite3 BEFORE PRIVATE
  src
  "${LIBLUA_INCLUDEDIR}" 
  "${SQLEAN_DIR}/include"
)

# ------------------------------------------------------------------------------
# Compiler Definitions & Mapping
target_compile_definitions(lsqlite3 PRIVATE 
  LUA_BUILD_AS_DLL
  LUA_LIB
  SQLITE_CORE
  LSQLITE_VERSION="${PROJECT_VERSION}"
)
set_source_files_properties("${LSQLITE3_DIR}/lsqlite3.c" PROPERTIES 
  COMPILE_DEFINITIONS "luaopen_lsqlite3=luaopen_lsqlite3_original"
)
if(MSVC)
  # Mutes warning C4005: "LUA_LIB": Macro-Redefinition in lsqlite3.c
  # as LUA_LIB is defined in lsqlite3.c for historical reasons
  set_source_files_properties("${LSQLITE3_DIR}/lsqlite3.c" PROPERTIES 
    COMPILE_FLAGS "/wd4005"
)
endif()
  
# ------------------------------------------------------------------------------
# Link against the static sqlean.lib (which includes SQLite) and Lua
target_link_libraries(lsqlite3 PRIVATE 
  "${SQLEAN_DIR}/lib/sqlean.lib"
  "${LIBLUA_LIBDIR}/liblua.lib"
)

# ------------------------------------------------------------------------------
# Output Configuration
# Ensure the output is named lsqlite3.dll without "lib" prefix
set_target_properties(lsqlite3 PROPERTIES 
  PREFIX "" 
  OUTPUT_NAME "lsqlite3"
)

# ------------------------------------------------------------------------------
# Install
install(TARGETS lsqlite3 RUNTIME DESTINATION ${INSTALL_TOP_CDIR})
