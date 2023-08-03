local getopt = require('getopt')
local utils = require('utils')
local ac = require('ansicolors')
local os = require('os')
local count = 0
line = '-------------------------------------------------------------------------'
mod = "                   ELECTRA or EM410x fob cloning SCRIPT "
version = "               v1.1.14  01/08/2023 made by Jarek Barwinski "
desc = [[

   Cloning new ELECTRA tags or EM410x to T5577 tag. This script changes 
   block 0. Additional data is written to block 3 and 4. The last 
   ELECTRA ID can be accessed through the option ---> "-c". For copy 
   directly from the original ELECTRA tag, ---> option "-e". For copy 
   from input, EM410X ID ---> option "-s". Next option for cloning simple 
   EM4102 ---> option "-m". If press  <enter> it,  which writes an ID. 
   If press <n> ---> exit the script.
 ------------------------------------------------------------------------
]]
example = [[
-------------------------------------------------------------------------------

--------------- cloning ELECTRA tag from input ID to T5577 tag ----------------
  
  script run lf_electra -s 11AA22BB55

----------------- continue cloning from last cloned ELECTRA ------------------- 
  
  script run lf_electra -c
  
----------------------  ELECTRA cloning from the original TAG -----------------
  
  script run lf_electra -e

----------------------------- simple EM410x cloning --------------------------- 
  
  script run lf_electra -m
  
-------------------------------------------------------------------------------

]]
usage = [[
  script run lf_electra.lua [-e] [-h] [-c] [-m] [-s <EM410x ID HEX number>]
]]
arguments = [[
    -h      : this help
    -c      : continue cloning from last ID used
    -s      : ELECTRA - EM410x ID HEX number
    -e      : Read original ELECTRA from Proxmark3 device
    -m      : EM410x cloning
    ]]
--------------------------------------Path to logs files
local DEBUG = false
local ID_STATUS = os.getenv('HOME')..'/.proxmark3/logs/log_'..os.date('%Y%m%d')..'.txt'
-------------------------------------------A debug printout-function
local function dbg(args)
    if not DEBUG then return end
    if type(args) == 'table' then
        local i = 1
        while args[i] do
            dbg(args[i])
            i = i+1
        end
    else
        print('###', args)
    end
end
------------------------------------------------- errors
local function oops(err)
    core.console('clear')
    print( string.rep('--',39) )
    print( string.rep('--',39) )
    print(ac.red..'               ERROR:'..ac.reset.. err)
    print( string.rep('--',39) )
    print( string.rep('--',39) )
    core.clearCommandBuffer()
    return nil, err
end
-----------------------------------------------sleep
local function sleep(n)
    os.execute("sleep " ..tonumber(n))
end
----------------------------------------------time wait
local function timer(n)
print( string.rep('--',39) )
    while n > 0 do
        io.write(ac.cyan..">>>>> "..ac.yellow.. tonumber(n)..ac.cyan.." seconds...\r"..ac.reset)
        sleep(1)
        io.flush()
        n = n-1
    end
end
----------------------------------------------------- help
local function help()
    core.console('clear')
    print(line)
    print(ac.cyan..mod..ac.reset)
    print(ac.cyan..version..ac.reset)
    print(ac.yellow..desc..ac.reset)
    print(ac.cyan..'  Usage'..ac.reset)
    print(usage)
    print(ac.cyan..'  Arguments'..ac.reset)
    print(arguments)
    timer(30)
    core.console('clear')
    print(ac.cyan..'  Example usage'..ac.reset)
    print(example)
end
------------------------------------ Exit message
local function exitMsg(msg)
    print( string.rep('--',39) )
    print( string.rep('--',39) )
    print(msg)
    print()
end
--------------------------------- idsearch EM ID
local function id()
    local f = io.open(ID_STATUS, "r")
    for line in f:lines() do
        id = line:match"^%[%+%] EM 410x ID (%x+)"
        if id then break end
    end
    f:close()
    local  f= io.open(ID_STATUS, "w")
    f:write(id)
    f:close()
    local  f= io.open(ID_STATUS, "r")
    local t = f:read("*all")
    f:close()
    local hex_hi  = tonumber(t:sub(1, 2), 16)
    local hex_low = tonumber(t:sub(3, 10), 16)
    return hex_hi, hex_low
end
---------------------------------------read file
local function readfile()
    local f = io.open(ID_STATUS, "r")
    for line in f:lines() do
        id = line:match"^(%x+)"
	if id then break end
    end
    f:close()
    if not id then
        return oops ("        ....No ID found in file") end
    local  f= io.open(ID_STATUS, "r")
    local t = f:read("*all")
    f:close()
    local hex_hi  = tonumber(t:sub(1, 2), 16)
    local hex_low = tonumber(t:sub(3, 10), 16)
    return hex_hi, hex_low
end
----------------------------------------write file
local function writefile(hex_hi, hex_low)
    local f = io.open(ID_STATUS, "w+")
    f:write(("%02X%08X\n"):format(hex_hi, hex_low))
    f:close()
    print(('  Saved EM410x ID '..ac.green..'%02X%08X'..ac.reset..' to TXT file:`'):format(hex_hi, hex_low))
    print((ac.yellow..'  %s'..ac.reset..'`'):format(ID_STATUS))
    return true, 'Ok'
end
---------------------------------------- main
local function main(args)
    print( string.rep('--',39) )
    print( string.rep('--',39) )
    print()
    if #args == 0 then return help() end
    local saved_id = false
    local id_original = false
    local emarine = false
    local input_id = ''
	for o, a in getopt.getopt(args, 'hems:c') do
        if o == 'h' then return help() end
        if o == 'e' then id_original = true end
        if o == 'm' then emarine = true end
	if o == 's' then input_id = a end
	if o == 'c' then saved_id = true end
    end
    --------------------check -id
    if not saved_id and not id_original and not emarine then 
        if input_id == nil then return oops('       empty EM410x ID string') end
        if #input_id == 0 then return oops('       empty EM410x ID string') end
        if #input_id < 10 then return oops(' EM410x ID too short. Must be 5 hex bytes') end
        if #input_id > 10 then return oops(' EM410x ID too long. Must be 5 hex bytes') end
    end
    core.console('clear')
    print( string.rep('--',39) )
    print(ac.green..'            ....... OFF THE HINTS WILL BE LESS ON THE SCREEN'..ac.reset)
    print( string.rep('--',39) )
    core.console('pref set hint --off')
    print()
    timer(4)
    core.console('clear')
    local hi  = tonumber(input_id:sub(1, 2), 16)
    local low = tonumber(input_id:sub(3, 10), 16)
	if saved_id then
        hi, low = readfile()
        print( string.rep('--',39) )
        print( string.rep('--',39) )
	print('')
        print(ac.green..'             ......Continue cloning from last saved ID'..ac.reset)
    end
    if id_original then
        print( string.rep('--',39) )
        print( string.rep('--',39) )
	print('')
        print(ac.green..'                Put the ELECTRA tag on the coil PM3 to read '..ac.reset)
        print('')
        print( string.rep('--',39))
        print(string.rep('--',39))
    end
	if emarine then
        print( string.rep('--',39) )
        print( string.rep('--',39) )
	print('')
        print(ac.green..'                Put the EM4102 tag on the coil PM3 to read '..ac.reset)
        print('')
        print( string.rep('--',39) )
        print( string.rep('--',39) )
    end
    if emarine or id_original then
       print(ac.yellow..'')
       os.execute("PAUSE")
       print(ac.reset..'')
       print('')
       print('    Readed TAG ID: ')
       core.console('lf em 410x read')
       hi, low = id()
       print('')
       timer(5)
       core.console('clear')
       print( string.rep('--',39) )
       print('')
       print(ac.green..'                   Continuation of the cloning process....'..ac.reset)
       print('')
       print( string.rep('--',39) )
    end
    if not emarine and not id_original and not saved_id then
       print( string.rep('--',39) )
       print( string.rep('--',39) )
       print('')
       print(ac.green..'          ........ ELECTRA cloning from entered EM-ELECTRA ID'..ac.reset)
    end
    local template =('EM410x ID '..ac.green..'%02X%08X'..ac.reset)
    for i = low, low + 100, 1 do
        print('')
        print( string.rep('--',39) )
        local msg = (template):format(hi, low)
        print( string.rep('--',39) )
        if count > 0 then
            print(('  TAGs created: '..ac.green..'%s'..ac.reset):format(count))
        end
	print(('  %s'..ac.reset..' >>>>>>>>cloning to T5577? -'..ac.yellow..' enter'..ac.reset..' for yes or '..ac.yellow..'n'..ac.reset..' for exit'):format(msg))
        print('  Before confirming the cloning operation, put a blank '..ac.cyan..'T5577'..ac.reset..' tag on coil PM3!')
        local ans = utils.input(ac.cyan..' ')
        if ans == 'n' then
            print(ac.reset..'')
            core.console('clear')
            print( string.rep('--',39) )
            print(ac.yellow..'                                  USER ABORTED'..ac.reset)
            print( string.rep('--',39) )
            break
        end
        core.console('clear')
        print(ac.reset..'')
        print( string.rep('--',39) )
        if emarine then
            core.console( ('lf em 410x clone --id %02X%08X'):format(hi, low) )
        else
            core.console( ('lf em 410x clone --id %02X%08X'):format(hi, low) )
            core.console('lf t55 write -b 0 -d 00148080')
            core.console('lf t55 write -b 3 -d 7E1EAAAA')
            core.console('lf t55 write -b 4 -d AAAAAAAA')
        end
        count = count+1
    end
    writefile(hi, low)
    core.console('pref set hint --on')
    print( string.rep('--',39) )
    if count > 0 then
        print( string.rep('--',39) )
        print(('  TAGs created: '..ac.green..'%s'..ac.reset):format(count))
    end
end
main(args)
