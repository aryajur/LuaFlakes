REM This is a test recipe to get the Lua executables together with luasocket and LuaSec binaries from LuaFlakes-bin1 repository 
REM and then also get the tableUtils module

mkdir __Lua
cd __Lua
REM Get Lua executables
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/Lua/5.3/lua.exe
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/Lua/5.3/lua.dll
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/Lua/5.3/luac.exe

REM get luasocket
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/ltn12.lua
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/mime.lua
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket.lua
mkdir mime
cd mime
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/mime/core.dll
cd ..
mkdir socket
cd socket
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket/core.dll
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket/ftp.lua
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket/headers.lua
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket/http.lua
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket/smtp.lua
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket/tp.lua
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/luasocket/socket/utl.lua
cd ..

REM get luasec
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/LuaSec/libcrypto-3.dll
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/LuaSec/libssl-3.dll
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/LuaSec/ssl.dll
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/LuaSec/ssl.lua
mkdir ssl
cd ssl
curl -O https://raw.githubusercontent.com/aryajur/LuaFlakes-bin1/HEAD/Windows/x32/LuaSec/ssl/https.lua
cd ..

REM get to the root
cd ..
REM get TableUtils
mkdir tableUtils
cd tableUtils
curl -O https://raw.githubusercontent.com/aryajur/tableUtils/7b5857e25d0953971d919d1254ff253517185d31/src/tableUtils.lua
cd ..





