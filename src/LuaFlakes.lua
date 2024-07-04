-- Luaflakes script to provide the functionality to manage a Lua setup

require("submodsearcher")
local tu = require("tableUtils")

local argparse = require "argparse"
local parser = argparse("LuaFlakes","Local Lua installation and module management script.")

local opt = require("LuaFlakes.clioptions")	-- To load all command line options in the parse
opt.new(parser)

local STATFILE = "_attr.flakes"


local args = parser:parse()

local ATTRREPO = "LuaFlakes-attr"

local sep = package.config:match("(.-)%s")

-- Function to extract the file name from the path that is mentioned in _attr.flakes files. The separator in these files is supposed to be '/' only
local function getFileName(path)
	local fName = path:match("/([^%/]+)$") or path
	return fName
end

--https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
--- Check if a file or directory exists in this path
local function exists(file)
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
local function isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end

local function strWrap(str,pre)
	local flag
	return function()
		if flag then
			return nil
		else
			flag = true
			return pre..str
		end
	end
end

local function copyFile(source,destPath,fileName,chunkSize,overwrite)
	chunkSize = chunkSize or 1000000	-- 1MB chunk size default
	local ret = true
	local f = io.open(source,"rb")
	local fd = io.open(destPath..fileName,"w+b")
	local chunk = f:read(chunkSize)
	local stat,msg
	while chunk do
		stat,msg = fd:write(chunk)
		if not stat then
			fd:close()
			f:close()
			return nil,"Error writing file: "..msg
		end
		chunk = f:read(chunkSize)
	end
	fd:close()
	f:close()
	return true
end

local function getIndex()
	if not isdir(ATTRREPO) then
		os.execute([[git clone --no-checkout https://github.com/aryajur/]]..ATTRREPO..[[ >> log.txt]])
	end
	os.execute([[cd ]]..ATTRREPO..[[ && git reset --hard && git fetch origin && git checkout origin/main -- index.lua >> ../log.txt]])
	os.remove("log.txt")
	return loadfile(ATTRREPO..[[/index.lua]])()
end


-- Function to print the remote list of modules available
local function remoteList()
	local index = getIndex().modules
	print("List of Modules available are:")
	print(" OS ","Arch","Lua","Module")
	for i = 1,#index do
		print(index[i]:match("^([^\\/]+)/([^\\/]+)/([^\\/]+)/([^\\/]+)$"))
	end
end

local function remoteLuaList()
	local index = getIndex().lua
	print("List of Lua versions available are:")
	print(" OS ","Arch","Lua")
	for i = 1,#index do
		print(index[i]:match("^([^\\/]+)/([^\\/]+)/([^\\/]+)/[^\\/]+$"))
	end
end

local function getVerInfo(mod,OS,arch,luaver)
	local index = getIndex().modules
	local mods = {}
	for i = 1,#index do
		if OS and arch and luaver then
			if index[i] == OS.."/"..arch.."/"..luaver.."/"..mod then
				mods[#mods + 1] = {{},index[i]}
			end
		elseif index[i]:match("/([^\\/]+)$") == mod then
			mods[#mods + 1] = {{},index[i]}
		end
	end
	if #mods == 0 then
		return nil,"Module "..mod.." not found."
	end
	--print("Found entries:",#mods)
	for i = 1,#mods do
		os.execute([[cd ]]..ATTRREPO..[[ && git fetch && git pull origin main:]]..mods[i][2]..[[ && git checkout main -- ]]..mods[i][2]..[[/_attr.flakes]])
		os.execute([[cd ]]..ATTRREPO..[[ && git log --date=short ]]..mods[i][2]..[[/_attr.flakes >> ../log.txt]])
		-- Open and parse log.txt
		local hashes = {}
		local ver = mods[i][1]
		local f = io.open("log.txt")
		local l = f:read("*a")
		f:close()
		os.remove("log.txt")
		--print(l)
		local st,stp = l:find("commit .-commit")
		local offset = 6
		if not st then st,stp = l:find("commit .+") offset = 0 end
		while st do
			local com = l:sub(st,stp-offset)
			local hash = com:match("commit (.-)%c")
			local date = com:match("Date:%s*(.-)%c")
			--print(l)
			hashes[#hashes + 1] = {hash,date}
			local cstp = stp
			st,stp = l:find("commit .-commit",cstp-offset)
			if not st then
				st,stp = l:find("commit .+",cstp - offset)
				offset = 0
			end
		end
		-- Now get the versions by getting the contents of _attr.flakes checked in at different hashes
		for j = 1,#hashes do
			--print(hashes[i])
			os.execute([[cd ]]..ATTRREPO..[[ && git show ]]..hashes[j][1]..[[:]]..mods[i][2]..[[/_attr.flakes >> ../content.lua]])
			f = io.open("content.lua")
			local content = f:read("*a")
			--print(content)
			f:close()
			--print(load(strWrap(content,"return ")))
			local con = load(strWrap(content,"return "))()	-- Wrapped string in a function to be compatible with Lua 5.1 load
			--print(hashes[j][1],hashes[j][2],tu.t2spp(con))
			ver[#ver + 1] = {hashes[j][1],hashes[j][2],con}	-- Store the commit hash, commit date and the _attr.flakes content table
			os.remove("content.lua")	-- So that the next commit is not appended to it
		end
	end
	return mods
end

-- Function to list the versions of the indicated module on the command line
local function moduleverlist()
	local ver,msg = getVerInfo(args.module)
	if not ver then
		print(msg)
		return
	end
	--print(tu.t2spp(ver))
	print("Version list for "..args.module..": ")
	local verList = {}
	print("  OS  ","Arch","Lua","Version")
	for i = 1,#ver do
		--print(tu.t2spp(ver[i][1]))
		for j = 1,#ver[i][1] do
			if not tu.inArray(verList,ver[i][1][j][3],function(one,two) return one[1] == two.ModVER and one[2] == two.OS and one[3] == two.Architecture and one[4] == two.LuaVER end) then
				verList[#verList + 1] = {ver[i][1][j][3].ModVER,ver[i][1][j][3].OS,ver[i][1][j][3].Architecture,ver[i][1][j][3].LuaVER}
				print(ver[i][1][j][3].OS,ver[i][1][j][3].Architecture,ver[i][1][j][3].LuaVER,verList[#verList])
			end
		end
	end
end

-- Function to download the fileIndex of a module
local function downloadFiles(modDIR,fileIndex)
	local index = {}		-- index of files that will be placed in the attributes of the current setup
	local mdir
	for i = 1,#fileIndex do
		if fileIndex[i][2] == "DIR" then
			local path = fileIndex[i][1]
			path = path:gsub("/",sep)
			if fileIndex[i][3] == "MODULE" then
				if not mdir and not isdir(modDIR) then
					print("mkdir "..modDIR)
					os.execute("mkdir "..modDIR)
					mdir = true
				end
				print("mkdir "..modDIR..sep..path)
				os.execute("mkdir "..modDIR..sep..path)
			else	-- fileIndex[i][3] == "COMMON"
				print("mkdir __Lua"..sep..path)
				os.execute("mkdir __Lua"..sep..path)
			end
		else	-- fileIndex[i][2] == "FILE"
			-- Get the source
			local src = fileIndex[i][4]
			-- only "WEB" sources for now
			local path = fileIndex[i][1]
			--path = path:gsub("/",sep)
			if fileIndex[i][3] == "MODULE" then
				path = modDIR.."/"..path
				if not mdir and not isdir(modDIR) then
					print("mkdir "..modDIR)
					os.execute("mkdir "..modDIR)
					mdir = true
				end
			else	-- fileIndex[i][3] == "COMMON"
				path = "__Lua/"..path
			end
			index[#index + 1] = path
			print([[curl -o "]]..path..[[" ]]..src[2])			
			os.execute([[curl -o "]]..path..[[" ]]..src[2])			
		end
	end
	return index
end

local function init()
	-- Find the directory remove command
	os.execute("mkdir __Lua")
	os.execute("mkdir __Lua"..sep.."test")
	local commands = {
		"rm",
		"rmdir"
	}
	local found
	for i = 1,#commands do
		if os.execute(commands[i].." __Lua"..sep.."test") then
			os.execute(commands[i].." __Lua")
			found = commands[i]
			break
		end
	end
	if not found then
		print("Please enter the command which can be used to delete directories in the current Operating System. Example 'rmdir' in windows or 'rm' in Linux.")
		local com = io.read()
		if #com == 0 then
			return
		end
		if os.execute(com.." __Lua"..sep.."test") then
			os.execute(com.." __Lua")
			found = com
		end
		while not found do
			print("That does not work. Please try again.")
			com = io.read()
			if #com == 0 then
				return
			end
			if os.execute(com.." __Lua"..sep.."test") then
				os.execute(com.." __Lua")
				found = com
			end
		end
	end
	local index = getIndex()
	local luaList = {}
	for i = 1,#index.lua do
		local OS,arch,ver = index.lua[i]:match("^([^\\/]+)/([^\\/]+)/([^\\/]+)/[^\\/]+$")
		local ind = tu.inArray(luaList,OS,function(one,two) return one[1] == two end)
		if not ind then
			luaList[#luaList + 1] = {OS,{}}	-- OS and a table for architectures
			ind = #luaList
		end
		local ind1 = tu.inArray(luaList[ind][2],arch,function(one,two) return one[1] == two end)
		if not ind1 then
			ind1 = #luaList[ind][2] + 1
			luaList[ind][2][ind1] = {arch,{}}	-- Architecture and a table for Lua Versions
		end
		local ind2 = tu.inArray(luaList[ind][2][ind1][2],ver)
		if not ind2 then
			local ind2 = #luaList[ind][2][ind1][2] + 1
			luaList[ind][2][ind1][2][ind2] = ver
		end
	end
	local config = {FileIndex = {},Dependencies = {},RMCMD=found}
	if exists("_attr.flakes") then
		print("There seems to be a existing setup here. Run clean to clean the setup (N) or continue to merge with previous setup (Y)? (Y/N)")
		local ch = io.read()
		if ch ~= "Y" then
			return  
		end
		-- Load the current _attr.flakes
		local f = io.open("_attr.flakes")
		local c = f:read("*a")
		f:close()
		local con = load(strWrap(c,"return "))() 	-- Wrapped the string in a function to be compatible with Lua 5.1
		config.FileIndex = con.FileIndex
	end
	local osindex,archindex,verindex
	-- Choose the OS
	if #luaList == 1 then
		config.os = luaList[1][1]
		osindex = 1
	else
		print("Select an OS from the list, 0 to cancel:")
		for i = 1,#luaList do
			print(i..". "..luaList[i][1])
		end
		osindex = tonumber(io.read())
		if osindex < 1 or osindex > #luaList then
			return
		end
		config.os = luaList[osindex][1]
	end
	-- Choose the architecture
	if #luaList[osindex][2] == 1 then
		config.arch = luaList[osindex][2][1][1]
		archindex = 1
	else
		print("Select an Architecture from the list, 0 to cancel:")
		for i = 1,#luaList[osindex][2] do
			print(i..". "..luaList[osindex][2][i])
		end
		archindex = tonumber(io.read())
		if archindex < 1 or archindex > #luaList[osindex][2] then
			return
		end	
		config.arch = luaList[osindex][2][archindex][1]
	end
	-- Choose the Lua version
	local list = luaList[osindex][2][archindex][2]
	if #list == 1 then
		config.lua = list[1]
		verindex = 1
	else
		print("Select Lua version from the list, 0 to cancel:")
		for i = 1,#list do 
			print(i..". "..list[i])
		end
		verindex = tonumber(io.read())
		if verindex < 1 or verindex > #list then
			return
		end
		config.lua = list[verindex]
	end
	-- Create the __Lua directory
	if isdir("__Lua") then
		print("There already seems to be a __Lua sub-directory. Do you want to overwrite the files in the directory? (Y/N)")
		local ch = io.read()
		if ch ~= "Y" then
			return
		end
	else
		os.execute("mkdir __Lua")
	end
	-- Get the Lua files
	local path = config.os..[[/]]..config.arch..[[/]]..config.lua..[[/Lua]]
	os.execute([[cd ]]..ATTRREPO..[[ && git fetch && git pull origin main:]]..path..[[ && git checkout main -- ]]..path..[[/_attr.flakes]])
	
	path = ATTRREPO..[[/]]..path.."/"
	-- Read the _attr.flakes file
	local f,msg = io.open(path..[[_attr.flakes]])
	assert(f,msg)
	local content = f:read("*a")
	--print(content)
	f:close()
	local con = load(strWrap(content,"return "))()	-- Wrapped string in function to be compatible with Lua 5.1
	config.FileIndex = config.FileIndex or {}
	local ind = downloadFiles("__Lua/",con.FileIndex)
	for i = 1,#ind do
		if not tu.inArray(config.FileIndex,ind[i], function(one,two) return one[3] == two end) then
			config.FileIndex[#config.FileIndex + 1] = {"init",{"Lua",config.lua},ind[i]}
		end
	end
	-- Create the local installation _attr.flakes file
	f = io.open("_attr.flakes","w+")
	f:write(tu.t2spp(config))
	f:close()
end

-- Function to list the module attributes(_attr.flakes file) for a particular version 
local function moduleattr()
	local ver,msg = getVerInfo(args.module[1])
	if not ver then
		print(msg)
		return
	end
	if args.module[2] then
		local list = {}
		for i = 1,#ver do
			local os,arch,luaver = ver[i][2]:match("^([^\\/]+)/([^\\/]+)/([^\\/]+)/[^\\/]+$")
			local l = {}
			for j = 1,#ver[i][1] do
				if ver[i][1][j][3].ModVER == args.module[2] then
					l[#l + 1] = ver[i][1][j]
				end
			end
			if #l > 0 then
				local ind = #list + 1
				list[ind] = l
				table.sort(list[ind],function(one,two) return one[2] > two[2] end)	-- Sort the list with dates
				list[ind].os = os
				list[ind].arch = arch
				list[ind].luaver = luaver
			end
		end
		if #list == 0 then
			print("Version "..args.module[2].." not found for module "..args.module[1])
			return
		end
		for i = 1,#list do
			print("For OS: "..list[i].os.." Architecture: "..list[i].arch.." Lua version: "..list[i].luaver.." the attributes for module "..args.module[1].." are:")
			print(tu.t2spp(list[i][1][3]))
		end
	else
		local ind
		for i = 1,#ver do
			local os,arch,luaver = ver[i][2]:match("^([^\\/]+)/([^\\/]+)/([^\\/]+)/[^\\/]+$")
			print("For OS: "..os.." Architecture: "..arch.." Lua version: "..luaver.." the attributes for module "..args.module[1].." are:")
			local latest = ver[i][1][1][3].ModVER
			local date = ver[i][1][1][2]
			ind = 1
			for j = 2,#ver[i][1] do
				if ver[i][1][j][3].ModVER > latest then
					latest = ver[i][1][j][3].ModVER
					date = ver[i][1][j][2]
					ind = j
				elseif ver[i][1][j][3].ModVER == latest and ver[i][1][j][2] > date then
					latest = ver[i][1][j][3].ModVER
					date = ver[i][1][j][2]
					ind = j
				end
			end
			print(tu.t2spp(ver[i][1][ind][3]))
		end
	end
end

-- Function to return the local modules in the installation
local function getLocalAttr()
	if not exists("_attr.flakes") then
		return nil,"Did not find any _attr.flakes file to indicate local installation."
	end
	local f = io.open("_attr.flakes")
	local con = f:read("*a")
	f:close()
	local attr = load(strWrap(con,"return "))()	-- Wrapping the string in a function to be compatible with Lua 5.1
	local mods = {}
	local LuaVER
	for i = 1,#attr.FileIndex do
		if not tu.inArray(mods,attr.FileIndex[i][2][1],function(one,two) return one[1] == two end) then
			if attr.FileIndex[i][1] ~= "init" then
				mods[#mods + 1] = {attr.FileIndex[i][2][1],attr.FileIndex[i][2][2]}
			end
		end
	end
	return mods,attr
end

-- Function to list the local modules in the installation
local function locallist()
	local mods,con = getLocalAttr()
	if not mods then
		print(con)
		return
	end
	print("Current Installation is for "..con.os.." OS for "..con.arch.." architecture and Lua version "..con.lua)
	print("Module","Version")
	for i = 1,#mods do
		print(mods[i][1],mods[i][2])
	end
end

local function installModule(mod,modver)
	if not exists("_attr.flakes") then
		return nil,"Did not find any _attr.flakes file to indicate local installation. Please do an init first."
	end
	
	local mods,attr
	mods,attr = getLocalAttr()
	if not mods then
		return nil,attr
	end
	if tu.inArray(mods,mod,function(one,two) return one[1] == two end) then
		return nil,"The module "..mod.." is already installed."
	end
	local ver,msg = getVerInfo(mod)
	if not ver then
		return nil,msg
	end
	--print(attr.os,attr.arch,attr.lua)
	local ind = tu.inArray(ver,mod,function(one,two) 
			local os,arch,luaver,mod = one[2]:match("^([^\\/]+)/([^\\/]+)/([^\\/]+)/([^\\/]+)$")
			--print(os,arch,luaver,mod,two)
			if mod == two then
				return (os == attr.os or os == "all") and (arch == attr.arch or arch=="all") and (luaver == attr.lua or luaver =="all")
			end
		end)
	if not ind then
		return nil,"Cannot find the module compatible for OS:"..attr.os.." Architecture: "..attr.arch.." and Lua version: "..attr.lua
	end
	msg = ver[ind][2]
	ver = ver[ind][1]
	local hash,modattr
	if modver then
		local list = {}
		for i = 1,#ver do
			if ver[i][3].ModVER == modver then
				list[#list + 1] = ver[i]
			end
		end
		table.sort(list,function(one,two) return one[2] > two[2] end)
		if #list == 0 then
			return nil,"Version "..modver.." not found for module "..mod
		end
		modattr = list[1][3]
		hash = list[1][1]
	else
		local ind = 1
		local latest = ver[1][3].ModVER
		local date = ver[1][2]
		for i = 2,#ver do
			if ver[i][3].ModVER > latest then
				latest = ver[i][3].ModVER
				date = ver[i][2]
				ind = i
			elseif ver[i][3].ModVER == latest and ver[i][2] > date then
				latest = ver[i][3].ModVER
				date = ver[i][2]
				ind = i
			end
		end
		modattr = ver[ind][3]
		hash = ver[ind][1]
	end
	-- Checkout this version's _attr.flakes
	os.execute([[cd ]]..ATTRREPO..[[ && git fetch && git pull origin main:]]..msg..[[ && git checkout ]]..hash..[[ -- ]]..msg..[[/_attr.flakes]])
	-- Now download the files
	ind = downloadFiles(modattr.ModDIR,modattr.FileIndex)
	for i = 1,#ind do
		if not tu.inArray(attr.FileIndex,ind[i], function(one,two) return one[3] == two end) then
			attr.FileIndex[#attr.FileIndex + 1] = {"install",{modattr.Name,modattr.ModVER},ind[i]}
		end
	end
	if modattr.Dependencies and #modattr.Dependencies > 0 then
		attr.Dependencies[#attr.Dependencies + 1] = modattr.Dependencies
		attr.Dependencies[#attr.Dependencies].module = modattr.Name
	end
	local f = io.open("_attr.flakes","w+")
	f:write(tu.t2spp(attr))
	f:close()	
	return modattr
end

-- Function to install a module in the local installation specified on the command line
local function install()
	local que = {}
	local stat,msg = installModule(args.module[1],args.module[2])
	if not stat then 
		print(msg)
		return
	end
	if stat.Dependencies and #stat.Dependencies > 0 and args.dependencies then
		for i = 1,#stat.Dependencies do
			if not tu.inArray(que,stat.Dependencies[i],function(one,two) return one[1] == two[1] and one[2] == two[2] end) then
				que[#que + 1] = stat.Dependencies[i]
			end
		end
	end
	while #que > 0 do
		print("Install Dependency: "..que[1][1].." Version: "..que[1][2])
		stat,msg = installModule(que[1][1],que[1][2])
		if not stat then
			print(msg)
		else
			if stat.Dependencies and #stat.Dependencies > 0 then
				for i = 1,#stat.Dependencies do
					if not tu.inArray(que,stat.Dependencies[i],function(one,two) return one[1] == two[1] and one[2] == two[2] end) then
						que[#que + 1] = stat.Dependencies[i]
					end
				end
			end
		end
		table.remove(que,1)
	end
end

-- Function to remove the list of files given in fileindex. The format of fileindex should be the same as the FileIndex in the local _attr.flakes file
local function removeFiles(fileindex)
	local dirs = {} 	-- to record all touched directories
	for i = 1,#fileindex do
		if fileindex[i][3]:find("/") then
			local dchain = fileindex[i][3]
			while dchain:find("/") and not tu.inArray(dirs,dchain:match("(.+)/[^/]+$")) do
				dchain = dchain:match("(.+)/[^/]+$")
				dirs[#dirs + 1] = dchain
			end
		end
		print("Delete file: "..fileindex[i][3])
		os.remove(fileindex[i][3])
	end
	return dirs
end

-- Function to check whether any file is still linked in the directory list. If not try removing the directory
-- fileindex should contain the list of files currently in the installation. The format should be as from the local _attr.flakes FileIndex
local function removeEmptyDir(dirs,fileindex,rmcmd)
	-- Sort the directories with the lowest level directories first
	table.sort(dirs,function(one,two)
			local _,o = one:gsub("/","")
			local _,t = two:gsub("/","")
			return o > t
		end)
	for i = 1,#dirs do
		if not tu.inArray(fileindex,dirs[i],function(one,two) return one[3]:sub(1,#two) == two end) then
			print("Delete directory: "..dirs[i])
			os.execute(rmcmd.." "..dirs[i]:gsub("/",sep))
		end
	end
	return true
end

-- Function to uninstall a module specified on the command line
local function uninstall()
	local mods,attr = getLocalAttr()
	if not mods then
		print(attr)
		return
	end
	-- First check whether this module is a dependency
	local dep = {}
	for i = 1,#attr.Dependencies do
		for j = 1,#attr.Dependencies[i] do
			if attr.Dependencies[i][j][1] == args.module then
				dep[#dep + 1] = attr.Dependencies[i].module
				break
			end
		end
	end
	if #dep > 0 then
		print("Module "..args.module.." is a dependency for the following modules:")
		for i = 1,#dep do
			print(dep[i])
		end
		print("Are you sure you want to uninstall it? (Y/N)")
		local ch = io.read()
		if ch ~= "Y" then
			return
		end
	end
	-- Build the file index
	local fi = {}
	for i = #attr.FileIndex,1,-1 do
		--print(attr.FileIndex[i][2][1],args.module)
		if attr.FileIndex[i][2][1] == args.module then
			fi[#fi + 1] = attr.FileIndex[i]
			table.remove(attr.FileIndex,i)
		end
	end
	print("Remove ",#fi,"files")
	local stat,msg = removeFiles(fi)
	if not stat then
		print(msg)
		return
	end
	stat,msg = removeEmptyDir(stat,attr.FileIndex,attr.RMCMD)
	if not stat then
		print(msg)
		return
	end
	for i = 1,#attr.Dependencies do
		if attr.Dependencies[i].module == args.module then
			table.remove(attr.Dependencies,i)
			break
		end
	end
	print("Update _attr.flakes")
	f = io.open("_attr.flakes","w+")
	f:write(tu.t2spp(attr))
	f:close()
end

-- Function to wipe clean the installation
local function clean()
	local mods,attr = getLocalAttr()
	if not mods then
		print(attr)
		return
	end
	local stat,msg = removeFiles(attr.FileIndex)
	if not stat then
		print(msg)
		return
	end
	stat,msg = removeEmptyDir(stat,{},attr.RMCMD)
	if not stat then
		print(msg)
		return
	end
	print("Remove _attr.flakes")
	os.remove("_attr.flakes")
end

local commandMap = {
	remotelist = remoteList,
	remotelualist = remoteLuaList,
	moduleverlist = moduleverlist,
	moduleattr = moduleattr,
	init = init,
	install = install,
	locallist = locallist,
	clean = clean,
	uninstall = uninstall,
}

commandMap[args.command]()
