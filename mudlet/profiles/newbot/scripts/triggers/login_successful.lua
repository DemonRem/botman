--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function loginSuccessful(line)
	-- relogCount is used to detect excessive relogging which is indicative of a server crash.
	if relogCount == nil then relogCount = 0 end

	if string.find(line, "Logon successful.") then
		botman.botOfflineCount = 0
		relogCount = relogCount + 1
		botman.botOffline = false
		botman.botConnectedTimestamp = os.time() -- used to measure how long the bot has been offline so we can slow down how often it tries to reconnect.
		irc_chat(server.ircMain, "Successfully logged in and monitoring server traffic.")
		botman.getMetrics = false
		metrics = nil
	end

	-- we need to know that we can actually send telnet commands.  Simply being able to login doesn't mean telnet is working. We pick on gt because it is a 1 line response.
	tempTimer(2, [[ send("gt") ]])
end
