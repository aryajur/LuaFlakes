-- Command Line options parser setup module


local M = {}
package.loaded[...] = M
if setfenv and type(setfenv) == "function" then
	setfenv(1,M)	-- Lua 5.1
else
	_ENV = M		-- Lua 5.2
end


function new(parser)

	-- Add the commands
	parser:command_target("command")
	local commands = {}
	commands.remotelist = parser:command("remotelist","Prints list of modules available to install.")
	commands.moduleverlist = parser:command("moduleverlist","Prints all the versions of a particular module available to install.")
	commands.init = parser:command("init","Initialize the current directory to be a Lua setup managed by LuaFlakes.")
	commands.remotelualist = parser:command("remotelualist","Prints all the versions of Lua avalaible to install.")
	commands.moduleattr = parser:command("moduleattr","Prints the module's attributes for a particular version of the module")
	commands.install = parser:command("install","Install a module. Version number can be specified (default=latest).")
	commands.locallist = parser:command("locallist","Prints the list of modules installed locally")
	commands.clean = parser:command("clean","Clean the current setup entirely")
	commands.uninstall = parser:command("uninstall","Uninstall a module")
	
	commands.moduleverlist:argument("module","Module name whose version list is to be displayed."):args(1)	-- Only 1 argument needed - the module name
	commands.moduleattr:argument("module","Module name whose attributes are to be displayed. Indicate version number default=latest"):args("1-2")
	commands.install:argument("module","Module name to be installed. Indicate version number default=latest"):args("1-2")
	commands.install:flag("-d --dependencies","Flag to indicate whether to install dependencies automatically. Default=no")
	commands.uninstall:argument("module","Module name to be uninstalled."):args(1)	-- Only 1 argument needed
	
	return true
end