local getopt = require('getopt')
local ansicolors = require('ansicolors')

copyright = 'Iceman'
author = 'Iceman'
version = 'v0.9.9'
desc = [[
This is scripts loops though a tear attack and reads expected value.
]]
example = [[
    1. script run tearoff -n 2 -s 200 -e 400 -a 5
]]
usage = [[
script run tearoff [-h] [-n <steps us>] [-a <addr>]  [-p <pwd>]  [-s <start us>]  [-e <end us>]
]]
arguments = [[
    -h                 This help
    -n <steps us>      steps in mili seconds for each tearoff
    -a <addr>          address to target on card
    -p <pwd>           (optional) use a password
    -s <delay us>      inital start delay
    -e <delay us>      end delay, must be larger than start delay
    end
]]

---
-- This is only meant to be used when errors occur
local function oops(err)
    print('ERROR:', err)
    core.clearCommandBuffer()
    return nil, err
end
---
-- Usage help
local function help()
    print(copyright)
    print(author)
    print(version)
    print(desc)
    print(ansicolors.cyan..'Usage'..ansicolors.reset)
    print(usage)
    print(ansicolors.cyan..'Arguments'..ansicolors.reset)
    print(arguments)
    print(ansicolors.cyan..'Example usage'..ansicolors.reset)
    print(example)
end

local function main(args)

    --[[
    Basically do the following,
    
    1. hw tear
    2. lf em 4x05_write 
    3. lf em 4x05_read
    
    The first two commands doesn't need a feedback from the system, so going with core.console commands.
    Since the read needs demodulation of signal I opted to add that function from cmdlfem4x.c to the core lua scripting
        core.em4x05_read(addr, password)
    
    --]]
    local n, addr, password, sd, ed
    
    for o, a in getopt.getopt(args, 'he:s:a:p:n:') do
        if o == 'h' then return help() end
        if o == 'n' then n = a end
        if o == 'a' then addr = a end
        if o == 'p' then password = a end
        if o == 'e' then ed = tonumber(a) end
        if o == 's' then sd = tonumber(a) end
    end

   
    addr = addr or 5
    password = password or ''
    n = n or 2
    sd = sd or 2000
    ed = ed or 2100

    if #password ~= 8 then
        password = ''
    end
    
    if sd > ed then
        return oops('start delay cant be larger than end delay', sd, ed)
    end
    
    print('Starting EM4x05 tear off')
    print('target addr', addr)
    if password then
        print('target pwd', password)
    end
    print('target stepping', n)
    print('target delay')
    print('', sd, ed)
    
    local res_tear = 0
    local res_nowrite = 0
    
    local set_tearoff_delay = 'hw tearoff --delay %d'
    local enable_tearoff = 'hw tearoff --on'
    
    for step = sd, ed, n do
    
        io.flush()
        if core.kbd_enter_pressed() then
            print("aborted by user")
            break
        end

        core.clearCommandBuffer()
        
        local c = set_tearoff_delay:format(step)
        core.console(c);
        core.console(enable_tearoff)
        if #password == 8 then
            c = ('lf em 4x05_write %s ffffffff %s'):format(addr, password)
        else
            c = ('lf em 4x05_write %s ffffffff'):format(addr)
        end        
        core.console(c)
        local word, err =  core.em4x05_read(addr, password)
        if err then
            return oops(err)
        end
        
        if word ~= 0xFFFFFFFF then
            if word ~= 0 then
                print((ansicolors.red..'TEAR OFF occured:'..ansicolors.reset..' %08X'):format(word))
                res_tear = res_tear + 1
            else
                print((ansicolors.cyan..'TEAR OFF occured:'..ansicolors.reset..' %08X'):format(word))
                res_nowrite = res_nowrite + 1
            end
        else
            print((ansicolors.green..'Good write occured:'..ansicolors.reset..' %08X'):format(word))
        end
        
        if password then
            c = ('lf em 4x05_write %s 00000000 %s'):format(addr, password)
        else
            c = ('lf em 4x05_write %s 00000000'):format(addr)
        end  
        core.console(c)
        
        if res_tear == 5 then
            print(('No of no writes %d'):format(res_nowrite))
            return oops('five times tear off,  shutting down')
        end
    end
end

--[[
In the future, we may implement so that scripts are invoked directly
into a 'main' function, instead of being executed blindly. For future
compatibility, I have done so, but I invoke my main from here.
--]]
main(args)
