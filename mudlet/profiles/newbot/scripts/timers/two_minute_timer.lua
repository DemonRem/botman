--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function twoMinuteTimer()
	-- to fix a weird bug where the bot would stop responding to chat but could be woken up by irc chatter we send the bot a wake up call
	irc_chat(server.ircBotName, "Keep alive")

	removeBadPlayerRecords()

	if server.scanErrors and server.coppi then
		for k,v in pairs(igplayers) do
			send("rcd " .. math.floor(v.xPos) .. " " .. math.floor(v.zPos))

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end
		end
	end

	-- logout anyone on irc who hasn't typed anything and their session has expired
	for k,v in pairs(players) do
		if v.ircAuthenticated == true then
			if v.ircSessionExpiry == nil then
				v.ircAuthenticated = false
				if botman.dbBotsConnected then connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. k) end
			else
				if (v.ircSessionExpiry - os.time()) < 0 then
					v.ircAuthenticated = false
					if botman.dbBotsConnected then connBots:execute("UPDATE players SET ircAuthenticated = 0 WHERE steam = " .. k) end
				end
			end
		end
	end
end
