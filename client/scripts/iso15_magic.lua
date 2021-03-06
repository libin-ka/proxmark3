local cmds = require('commands')
local lib15 = require('read15')
local getopt = require('getopt')
local utils =  require('utils')

copyright = 'Copyright (c) 2018 IceSQL AB. All rights reserved.'
author = 'Christian Herrmann'
version = 'v1.0.3'
desc = [[
This script tries to set UID on a IS15693 SLIX magic card 
Remember the UID  ->MUST<- start with 0xE0
 ]]
example = [[

	 -- ISO15693 slix magic tag

	 script run iso15_magic -u E004013344556677
]]
usage = [[
script run iso15_magic -h -u <uid>

Arguments:
	-h             : this help
	-u <UID>       : UID (16 hexsymbols)
]]

local DEBUG = true
--- 
-- A debug printout-function
local function dbg(args)
    if not DEBUG then return end
    if type(args) == "table" then
		local i = 1
		while args[i] do
			dbg(args[i])
			i = i+1
		end
	else
		print("###", args)
	end	
end	
--- 
-- This is only meant to be used when errors occur
local function oops(err)
	print("ERROR: ",err)
	return nil, err
end
--- 
-- Usage help
local function help()
	print(copyright)
	print(author)	
	print(version)	
	print(desc)
	print('Example usage')
	print(example)
end
--
--- Set UID on magic command enabled on a ICEMAN based REPO
local function magicUID_iceman(b0, b1)
	print('Using backdoor Magic tag function')
 	core.console("hf 15 raw -2 -c 02213E00000000")
	core.console("hf 15 raw -2 -c 02213F69960000")		
	core.console("hf 15 raw -2 -c 022138"..b1)
	core.console("hf 15 raw -2 -c 022139"..b0)
end
--
--- Set UID on magic command enabled,  OFFICAL REPO
local function magicUID_offical(b0, b1)
	print('Using backdoor Magic tag function OFFICAL REPO')
 	core.console("hf 15 cmd raw -c 02213E00000000")
	core.console("hf 15 cmd raw -c 02213F69960000")		
	core.console("hf 15 cmd raw -c 022138"..b1)
	core.console("hf 15 cmd raw -c 022139"..b0)
end
--- 
-- The main entry point
function main(args)

	print( string.rep('--',20) )
	print( string.rep('--',20) )	
	print()

	local uid = 'E004013344556677'
	
	-- Read the parameters
	for o, a in getopt.getopt(args, 'hu:') do
		if o == "h" then return help() end
		if o == "u" then uid = a end
	end	
	
	-- uid string checks
	if uid == nil then return oops('empty uid string') end
	if #uid == 0 then return oops('empty uid string') end
	if #uid ~= 16 then return oops('uid wrong length. Should be 8 hex bytes') end

	local bytes = utils.ConvertHexToBytes(uid)
	
	local block0 = string.format('%02X%02X%02X%02X', bytes[4], bytes[3], bytes[2], bytes[1])
	local block1 = string.format('%02X%02X%02X%02X', bytes[8], bytes[7], bytes[6], bytes[5])
	
	print('new UID | '..uid)
	
	core.clearCommandBuffer()
	
	magicUID_iceman(block0, block1)
	--magicUID_offical(block0, block1)
end

main(args)
