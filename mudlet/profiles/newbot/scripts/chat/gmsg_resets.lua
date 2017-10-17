--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gmsg_resets()
	calledFunction = "gmsg_resets"

	local region, x, z, debug
	local shortHelp = false
	local skipHelp = false

	debug = false

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "resets" then
				skipHelp = true
			end
		end

		if chatvars.words[1] == "help" then
			skipHelp = false
		end

		if chatvars.words[1] == "list" then
			shortHelp = true
		end
	end

	if chatvars.showHelp and not skipHelp and chatvars.words[1] ~= "help" then
		irc_chat(players[chatvars.ircid].ircAlias, " ")
		irc_chat(players[chatvars.ircid].ircAlias, "Reset Zone Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "====================")
		irc_chat(players[chatvars.ircid].ircAlias, " ")
		irc_chat(players[chatvars.ircid].ircAlias, "Regions can be marked as reset zones to warn players not to build in them.")
		irc_chat(players[chatvars.ircid].ircAlias, "It will block setbase and sethome and any claims placed by players are removed.")
		irc_chat(players[chatvars.ircid].ircAlias, "Currently the bot does not have the ability to physically delete region files but it can provide a list of reset zones for manual deletion.")
		irc_chat(players[chatvars.ircid].ircAlias, " ")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "resets")
	end

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and chatvars.words[3] == "zones"  or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "clear reset zones")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The bot will forget all the reset zones so you can start over marking new ones.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if ((chatvars.words[1] == "clear" or chatvars.words[1] == "reset" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and chatvars.words[3] == "zones") then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end
		else
			if (accessLevel(chatvars.ircid) > 2) then
				irc_chat(players[chatvars.ircid].ircAlias, "This command is restricted.")
				botman.faultyChat = false
				return true
			end
		end

		resetRegions = {}
		conn:execute("DELETE FROM resetZones")
		conn:execute("UPDATE keystones SET remove = 0") -- clear the remove flag from the keystones table to prevent removals that we don't want.

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]All reset zones have been forgotten.[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "All reset zones have been forgotten.")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	-- Add the following condition to any commands added below here:  and (chatvars.playerid ~= 0)

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "add") or string.find(chatvars.command, "remo") or string.find(chatvars.command, "dele") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "regi") or string.find(chatvars.command, "zone") or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "add reset zone")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "remove reset zone")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Flag or unflag an entire region as a reset zone.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if ((chatvars.words[1] == "add" or chatvars.words[1] == "remove" or chatvars.words[1] == "delete") and chatvars.words[2] == "reset" and (chatvars.words[3] == "region" or chatvars.words[3] == "zone")) and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 3) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		x = math.floor(igplayers[chatvars.playerid].xPos / 512)
		z = math.floor(igplayers[chatvars.playerid].zPos / 512)
		region = "r." .. x .. "." .. z .. ".7rg"

		if (chatvars.words[1] == "add") then
			resetRegions[region] = {}
			conn:execute("INSERT INTO resetZones (region) VALUES ('" .. region .. "')")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Region " .. region .. " is now a reset zone.[-]")
		else
			resetRegions[region] = nil
			conn:execute("DELETE FROM resetZones WHERE region = '" .. region .. "'")
			conn:execute("UPDATE keystones SET remove = 0") -- clear the remove flag from the keystones table to prevent removals that we don't want.
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Region " .. region .. " is no longer a reset zone.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug resets line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if string.find(chatvars.command, "reset") or string.find(chatvars.command, "zone") or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "reset zones")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List all of the regions that are reset zones.")
				irc_chat(players[chatvars.ircid].ircAlias, " ")
			end
		end
	end

	if (chatvars.words[1] == "reset" and chatvars.words[2] == "zones") and (chatvars.playerid ~= 0) then
		if (chatvars.accessLevel > 2) then
			message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
			botman.faultyChat = false
			return true
		end

		cursor,errorString = conn:execute("select * from resetZones")
		rows = cursor:numrows()

		if rows == 0 then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No regions have been flagged as reset zones.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The following regions are reset zones:[-]")

			row = cursor:fetch({}, "a")
			while row do
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.region .. "[-]")
				row = cursor:fetch(row, "a")
			end
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug resets end") end

end
