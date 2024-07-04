# LuaFlakes
Lua and modules binary storage and retrieval

# Usage
1. Download the binary from the release
2. Extract the contents. It will have a Lua executable and a LuaFlakes.lua file
3. Make sure git is installed and accessible on the command line. Install from https://git-scm.com
4. Go to an empty directory where you want to install Lua and its modules.
5. Run the LuaFlakes.lua file using the lua executable from the downloaded binary using the command:
```
> path\to\downloaded\lua path\to\downloaded\LuaFlakes.lua init
```

A Lua executable will be installed in the __Lua subdirectory.

6. A module can be installed using a command:
```
> path\to\downloaded\lua path\to\downloaded\LuaFlakes.lua install luasocket
```

For a list of commands do:
```
> path\to\downloaded\lua path\to\downloaded\LuaFlakes.lua -h
```

To see version information do:
```
> path\to\downloaded\lua path\to\downloaded\LuaFlakes.lua -v
```


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

# Attributes of a Module
1. Name - This should be the same as the directory name where this _attr.flakes file is placed
2. Description
3. Websites - Array of websites
4. Architecture - 32,64
5. OS - Windows, Linux
6. LuaVER - Version of Lua it works with
7. ModVER - Version number of the Mod
8. ModDIR - (Optional) If given the directory with this name will be created and all MODULE marked files will be inside this
8. FileIndex - List of all files of the module. Each list item is a table with the following information:
	1. File name - At the first index. This contains the file name and path by which to save the file in the indicated place.
 	2. "FILE"/"DIR" string at the second index to indicate this entry describes a file or a directory
	3. At the third index, the place it has to be placed:
		Places can be:
		1. Module place - "MODULE" - Creates a folder with the name ModDIR if given and places them in that directory
		2. Common DLL - "COMMON" - Places the file in the lua executable directory (__Lua)
	3. This entry describes where to copy the file from and is only present for "FILE" entries. This entry will be a array with 2 entries:
		1. Type or source:
			1. "WEB" - download from internet.
		2. Source info. For WEB it is the direct URL of the file
9. Dependencies and their versions
10. Comment - Any additional information
