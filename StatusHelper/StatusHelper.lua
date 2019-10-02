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
    * Neither the name of StatusHelper nor the
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

_addon.name = 'StatusHelper'
_addon.author = 'Xathe (Asura)'
_addon.version = '1.0.0.0'
_addon.commands = {'sts','statushelper'}

config = require('config')
packets = require('packets')
res = require('resources')
texts = require('texts')
require('logger')

defaults = {}
defaults.interval = .1

settings = config.load(defaults)
box = texts.new('${current_string}', settings)
box:show()

frame_time = 0
player_buffs = {}
party_buffs = {}

whitelist = {
    [2]   = 'Sleep',
    [3]   = 'Poison',
    [4]   = 'Paralyze',
    [5]   = 'Blind',
    [6]   = 'Silence',
    [7]   = 'Petrify',
    [8]   = 'Disease',
    [9]   = 'Curse',
    [11]  = 'Bind',
    [12]  = 'Gravity',
    [13]  = 'Slow',
    [15]  = 'Doom',
    [18]  = 'Gradual Petrify',
    [19]  = 'Sleep',
    [31]  = 'Plague',
    [134] = 'Dia',
    [135] = 'Bio',
    [136] = 'STR Down',
    [137] = 'DEX Down',
    [140] = 'INT Down',
    [144] = 'Max HP Down',
    [146] = 'Accuracy Down',
    [147] = 'Attack Down',
    [149] = 'Defence Down',
    [167] = 'Magic Def. Down',
    [194] = 'Song',
    [557] = 'Attack Down',
    [558] = 'Defence Down',
    [560] = 'Magic Def. Down',
    [561] = 'Accuracy Down',
    [564] = 'Magic Evasion Down',
    [565] = 'Slow',
    [567] = 'Gravity'
}

removals = {
    [2]   = 'Curaga',
    [3]   = 'Poisona',
    [4]   = 'Paralyna',
    [5]   = 'Blindna',
    [6]   = 'Silena',
    [7]   = 'Stona',
    [8]   = 'Viruna',
    [9]   = 'Cursna',
    [11]  = 'Erase',
    [12]  = 'Erase',
    [13]  = 'Erase',
    [15]  = 'Cursna',
    [18]  = 'Stona',
    [19]  = 'Curaga',
    [31]  = 'Viruna',
    [134] = 'Erase',
    [135] = 'Bio',
    [136] = 'Erase',
    [137] = 'Erase',
    [140] = 'Erase',
    [144] = 'Erase',
    [146] = 'Erase',
    [147] = 'Erase',
    [149] = 'Erase',
    [167] = 'Erase',
    [194] = 'Erase',
    [557] = 'Erase',
    [558] = 'Erase',
    [560] = 'Erase',
    [561] = 'Erase',
    [564] = 'Erase',
    [565] = 'Erase',
    [567] = 'Erase'
}

function update_box()
    local lines = L{}
    
    if #player_buffs > 0 then
        lines:append('\n[You]')
        for _,v in ipairs(player_buffs) do
            lines:append(whitelist[v])
        end
    end
    
    for k,v in pairs(party_buffs) do
        if not v.name then
            local t = windower.ffxi.get_mob_by_id(k)
            if t then v.name = t.name end
        end
        if #v.buffs > 0 then
            lines:append('\n[%s]':format(v.name or 'Unknown'))
            for x,y in pairs(v.buffs) do
                lines:append(whitelist[y])
            end
        end
    end
    
    if lines:length() == 0 then
        box.current_string = ''
    else
        box.current_string = 'Status Effects\n' .. lines:concat('\n')
    end
end

function parse_player(data)
    if data:byte(0x05) == 0x09 then
        player_buffs = {}
        for i=1,32 do
            local buff = data:unpack('H',i*2+7)
            if whitelist[buff] then
                table.insert(player_buffs, buff)
            end
        end
    end
end

function parse_buffs(data)
    party_buffs = {}
    for i = 0,4 do
        if data:unpack('I',i*48+5) == 0 then
            break
        else
            local id = data:unpack('I', i*48+5)
            
            if id == 0 then
                break
            else
                party_buffs[id] = { buffs = { } }
                for n=1,32 do
                    local buff = data:byte(i*48+5+16+n-1) + 256*( math.floor( data:byte(i*48+5+8+ math.floor((n-1)/4)) / 4^((n-1)%4) )%4)
                    
                    if buff == 255 then
                        break
                    elseif whitelist[buff] then
                        table.insert(party_buffs[id].buffs, buff)
                    end
                end
            end
        end
    end
end

function remove_debuffs(t)
    local target = t and windower.ffxi.get_mob_by_name(t) or windower.ffxi.get_mob_by_target('t')
    local id = target and target.id or 0
    
    -- Check that we have a valid target
    if not target then return end
    
    -- Remove the target's statuses
    if player_name and target.name == player_name then
        for _,v in ipairs(player_buffs) do
            if removals[v] then
                windower.send_command('input /ma "%s" <me>':format(removals[v]))
                return
            end
        end
    else
        if party_buffs[id] then
            for _,v in ipairs(party_buffs[id].buffs) do
                if removals[v] then
                    windower.send_command('input /ma "%s" %s':format(removals[v], t and target.name or '<t>'))
                    return
                end
            end
        end
    end
end

windower.register_event('load','login', function()
    if windower.ffxi.get_info().logged_in then
        local player = windower.ffxi.get_player()
        if player then
            player_name = player.name
        end
    end
end)

windower.register_event('logout','zone change', function()
    party_buffs = {}
end)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x063 then
        parse_player(data)
    elseif id == 0x076 then
        parse_buffs(data)
    end
end)

windower.register_event('prerender', function()
    local curr = os.clock()
    if curr > frame_time + settings.interval then
        frame_time = curr
        update_box()
    end
end)

windower.register_event('addon command', function(cmd, target, ...)
    if cmd == 'remove' or cmd == 'r' then
        remove_debuffs(target)
    end
end)
