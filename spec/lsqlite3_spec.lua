-- -*- coding: utf-8 -*-
--[[
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
]]
local sqlite3 = require("lsqlite3")
local openssl = require("openssl")
local lfs = require("lfs")

describe("lsqlite3 with SQLean cross-check", function()
  local db

  before_each(function()
	db = sqlite3.open_memory()
  end)
  
  after_each(function()
	if db then db:close() end
  end)

  it("should match MD5 results between SQLean and OpenSSL", function()
	local data = "OneLuaPro"
    
	-- 1. Calculate reference hash using lua-openssl
	local md = openssl.digest.get("md5")
	local hash_bin = md:digest(data)
	local expected_hex = openssl.hex(hash_bin):lower()
    
	-- 2. Calculate hash using SQLean in lsqlite3
	local actual_hex = ""
	-- We use lower() in SQL to ensure case-insensitive comparison
	for hash in db:urows(string.format("SELECT lower(hex(crypto_md5('%s')))", data)) do
	   actual_hex = hash
	end
    
	-- 3. Assert equality
	assert.is_equal(expected_hex, actual_hex)
	-- Value should be: 0438541a7758c7d4745d4e8c9c9c1a13 (based on your snippet)
  end)

  it("should verify math_sqrt against Lua's native math.sqrt", function()
	local val = 123.456
	local expected = math.sqrt(val)
	local actual = 0
    
	for res in db:urows(string.format("SELECT math_sqrt(%f)", val)) do
	   actual = res
	end
    
	-- Using almost_equal for floating point precision
	assert.is_near(expected, actual, 0.000001)
  end)

  it("should be compiled with thread-safety enabled", function()
	local thread_safe = 0
	for val in db:urows("SELECT sqlite_compileoption_used('THREADSAFE=1')") do
	   thread_safe = 1
	end
	assert.is_equal(1, thread_safe)
  end)

  it("should correctly handle UTF-8 upper casing (SQLean-Text)", function()
	local result = ""
	for val in db:urows("SELECT nupper('äöü')") do
	   result = val
	end
	assert.is_equal("ÄÖÜ", result)
  end)

  it("should support PCRE2 regular expressions (SQLean-Regexp)", function()
	local matched = false
	-- Test: Endet der String 'OneLuaPro2026' auf genau vier Ziffern?
	for val in db:urows("SELECT regexp_like('OneLuaPro2026', '\\d{4}$')") do
	   matched = (val == 1)
	end
	assert.is_true(matched)

	-- Test: Ersetze alle Zahlen durch ein 'X'
	local replaced = ""
	for val in db:urows("SELECT regexp_replace('V096', '\\d', 'X')") do
	   replaced = val
	end
	assert.is_equal("VXXX", replaced)
  end)

  it("should calculate Levenshtein distance (SQLean-Fuzzy)", function()
	local dist = -1
	-- Distanz zwischen 'test' und 'text' sollte genau 1 sein (ein Buchstabe anders)
	for val in db:urows("SELECT levenshtein('test', 'text')") do
	   dist = val
	end
	assert.is_equal(1, dist)
  end)

  it("should support FTS5 virtual tables (SQLite-Core)", function()
	local status = pcall(function()
	      db:exec("CREATE VIRTUAL TABLE search_test USING fts5(content)")
	      db:exec("INSERT INTO search_test VALUES('OneLuaPro is a professional Lua distribution')")
	end)
	assert.is_true(status)
    
	local found = false
	for val in db:urows("SELECT content FROM search_test WHERE search_test MATCH 'professional'") do
	   found = true
	end
	assert.is_true(found)
  end)

  it("should list directory contents (SQLean-FileIO)", function()
	local files = {}
	-- fileio_ls is a table-valued function in SQLean
	-- We list the current directory ('.')
	for row in db:nrows("SELECT name FROM fileio_ls('.')") do
	   table.insert(files, row.name)
	end
    
	-- Verification: Should find at least one entry (e.g., '.' or '..')
	assert.is_true(#files > 0)
    
	-- Check if the list contains typical file system entries
	local found_spec = false
	for _, name in ipairs(files) do
	   if name:match("spec") then found_spec = true end
	end
	-- If we run busted from the project root, it should find the 'spec' folder
	assert.is_true(found_spec)
  end)

  it("should match directory listing between SQLean-FileIO and LFS", function()
	local path = "."
  
	-- 1. Get reference list from LFS
	local lfs_files = {}
	for file in lfs.dir(path) do
	   -- Skip directory navigation entries
	   if file ~= ".." then
	      lfs_files[file] = true
	   end
	end
  
	-- 2. Get actual list from SQLean-FileIO
	local sqlean_files = {}
	for row in db:nrows(string.format("SELECT name FROM fileio_ls('%s')", path)) do
	   -- Remove leading './' if present to match LFS output
	   local clean_name = row.name:gsub("^%./", "")
	   sqlean_files[clean_name] = true
	end
  
	-- 3. Cross-check: Every file found by LFS must be in SQLean result
	for name in pairs(lfs_files) do
	   assert.is_true(sqlean_files[name], "File missing in SQLean: " .. name)
	end
  
	-- 4. Cross-check: Every file found by SQLean must be in LFS result
	for name in pairs(sqlean_files) do
	   assert.is_true(lfs_files[name], "Unexpected file in SQLean: " .. name)
	end
  end)

  it("should match file size between SQLean and LFS using random binary content", function()
	local tmpdir = os.getenv("TEMP") or "."
	local filename = "busted_size_test.tmp"
	local fullpath = tmpdir .. "\\" .. filename
    
	-- Generate random length between 512 and 4096 bytes
	local random_length = math.random(512, 4096)
	local bytes = {}
	for i = 1, random_length do
	   bytes[i] = string.char(math.random(0, 255))
	end
	local random_content = table.concat(bytes)

	-- 1. Create file with random binary content
	local f = assert(io.open(fullpath, "wb"))
	f:write(random_content)
	f:close()

	-- 2. Retrieve size via LuaFileSystem
	local lfs_size = lfs.attributes(fullpath, "size")
    
	-- 3. Retrieve size via SQLean fileio_ls
	-- Use LIKE to remain agnostic of path separators (./ vs \)
	local stmt = db:prepare("SELECT size FROM fileio_ls(?) WHERE name LIKE ?")
	if not stmt then error(db:errmsg()) end
    
	-- Search in temp directory for our specific filename
	stmt:bind_values(tmpdir, "%" .. filename)
    
	local sqlean_size = nil
	if stmt:step() == sqlite3.ROW then
	   sqlean_size = stmt:get_named_values().size
	end
	stmt:finalize()

	-- 4. Cleanup temporary file
	os.remove(fullpath)

	-- 5. Final assertions
	assert.is_not_nil(sqlean_size, "SQLean failed to locate the file in the temp directory")
	assert.are.equal(lfs_size, tonumber(sqlean_size))
	assert.are.equal(random_length, tonumber(sqlean_size))
  end)
  
end)
