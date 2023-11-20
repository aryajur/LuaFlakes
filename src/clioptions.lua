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
	commands.remotelist = parser:command("remotelist","Prints list of modules available to install")
	commands.moduleverlist = parser:command("moduleverlist","Prints all the versions of a particular module available to install")
	--[[
	commands.moduleattr = parser:command("moduleattr","Prints the module's attributes for a particular version of the module")
	commands.locallist = parser:command("locallist","Prints the list of modules installed locally")
	commands.install = parser:command("install","Install a module")
	commands.uninstall = parser:command("uninstall","Uninstall a module")
	]]
	commands.moduleverlist:argument("module","Module name whose version list is the be displayed."):args(1)	-- Only 1 argument needed - the module name
	
	return true
end