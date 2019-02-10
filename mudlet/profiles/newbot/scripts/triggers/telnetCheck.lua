--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function flagTelnetOnline()
	botman.lastServerResponseTimestamp = os.time()
	botman.lastTelnetResponseTimestamp = os.time()
	botman.telnetOffline = false
	botman.telnetOfflineCount = 0
end