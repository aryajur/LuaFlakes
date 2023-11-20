-- Luaflakes script to provide the following functionality
--[[
1. List modules on remote						remotelist
2. List module version attributes				moduleattr
3. List module versions on remote				moduleverlist
4. List local modules and their versions		locallist
5. Install module								install
6. Uninstall module								uninstall
]]

require("submodsearcher")
local tu = require("tableUtils")

local argparse = require "argparse"
local parser = argparse("LuaFlakes","Local Lua installation and module management script.")

local opt = require("LuaFlakes.clioptions")	-- To load all command line options in the parse
opt.new(parser)


local args = parser:parse()

--https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
--- Check if a file or directory exists in this path
function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

--- Check if a directory exists in this path
function isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end

local function getIndex()
	if not isdir("LuaFlakes-bin1") then
		os.execute([[git clone --no-checkout https://github.com/aryajur/LuaFlakes-bin1]])
	end
	os.execute([[cd LuaFlakes-bin1 && git checkout main -- index.lua]])
	return loadfile([[LuaFlakes-bin1/index.lua]])()
end


-- Function to print the remote list of modules available
local function remoteList()
	local index = getIndex()
	for i = 1,#index do
		print(index[i]:match("[\\?/]([^\\/]+)$"))
	end
end

local function moduleverlist()
	local index = getIndex()
	local mods = {}
	for i = 1,#index do
		mods[i] = {index[i]:match("[\\?/]([^\\/]+)$"),index[i]}
	end
	local ind = tu.inArray(mods,args.module,function(one,two) return one[1] == two end)
	if not ind then
		print("Module "..args.module.." not found.")
		return
	end
	os.execute([[cd LuaFlakes-bin1 && git checkout main -- ]]..mods[ind][2]..[[/_attr.flakes]])
	os.execute([[cd LuaFlakes-bin1 && git log --oneline ]]..mods[ind][2]..[[/_attr.flakes >> ../log.txt]])
	-- Open and parse log.txt
	local hashes = {}
	local ver = {}
	local f = io.open("log.txt")
	local l = f:read("*l")
	while l do
		--print(l)
		hashes[#hashes + 1] = l:match("^([^%s]+)%s")
		l = f:read("*l")
	end
	f:close()
	os.remove("log.txt")
	-- Now get the versions
	for i = 1,#hashes do
		--print(hashes[i])
		os.execute([[cd LuaFlakes-bin1 && git show ]]..hashes[i]..[[:]]..mods[ind][2]..[[/_attr.flakes >> ../content.lua]])
		f = io.open("content.lua")
		local content = f:read("*a")
		--print(content)
		f:close()
		local con = load("return "..content)()
		--print(tu.t2spp(con))
		ver[#ver + 1] = con.ModVER
	end
	os.remove("content.lua")
	print("Version list for "..args.module..": ")
	for i = 1,#ver do
		print(ver[i])
	end
end

local commandMap = {
	remotelist = remoteList,
	moduleverlist = moduleverlist
}

commandMap[args.command]()
