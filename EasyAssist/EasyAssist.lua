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
    * Neither the name of EasyAssist nor the
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

_addon.name = 'EasyAssist'
_addon.author = 'Xathe (Asura)'
_addon.version = '1.0.0.1'
_addon.commands = {'ea','easyassist'}

require('logger')
packets = require('packets')

windower.register_event('addon command', function(name)
    if not name then
        error('You must specify a player\'s name.')
        return
    else
        name = name:gsub('^%l', string.upper)
    end
    
    local assist = windower.ffxi.get_mob_by_name(name)
    if not assist then
        error('Couldn\'t find player %s.':format(name))
        return
    elseif not assist.in_party and not assist.in_alliance then
        error('That player is not in your group.')
        return
    end
    
    local target = windower.ffxi.get_mob_by_index(assist.target_index)
    if not target then
        error('That player doesn\'t have a target.')
        return
    elseif not target.is_npc or target.spawn_type ~= 16 then
        error('Player\'s target is not an enemy.')
        return
    end
    
    local player = windower.ffxi.get_player()
    if player.status == 0 then
        packets.inject(packets.new('outgoing', 0x01A, {
            ['Target'] = target.id,
            ['Target Index'] = target.index,
            ['Category'] = 2,
            ['Param'] = 0
        }))
        log('Attacking %s.':format(target.name))
    elseif player.status == 1 then
        packets.inject(packets.new('outgoing', 0x01A, {
            ['Target'] = target.id,
            ['Target Index'] = target.index,
            ['Category'] = 15,
            ['Param'] = 0
        }))
        log('Switching target to %s.':format(target.name))
    else
        error('Unable to target due to player status.')
    end
end)
