--[[
Copyright © 2019, Xathe
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
    * Neither the name of ReadyCheck nor the
    names of its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Xathe BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'ReadyCheck'
_addon.author = 'Xathe (Asura)'
_addon.version = '1.0.0.0'
_addon.commands = {'rc','readycheck'}

config = require('config')
packets = require('packets')
require('logger')
require('sets')
texts = require('texts')

defaults = {}

settings = config.load(defaults)
box = texts.new('${current_string}', settings)
box:show()

default_msg = 'ReadyCheck ' .. string.char(0x81, 0x5D) .. ' '
missing = T{}

function add_party()
    local party = windower.ffxi.get_party()
    for i=0,5 do
        local member = party['p'..i]
        if member then
            missing[member.name] = member.name
        end
    end
    for i=15,25 do
        local member = party['a'..i]
        if member then
            missing[member.name] = member.name
        end
    end
end

function check_key_items(id)
    if S(windower.ffxi.get_key_items())[id] then
        return true
    end
end

function send_chat(msg)
    windower.send_command('input /p ' .. default_msg .. msg)
end

function send_tell(player, msg)
    windower.send_command('input /t ' .. player .. ' ' .. default_msg .. msg)
end

function update_box()
    if missing:length() == 0 then
        box.current_string = ''
    else
        box.current_string = '\\cs(133,163,249)ReadyCheck\\cr\nWaiting for...\n\n' .. table.concat(missing,'\n')
    end
end

windower.register_event('incoming chunk', function(id, data)
    if id == 0x017 then
        local header, mode, gm, zone, sender, message = data:unpack('iCBHS16z')
        if mode == 3 then -- tell
            if message:find(default_msg .. 'Obtained') then
                missing[sender] = nil
                update_box()
            end
        elseif mode == 4 then -- party
            if message:find(default_msg .. 'Tribulens') then
                if check_key_items(2894) then
                    send_tell(sender, 'Obtained')
                end
            elseif message:find('%/') then
                missing[sender] = nil
                update_box()
            end
        end
    end
end)

windower.register_event('addon command', function(cmd, ...)
    local cmd = cmd and cmd:lower()
    
    if cmd == 'clear' or cmd == 'c' then
        missing = T{}
        update_box()
    elseif cmd == 'tribulens' or cmd == 'trib' then
        add_party()
        send_chat('Tribulens')
        update_box()
    else
        error('Invalid command.')
    end
end)
