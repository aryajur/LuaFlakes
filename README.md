# LuaFlakes
Lua and modules binary storage and retrieval

# Working
The LuaFlakes script depends on the companion repository [LuaFlakes-attr](https://github.com/aryajur/LuaFlakes-attr) which stores all the information attributes for all the modules available through LuaFlakes.

The modules are organized in a following directory structure:
```
- index.lua
- all
|- all
| |- 5.3
|- x32
| |- 5.3
|- x64
| |- 5.3
- Windows
|- all
| |- 5.3
|- x32
| |- 5.3
| |- Lua
| |- luasocket
|- x64
| |- 5.3
- Linux
|- all
| |- 5.3
|- x32
| |- 5.3
|- x64
| |- 5.3
```
- So the first level specifies the OS level selection of the modules.
- The second level selects the architecture level and inside
- The third level specifies the Lua Version
- On the 4th level are the module directories themselves. Each module directory or the Lua directory contains a _attr.flakes file which describes the module and its associated files.

The index.lua file contains the list of all the _attr.flakes files location wrt to the root of the repository. A sample index.lua file is shown below:
```lua
return {
	modules = {
		"all/all/5.3/tableUtils",
		"Windows/x32/5.3/LuaSec",
		"Windows/x32/5.3/luasocket",
	},
	lua = {
		"Windows/x32/5.3/Lua"
	}
}
```
**Note all paths should be using the "/" separator always.**
