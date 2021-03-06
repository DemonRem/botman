--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- if you have oper status on your irc server, you can set channel modes.  This one sets flood protection to 5000 chars in 1 second which should prevent the bot from getting banned for flooding.
-- /mode #channel +f [5000t#b]:1

-- /mode #mychannel +k mypassword
--

local debug = false -- should be false unless testing
local debugAdmin = false -- does not give unrestricted access to critical functions, mostly info.

function getNick()
	server.ircBotName = ircGetNick()
end


function secureIRCChannels()
	sendIrc("", "/join " .. server.ircMain .. " " .. server.ircMainPassword)
	sendIrc("", "/join " .. server.ircAlerts .. " " .. server.ircAlertsPassword)
	sendIrc("", "/join " .. server.ircWatch .. " " .. server.ircWatchPassword)

	--sendIrc("", "/mode +s " .. server.ircMain)
	if server.ircMainPassword ~= "" then
		sendIrc("", "/mode " .. server.ircMain .. " +k " .. server.ircMainPassword)
	end

	--sendIrc("", "/mode +s " .. server.ircAlerts)
	if server.ircAlertsPassword ~= "" then
		sendIrc("", "/mode " .. server.ircAlerts .. " +k " .. server.ircAlertsPassword)
	end

	--sendIrc("", "/mode +s " .. server.ircWatch)
	if server.ircWatchPassword ~= "" then
		sendIrc("", "/mode " .. server.ircWatch .. " +k " .. server.ircWatchPassword)
	end
end


function joinIRCServer()
	local channels = {}

	if not server.ircPort or not server.ircServer then
		return
	end

	-- delete some Mudlet files that store IP and other info forcing Mudlet to regenerate them.
	os.remove(homedir .. "/irc_host")
	os.remove(homedir .. "/irc_port")
	os.remove(homedir .. "/irc_server_port")

	-- Do not allow the bot to automatically connect to Freenode.
	if server.ircServer then
		if string.find(string.lower(server.ircServer), "freenode") then
			server.ircServer = "127.0.0.1"
		end
	end

	if setIrcServer ~= nil then
		table.insert(channels, server.ircMain)
		table.insert(channels, server.ircAlerts)
		table.insert(channels, server.ircWatch)

		setIrcServer(server.ircServer, server.ircPort)
		setIrcChannels(channels)
		tempTimer(5, [[restartIrc()]])
		tempTimer(7, [[secureIRCChannels()]])
	else
		ircSetHost(server.ircServer, server.ircPort)

		tempTimer( 1, [[ircJoin("]] .. server.ircAlerts .. [[")]] )
		tempTimer( 2, [[ircJoin("]] .. server.ircWatch .. [[")]] )
		tempTimer( 3, [[ircReconnect()]] )

		if server.ircBotName == "Bot" then
			server.ircBotName = getNick()
		end

		ircSetChannel(server.ircMain)
		ircSaveSessionConfigs()
	end

	if server.ircBotName then
		if server.ircBotName ~= "Bot" then
			if ircSetNick ~= nil then
				-- TheFae's modded mudlet
				ircSetNick(server.ircBotName)
			end

			if setIrcNick ~= nil then
				-- Mudlet 3.x
				setIrcNick(server.ircBotName)
			end
		end
	end
end


function irc_chat(name, msg)
	local multilineText, k, v

	-- Don't allow the bot to command itself
	if name == server.botName then
		return
	end

	if not msg then
		return
	end

	-- replace any placeholder text with actual values
	msg = msg:gsub("{#}", server.commandPrefix)
	msg = msg:gsub("{server}", server.serverName)
	msg = msg:gsub("{money}", server.moneyName)
	msg = msg:gsub("{monies}", server.moneyPlural)

	multilineText = string.split(msg, "\n")

	for k,v in pairs(multilineText) do
		if botman.registerHelp then
			file = io.open(homedir .. "/temp/help.txt", "a")

			if v == "." then
				v = ""
			else
				v = string.trim(v)
			end

			file:write(v .. "\n")
			file:close()
		else
			connMEM:execute("INSERT INTO ircQueue (name, command) VALUES ('" .. name .. "','" .. connMEM:escape(v) .. "')")
		end

		if name == server.ircAlerts then
			logAlerts(botman.serverTime, v)
		end
	end

	botman.ircQueueEmpty = false
	enableTimer("ircQueue")
end


function irc_reportDiskFree(name)
	local s
	local f = io.popen("df -h") -- run df -h

	repeat
	  s = f:read ("*l") -- read one line
	  if s then  -- if not end of file (EOF)
	   if string.find(s, "Filesystem") or string.find(s, "/dev/") and not string.find(s, "tmpfs") then irc_chat(name, s) end
	  end
	until not s  -- until end of file

	f:close()
end


function irc_NewInventory(tmp)
	local rows, i, max

	if tmp.trackerID then
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. tmp.playerID .." AND inventoryTrackerID = " .. tmp.trackerID)
	else
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. tmp.playerID .." ORDER BY inventoryTrackerid DESC Limit 1")
	end

	row = cursor:fetch({}, "a")
	if row then
		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "Belt of " .. players[tmp.playerID].name)

		tmp.inventory = string.split(row.belt, "|")

		max = table.maxn(tmp.inventory)-1
		for i=1, max, 1 do
			tmp.slot = string.split(tmp.inventory[i], ",")
			if tonumber(tmp.slot[4]) > 0 then
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3] .. " " .. tmp.slot[4])
			else
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3])
			end
		end

		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "Backpack of " .. players[tmp.playerID].name)

		tmp.inventory = string.split(row.pack, "|")

		max = table.maxn(tmp.inventory)-1
		for i=1, max, 1 do
			tmp.slot = string.split(tmp.inventory[i], ",")
			if tonumber(tmp.slot[4]) > 0 then
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3] .. " " .. tmp.slot[4])
			else
				irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " qty " .. tmp.slot[2] .. " " .. tmp.slot[3])
			end
		end

		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "Equipment of " .. players[tmp.playerID].name)

		tmp.inventory = string.split(row.equipment, "|")

		max = table.maxn(tmp.inventory)-1
		for i=1, max, 1 do
			tmp.slot = string.split(tmp.inventory[i], ",")
			irc_chat(tmp.name, "Slot " .. tmp.slot[1] .. " " .. tmp.slot[2] .. " " .. tmp.slot[3])
		end
	else
		irc_chat(tmp.name, ".")
		irc_chat(tmp.name, "I do not have an inventory recorded for " .. players[tmp.playerID].name)
	end

	irc_chat(tmp.name, ".")
end


function irc_ListTables()
	irc_chat(irc_params.name, "These are the bot tables that you can view and edit:")
	irc_chat(irc_params.name, "botman")
	irc_chat(irc_params.name, "server")
	irc_chat(irc_params.name, "rollingMessages")
	irc_chat(irc_params.name, "whitelist")
	irc_chat(irc_params.name, "----")
end


function irc_ListBases(steam)
	local prot1, prot2, msg, cursor, errorString, row

	if steam ~= nil then
		cursor,errorString = conn:execute("SELECT steam, name, bedX, bedY, bedZ, homeX, homeY, homeZ, home2X, home2Y, home2Z, protect, protect2, protectSize, protect2Size from players where steam = " .. steam .. " order by name")
	else
		cursor,errorString = conn:execute("SELECT steam, name, bedX, bedY, bedZ, homeX, homeY, homeZ, home2X, home2Y, home2Z, protect, protect2, protectSize, protect2Size from players order by name")
	end

	row = cursor:fetch({}, "a")
	while row do
		prot1 = "OFF"
		prot2 = "OFF"

		if row.protect == "1" then prot1 = "ON" end
		if row.protect2 == "1" then prot2 = "ON" end
		msg = row.steam .. " " .. row.name .. " "

		if tonumber(row.homeX) == 0 and tonumber(row.homeY) == 0 and tonumber(row.homeZ) == 0 and tonumber(row.home2X) == 0 and tonumber(row.home2Y) == 0 and tonumber(row.home2Z) == 0 then
			if steam ~= nil then
				msg = msg .. "has no base set"
			else
				msg = nil
			end
		else
			msg = msg .. row.homeX .. " " .. row.homeY .. " " .. row.homeZ .. " " .. prot1 .. " (" .. row.protectSize .. ") "
			msg = msg .. row.home2X .. " " .. row.home2Y .. " " .. row.home2Z .. " " .. prot2 .. " (" .. row.protect2Size .. ") "
		end


		if msg ~= nil then
			if tonumber(row.bedX) == 0 and tonumber(row.bedY) == 0 and tonumber(row.bedZ) == 0 then
				msg = msg .. " no bedroll recorded"
			else
				msg = msg .. " bedroll " .. row.bedX .. " " .. row.bedY .. " " .. row.bedZ
			end
		end

		if irc_params.filter == "protected" and (row.protect == "1" or row.protect2 == "1") then
			if msg ~= nil then
				irc_chat(irc_params.name, msg)
			end
		end

		if irc_params.filter ~= "protected" then
			if msg ~= nil then
				irc_chat(irc_params.name, msg)
			end
		end

		row = cursor:fetch(row, "a")
	end

	irc_chat(irc_params.name, ".")
end


function irc_PlayersNearPlayer(name, name1, range, xPos, zPos, offline, otherTarget)
	local alone, dist, number, flag

	alone = true

	if offline == false then
		if name1 ~= "" then
			irc_chat(name, "Players within " .. range .. " meters of " .. players[name1].name .. " are:")
		end

		if otherTarget ~= nil then
			irc_chat(name, "Players within " .. range .. " meters of " .. otherTarget .. " are:")
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "Players within " .. range .. " meters of x " .. xPos .. " z " .. zPos .. " are:")
		end

		for k, v in pairs(igplayers) do
			if k ~= name1 then
				if name1 ~= "" then
					dist = distancexz(players[name1].xPos, players[name1].zPos, v.xPos, v.zPos)
				else
					dist = distancexz(xPos, zPos, v.xPos, v.zPos)
				end

				if dist <= range then
					irc_chat(name, v.name .. " steam: " .. k .. " distance: " .. string.format("%-4.2d", dist) .. " meters")
					alone = false
				end
			end
		end
	else
		if name1 ~= "" then
			irc_chat(name, "Players within " .. range .. " meters of " .. players[name1].name .. " including offline are:")
		end

		if otherTarget ~= nil then
			irc_chat(name, "Players within " .. range .. " meters of " .. otherTarget .. " including offline are:")
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "Players within " .. range .. " meters of x " .. xPos .. " z " .. zPos .. " including offline are:")
		end

		for k, v in pairs(players) do
			if k ~= name1 then
				if name1 ~= "" then
					dist = distancexz(players[name1].xPos, players[name1].zPos, v.xPos, v.zPos)
				else
					dist = distancexz(xPos, zPos, v.xPos, v.zPos)
				end

				if dist <= range then
					if igplayers[k] then
						flag = " PLAYING"
					else
						flag = " OFFLINE"
					end

					irc_chat(name, v.name .. " steam: " .. k .. " distance: " .. string.format("%-4.2d", dist) .. " meters" .. flag)
					alone = false
				end
			end
		end
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There is nobody within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "Players within " .. range .. " meters of " .. otherTarget .. " including offline are:")
			irc_chat(name, "There is nobody within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There is nobody within " .. range .. " meters of x " .. xPos .. " z " .. zPos)
		end
	end

	irc_chat(name, ".")
end


function irc_BasesNearPlayer(name, name1, range, xPos, zPos, otherTarget)
	local alone, dist, protected

	alone = true

	if name1 ~= "" then
		irc_chat(name, "Bases within " .. range .. " meters of " .. players[name1].name .. " are:")
	end

	if otherTarget ~= nil then
		irc_chat(name, "Bases within " .. range .. " meters of " .. otherTarget .. " are:")
	end

	if name1 == "" and otherTarget == nil then
		irc_chat(name, "Bases within " .. range .. " meters of " .. players[name].name .. " are:")
	end

	for k, v in pairs(players) do
		if (v.homeX ~= 0 and v.homeZ ~= 0) then
			if name1 ~= "" then
				dist = distancexz(players[name1].xPos, players[name1].zPos, v.homeX, v.homeZ)
			else
				dist = distancexz(xPos, zPos, v.homeX, v.homeZ)
			end

			if dist <= tonumber(range) then
				if players[k].protect == true then
					protected = " bot protected"
				else
					protected = " unprotected"
				end

				irc_chat(name, v.name .. " steam: " .. k .. " distance: " .. string.format("%-.2d", dist) .. " meters" .. protected)
				alone = false
			end
		end

		if (v.home2X ~= 0 and v.home2Z ~= 0) then
			if name1 ~= "" then
				dist = distancexz(players[name1].xPos, players[name1].zPos, v.home2X, v.home2Z)
			else
				dist = distancexz(xPos, zPos, v.home2X, v.home2Z)
			end

			if dist <= tonumber(range) then
				if players[k].protect2 == true then
					protected = " bot protected"
				else
					protected = " unprotected"
				end

				irc_chat(name, v.name .. " steam: " .. k .. " (base 2) distance: " .. string.format("%-.2d", dist) .. " meters" .. protected)
				alone = false
			end
		end
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name].name)
		end
	end

	irc_chat(name, ".")
end


function irc_LocationsNearPlayer(name, name1, range, xPos, zPos, otherTarget)
	local alone, dist

	alone = true

	if name1 ~= "" then
		irc_chat(name, "Locations within " .. range .. " meters of " .. players[name1].name .. " are:")
	end

	if otherTarget ~= nil then
		irc_chat(name, "Locations within " .. range .. " meters of " .. otherTarget .. " are:")
	end

	if name1 == "" and otherTarget == nil then
		irc_chat(name, "Locations within " .. range .. " meters of " .. players[name].name .. " are:")
	end

	for k, v in pairs(locations) do
		if name1 ~= "" then
			dist = distancexz(players[name1].xPos, players[name1].zPos, v.x, v.z)
		else
			dist = distancexz(xPos, zPos, v.x, v.z)
		end

		if dist <= tonumber(range) then
			irc_chat(name, v.name .. " distance: " .. string.format("%-.2d", dist) .. " meters")
			alone = false
		end
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name].name)
		end
	end

	irc_chat(name, ".")
end


function irc_EntitiesNearPlayer(name, name1, range, xPos, zPos, otherTarget)
	local alone, dist, cursor, errorString, row

	alone = true

	if name1 ~= "" then
		irc_chat(name, "Entities within " .. range .. " meters of " .. players[name1].name .. " are:")
	end

	if otherTarget ~= nil then
		irc_chat(name, "Entities within " .. range .. " meters of " .. otherTarget .. " are:")
	end

	if name1 == "" and otherTarget == nil then
		irc_chat(name, "Entities within " .. range .. " meters of " .. players[name].name .. " are:")
	end

	cursor,errorString = connMEM:execute("SELECT * FROM memEntities WHERE type <> 'EntityPlayer'")

	row = cursor:fetch({}, "a")
	while row do
		if name1 ~= "" then
			dist = distancexz(players[name1].xPos, players[name1].zPos, row.x, row.z)
		else
			dist = distancexz(xPos, zPos, row.x, row.z)
		end

		if dist <= tonumber(range) then
			irc_chat(name, row.name .. " id: " .. row.entityID .. " distance: " .. string.format("%-.2d", dist))
			alone = false
		end

		row = cursor:fetch(row, "a")
	end

	if (alone == true) then
		if name1 ~= "" then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name1].name)
		end

		if otherTarget ~= nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. otherTarget)
		end

		if name1 == "" and otherTarget == nil then
			irc_chat(name, "There are none within " .. range .. " meters of " .. players[name].name)
		end
	end

	irc_chat(name, ".")
end


function irc_PlayerShortInfo()
	local time, days, hours, minutes, donor, expiry

	if (debug) then dbug("debug irc functions line " .. debugger.getinfo(1).currentline) end

	donor, expiry = isDonor(irc_params.pid)

	if (igplayers[irc_params.pid]) then
		time = tonumber(players[irc_params.pid].timeOnServer) + tonumber(igplayers[irc_params.pid].sessionPlaytime)
	else
		time = tonumber(players[irc_params.pid].timeOnServer)
	end

	if (debug) then dbug("debug irc functions line " .. debugger.getinfo(1).currentline) end

	days = math.floor(time / 86400)

	if (days > 0) then
		time = time - (days * 86400)
	end

	hours = math.floor(time / 3600)

	if (hours > 0) then
		time = time - (hours * 3600)
	end

	minutes = math.floor(time / 60)
	time = time - (minutes * 60)

	if (debug) then dbug("debug irc functions line " .. debugger.getinfo(1).currentline) end

	irc_chat(irc_params.name, "Info for player " .. irc_params.pname)
	if players[irc_params.pid].newPlayer == true then irc_chat(irc_params.name, "A new player") end
	irc_chat(irc_params.name, "SteamID " .. irc_params.pid)
	irc_chat(irc_params.name, "Steam Rep http://steamrep.com/search?q=" .. irc_params.pid)
	irc_chat(irc_params.name, "Steam http://steamcommunity.com/profiles/" .. irc_params.pid)

	if irc_params.pid ~= players[irc_params.pid].steamOwner then
		irc_chat(irc_params.name, ".")
		irc_chat(irc_params.name, "Family Key:")
		irc_chat(irc_params.name, "CBSM GBL https://gbl.envul.com/lookup/" .. players[irc_params.pid].steamOwner .. "/")
		irc_chat(irc_params.name, "Steam Rep http://steamrep.com/search?q=" .. players[irc_params.pid].steamOwner)
		irc_chat(irc_params.name, "Steam http://steamcommunity.com/profiles/" .. players[irc_params.pid].steamOwner)
		irc_chat(irc_params.name, ".")
	end

	irc_chat(irc_params.name, "Player ID " .. players[irc_params.pid].id)
	if players[irc_params.pid].firstSeen ~= nil then irc_chat(irc_params.name, "First seen: " .. os.date("%Y-%m-%d %H:%M:%S", players[irc_params.pid].firstSeen) ) end
	irc_chat(irc_params.name, seen(irc_params.pid))
	irc_chat(irc_params.name, "Total time played: " .. days .. " days " .. hours .. " hours " .. minutes .. " minutes " .. time .. " seconds")
	if players[irc_params.pid].aliases then irc_chat(irc_params.name, "Has played as " .. players[irc_params.pid].aliases) end

	if players[irc_params.pid].bedX ~= 0 and players[irc_params.pid].bedY ~= 0 and players[irc_params.pid].bedZ ~= 0 then
		irc_chat(irc_params.name, "Has a bedroll at " .. players[irc_params.pid].bedX .. " " .. players[irc_params.pid].bedY .. " " .. players[irc_params.pid].bedZ )
	else
		irc_chat(irc_params.name, "Does not have a bedroll down or its location is not recorded yet.")
	end

	if players[irc_params.pid].homeX ~= 0 and players[irc_params.pid].homeY ~= 0 and players[irc_params.pid].homeZ ~= 0 then
		irc_chat(irc_params.name, "Base one is at " .. players[irc_params.pid].homeX .. " " .. players[irc_params.pid].homeY .. " " .. players[irc_params.pid].homeZ )
	else
		irc_chat(irc_params.name, "Has not set base one.")
	end

	if players[irc_params.pid].home2X ~= 0 and players[irc_params.pid].home2Y ~= 0 and players[irc_params.pid].home2Z ~= 0 then
		irc_chat(irc_params.name, "Base two is at " .. players[irc_params.pid].home2X .. " " .. players[irc_params.pid].home2Y .. " " .. players[irc_params.pid].home2Z )
	else
		irc_chat(irc_params.name, "Has not set base two.")
	end

	if players[irc_params.pid].hackerScore then irc_chat(irc_params.name, "Hacker score: " .. players[irc_params.pid].hackerScore) end

	if players[irc_params.pid].timeout == true then
		irc_chat(irc_params.name, "Is in timeout")
	else
		irc_chat(irc_params.name, "Not in timeout")
	end

	if players[irc_params.pid].prisoner then
		irc_chat(irc_params.name, "Is a prisoner")
		if players[irc_params.pid].prisonReason ~= nil then irc_chat(irc_params.name, "Reason Arrested: " .. players[irc_params.pid].prisonReason) end
	else
		irc_chat(irc_params.name, "Not a prisoner")
	end

	irc_chat(irc_params.name, server.moneyPlural .. " " .. string.format("%d", players[irc_params.pid].cash))
	irc_chat(irc_params.name, "Keystones placed " .. players[irc_params.pid].keystones)
	irc_chat(irc_params.name, "Zombies " .. players[irc_params.pid].zombies)
	irc_chat(irc_params.name, "Score " .. players[irc_params.pid].score)
	irc_chat(irc_params.name, "Deaths " .. players[irc_params.pid].deaths)
	irc_chat(irc_params.name, "PVP kills " .. players[irc_params.pid].playerKills)
	irc_chat(irc_params.name, "Level " .. players[irc_params.pid].level)
	irc_chat(irc_params.name, "Current Session " .. players[irc_params.pid].sessionCount)
	irc_chat(irc_params.name, "IP https://www.whois.com/whois/" .. players[irc_params.pid].ip)
	irc_chat(irc_params.name, "Ping " .. players[irc_params.pid].ping .. " Country: " .. players[irc_params.pid].country)

	if players[irc_params.pid].china then
		irc_chat(irc_params.name, "China IP detected")
	end

	if players[irc_params.pid].exiled then
		irc_chat(irc_params.name, "Is exiled")
	else
		irc_chat(irc_params.name, "Not exiled")
	end

	if players[irc_params.pid].inLocation then
		if players[irc_params.pid].inLocation ~= "" then
			irc_chat(irc_params.name, "In location " .. players[irc_params.pid].inLocation)
		else
			irc_chat(irc_params.name, "Not in a named location")
		end
	end

	irc_chat(irc_params.name, "Current position " .. players[irc_params.pid].xPos .. " " .. players[irc_params.pid].yPos .. " " .. players[irc_params.pid].zPos)

	if  donor then
		irc_chat(irc_params.name, "Is a donor")
		if expiry then
			irc_chat(irc_params.name, "Expires on " .. os.date("%Y-%m-%d %H:%M:%S",  expiry))
		end
	else
		irc_chat(irc_params.name, "Not a donor")
	end

	cursor,errorString = conn:execute("SELECT * FROM bans WHERE steam =  " .. irc_params.pid)
	if cursor:numrows() > 0 then
		row = cursor:fetch({}, "a")
		irc_chat(irc_params.name, "BANNED until " .. row.BannedTo .. " " .. row.Reason)
	else
		irc_chat(irc_params.name, "Is not banned")
	end

	irc_chat(irc_params.name, "----")
end


function listOwners(steam)
	local pid
	local online = ""

	-- players do not see steam ID's of staff unless they are staff too.

	-- steam can be passed an irc nick so we need to do a lookup
	pid = LookupPlayer(steam)

	if igplayers[steam] then
		message("pm " .. steam .. " [" .. server.chatColour .. "]The server owners are:[-]")
	else
		irc_chat(irc_params.name, "The server owners are:")
	end

	for k, v in pairs(owners) do
		if igplayers[k] then
			online = "  [IN GAME NOW]"
		else
			online = " "
		end

		if accessLevel(pid) < 3 then
			if igplayers[steam] then
				if not players[k] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. k .. " UNKNOWN STEAM ID[-]")
				else
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. k .. " " .. players[k].name .. online .. "[-]")
				end
			else
				if not players[k] then
					irc_chat(irc_params.name, "UNKNOWN PLAYER " .. k .. " in admin list but not known to server.")
				else
					irc_chat(irc_params.name,  k .. " " .. players[k].name .. online)
				end
			end
		else
			if igplayers[steam] then
				if players[k] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. players[k].name .. online .. "[-]")
				end
			else
				if players[k] then
					irc_chat(irc_params.name,  players[k].name .. online)
				end
			end
		end
	end

	if not igplayers[steam] then
		irc_chat(irc_params.name, ".")
	end
end


function listAdmins(steam)
	local pid
	local online = ""

	pid = LookupPlayer(steam)

	if igplayers[steam] then
		message("pm " .. steam .. " [" .. server.chatColour .. "]The server admins are:[-]")
	else
		irc_chat(irc_params.name, "The server admins are..")
	end

	for k, v in pairs(admins) do
		if igplayers[k] then
			online = "  [IN GAME NOW]"
		else
			online = ""
		end

		if accessLevel(pid) < 3 then
			if igplayers[steam] then
				if not players[k] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. k .. " UNKNOWN STEAM ID[-]")
				else
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. k .. " " .. players[k].name .. online .. "[-]")
				end
			else
				if not players[k] then
					irc_chat(irc_params.name, "UNKNOWN PLAYER " .. k .. " in admin list but not known to server.")
				else
					irc_chat(irc_params.name,  k .. " " .. players[k].name .. online)
				end
			end
		else
			if igplayers[steam] then
				if players[k] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. players[k].name .. online .. "[-]")
				end
			else
				if players[k] then
					irc_chat(irc_params.name,  players[k].name .. online)
				end
			end
		end
	end

	if not igplayers[steam] then
		irc_chat(irc_params.name, ".")
	end
end


function listMods(steam)
	local pid
	local online = ""

	pid = LookupPlayer(steam)

	if igplayers[steam] then
		message("pm " .. steam .. " [" .. server.chatColour .. "]The server mods are:[-]")
	else
		irc_chat(irc_params.name, "The server mods are..")
	end

	for k, v in pairs(mods) do
		if igplayers[k] then
			online = "  [IN GAME NOW]"
		else
			online = ""
		end

		if accessLevel(pid) < 3 then
			if igplayers[steam] then
				if not players[k] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. k .. " UNKNOWN STEAM ID[-]")
				else
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. k .. " " .. players[k].name .. online .. "[-]")
				end
			else
				if not players[k] then
					irc_chat(irc_params.name, "UNKNOWN PLAYER " .. k .. " in admin list but not known to server.")
				else
					irc_chat(irc_params.name,  k .. " " .. players[k].name .. online)
				end
			end
		else
			if igplayers[steam] then
				if players[k] then
					message("pm " .. steam .. " [" .. server.chatColour .. "]" .. players[k].name .. online .. "[-]")
				end
			else
				if players[k] then
					irc_chat(irc_params.name,  players[k].name .. online)
				end
			end
		end
	end

	if not igplayers[steam] then
		irc_chat(irc_params.name, ".")
	end
end


function listStaff(steam)
	listOwners(steam)
	listAdmins(steam)
	listMods(steam)
end


function irc_friend()
	-- add to friends table
	if (friends[irc_params.pid] == nil) then
		friends[irc_params.pid] = {}
		friends[irc_params.pid].friends = ""
	end

	if addFriend(irc_params.pid, irc_params.pid2) then
		irc_chat(irc_params.name, players[irc_params.pid].name .. " is now friends with " .. players[irc_params.pid2].name)
	else
		irc_chat(irc_params.name, players[irc_params.pid].name .. " is already friends with " .. players[irc_params.pid2].name)
	end

	irc_chat(irc_params.name, ".")
end


function irc_unfriend()
	local friendlist, max

	-- add to friends table
	if (friends[irc_params.pid] == nil) then
		friends[irc_params.pid] = {}
		friends[irc_params.pid].friends = ""
	end

	friendlist = string.split(friends[irc_params.pid].friends, ",")

	-- now simply rebuild friend skipping over the one we are removing
	friends[irc_params.pid].friends = ""
	max = table.maxn(friendlist)
	for i=1,max,1 do
		if (friendlist[i] ~= irc_params.pid2) then
			friends[irc_params.pid].friends = friends[irc_params.pid].friends .. friendlist[i] .. ","
		end
	end

	irc_chat(irc_params.name, players[irc_params.pid].name .. " is no longer friends with " .. players[irc_params.pid2].name)

	conn:execute("DELETE FROM friends WHERE steam = " .. irc_params.pid .. " AND friend = " .. irc_params.pid2)

	irc_chat(irc_params.name, ".")
end


function irc_friends()
	local friendlist, max

	irc_chat(irc_params.name, players[irc_params.pid].name .. " is friends with..")
	friendlist = string.split(friends[irc_params.pid].friends, ",")
	max = table.maxn(friendlist)

	for i=1,max,1 do
		if (friendlist[i] ~= "") then
			id = LookupPlayer(friendlist[i])
			irc_chat(irc_params.name, players[id].name)
		end
	end

	if friends[irc_params.pid].friends == "" then
		irc_chat(irc_params.name, "Nobody :(")
	end

	irc_chat(irc_params.name, ".")
end


function irc_new_players(name)
	local id
	local x
	local z

	id = LookupOfflinePlayer(name, "all")

	irc_chat(name, "New players in the last 2 days:")

	for k, v in pairs(players) do
		if v.firstSeen ~= nil then
			if ((os.time() - tonumber(v.firstSeen)) < 86401) then
				if accessLevel(id) > 3 and not debugAdmin then
					irc_chat(name, v.name)
				else
					irc_chat(name, "steam: " .. k .. " id: " .. string.format("%8d", v.id) .. " name: " .. v.name .. " at " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos)
				end
			end
		end
	end

	irc_chat(name, ".")
end


function irc_server_status(name, days)
	irc_chat(name, "The server date is " .. botman.serverTime)

	if days == nil then
		irc_chat(name, "24 hour stats to now:")
		days = 1
	else
		irc_chat(name, "Last " .. days .. " days stats to now:")
	end

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%pvp%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "PVPs: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%timeout%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Timeouts: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%arrest%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Arrests: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%new%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "New players: " .. row.number)

	cursor,errorString = conn:execute("SELECT COUNT(id) as number FROM events WHERE type LIKE '%ban%' AND timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Bans: " .. row.number)

	cursor,errorString = conn:execute("SELECT MAX(players) as number FROM performance WHERE timestamp > DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	row = cursor:fetch({}, "a")
	irc_chat(name, "Most players online: " .. row.number)
	irc_chat(name, ".")
end


function irc_server_event(name, event, steam, days)
	if days == 0 then
		irc_chat(name, event .. "s in the last 24 hours:")
		days = 1
	else
		irc_chat(name, event .. "s in the last " .. days .. " days:")
	end

	if steam == 0 then
		cursor,errorString = conn:execute("SELECT * FROM events WHERE (type LIKE '%" .. event .. "%' or event LIKE '%" .. event .. "%') AND timestamp >= DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	else
		cursor,errorString = conn:execute("SELECT * FROM events WHERE (steam = " .. steam .. " AND type LIKE '%" .. event .. "%' or event LIKE '%" .. event .. "%') AND timestamp >= DATE_SUB(now(), INTERVAL ".. days .. " DAY)")
	end

	row = cursor:fetch({}, "a")
	while row do
		irc_chat(name, row.serverTime .. " " .. row.event .. " at " .. row.x .. " " .. row.y - 1 .. " " .. row.z)
		row = cursor:fetch(row, "a")
	end

	irc_chat(name, ".")
end


function irc_players(name)
	local id, x, z, flags, line, sort

	connMEM:execute("DELETE FROM list")

	id = LookupPlayer(name, "all")

	irc_chat(name, "The following players are in-game right now:")

	for k, v in pairs(igplayers) do
		x = math.floor(v.xPos / 512)
		z = math.floor(v.zPos / 512)

		flags = " "
		line = ""
		sort = 999

		if tonumber(players[k].accessLevel) < 3 then
			flags = flags .. "[ADMIN]"
			if sort == 999 then sort = 1 end
		end

		if players[k].newPlayer then
			flags = flags .. "[NEW]"
			if sort == 999 then sort = 3 end
		end

		if players[k].timeout then flags = flags .. "[TIMEOUT]" end
		if players[k].prisoner then flags = flags .. "[PRISONER]" end

		if isDonor(k) then
			flags = flags .. "[DONOR]"
			if sort == 999 then sort = 2 end
		end

		if tonumber(players[k].hackerScore) > 0 then
			flags = flags .. "[HACKER]"

			if v.flying then
				flags = flags .. "[FLYING " .. v.flyingHeight .. "]"
			end

			if v.noclip then
				flags = flags .. "[NOCLIP]"
			end

			if sort == 999 then sort = 0 end
		end

		if (accessLevel(id) > 3) and not debugAdmin then
			line = v.name .. " score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. "| level: " .. v.level .. " " .. flags .. "| " .. players[k].country .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
		else
			if players[id].ircAuthenticated == true then
				if v.inLocation ~= "" then
					line = "steam: " .. k .. "| id: " .. string.format("%d", v.id) .. "| score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. "| level: " .. v.level .. "| region r." .. x .. "." .. z .. ".7rg| name: " .. v.name  .. flags .. " in " .. v.inLocation .. " @ " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos .. "  " .. players[k].country .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
				else
					line = "steam: " .. k .. "| id: " .. string.format("%d", v.id) .. "| score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. "| level: " .. v.level .. "| region r." .. x .. "." .. z .. ".7rg| name: " .. v.name  .. flags .. " @ " .. v.xPos .. " " .. v.yPos .. " " .. v.zPos .. "  " .. players[k].country .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
				end
			else
				line = "steam: " .. k .. " " .. v.name .. "| score: " .. string.format("%d", v.score) .. "| PVP: " .. string.format("%d", v.playerKills) .. "| zeds: " .. string.format("%d", v.zombies) .. " " .. flags .. "| ping: " .. v.ping .. "| Hacker score: " .. players[k].hackerScore
			end
		end

		connMEM:execute("INSERT INTO list (id, thing) VALUES (" .. sort .. ",'" .. connMEM:escape(line) .. "')")
	end

	cursor,errorString = connMEM:execute("SELECT * FROM list ORDER BY id")
	row = cursor:fetch({}, "a")
	while row do
		irc_chat(name, row.thing)
		row = cursor:fetch(row, "a")
	end

	connMEM:execute("DELETE FROM list")

	irc_chat(irc_params.name, "There are " .. botman.playersOnline .. " players online.")
	irc_chat(name, ".")
end


function irc_who_played(name)
	local id
	local x
	local z
	local flags

	id = LookupPlayer(name, "all")

	irc_chat(name, "The following players joined the server over the last 24 hours:")

	cursor,errorString = conn:execute("SELECT steam, serverTime FROM events WHERE type = 'player joined' AND timestamp >= DATE_SUB(now(), INTERVAL 1 DAY) ORDER BY timestamp desc")

	row = cursor:fetch({}, "a")
	while row do
		if (accessLevel(id) > 3) and not debugAdmin then
			irc_chat(name, row.serverTime .. " " .. players[row.steam].name)
		else
			irc_chat(name, row.serverTime .. " " .. row.steam .. " " .. players[row.steam].name)
		end

		row = cursor:fetch(row, "a")
	end

	irc_chat(name, ".")
end


function irc_listResetZones(name)
   local a = {}
	local n
	local sid
	local pid

	irc_chat(name, "The following regions are designated reset zones:")

   for n in pairs(resetRegions) do
		table.insert(a, n)
	end

	table.sort(a)

   for k, v in ipairs(a) do
		irc_chat(name, "region: " .. v)
	end

	irc_chat(name, ".")
end


function irc_gameTime(name)
	irc_chat(name, "The game date is: " .. server.gameDate)
end


function irc_uptime(name)
	diff = os.difftime(os.time(), botman.botStarted)
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	irc_chat(name, server.botName .. " has been online " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")

	if tonumber(server.uptime) < 0 then
		irc_chat(name, "Server uptime is uncertain")
	else
		diff = server.uptime
		days = math.floor(diff / 86400)

		if (days > 0) then
			diff = diff - (days * 86400)
		end

		hours = math.floor(diff / 3600)

		if (hours > 0) then
			diff = diff - (hours * 3600)
		end

		minutes = math.floor(diff / 60)

		irc_chat(name, "Server uptime is " .. days .. " days " .. hours .. " hours " .. minutes .." minutes")
	end

	irc_chat(name, ".")
end


function irc_listAllPlayers(name) --tested
    local a = {}
	local n, id, steam, isADonor, isAdmin, isPrisoner, isBanned

	irc_chat(name, "These are all the players on record:")

    for n in pairs(players) do
		table.insert(a, players[n].name)
	end

	table.sort(a)

	if irc_params.pname == nil then
		for k, v in ipairs(a) do
			steam = LookupOfflinePlayer(v, "all")

			if tonumber(steam) > 0 then
				if players[steam].prisoner then
					isPrisoner = "Prisoner"
				else
					isPrisoner = ""
				end

				if isDonor(steam) then
					isADonor = "Donor"
				else
					isADonor = ""
				end

				if players[steam].accessLevel < 3 then
					isAdmin = "Admin"
				else
					isAdmin = "Player"
				end

				cmd = "steam: " .. steam .. " id: " .. string.format("%-8d", players[steam].id) .. " name: " .. v .. " [ " .. string.trim(isAdmin .. " " .. isADonor .. " " .. isPrisoner) .. " ] seen " .. players[steam].seen .. " playtime " .. players[steam].playtime .. " cash " .. players[steam].cash
				irc_chat(irc_params.name, cmd)
			end
		end
	else
		steam = LookupPlayer(irc_params.pname)

		if players[steam] then
			if players[steam].prisoner then
				isPrisoner = "Prisoner"
			else
				isPrisoner = ""
			end

			if isDonor(steam) then
				isADonor = "Donor"
			else
				isADonor = ""
			end

			if players[steam].accessLevel < 3 then
				isAdmin = "Admin"
			else
				isAdmin = "Player"
			end

			cmd = "steam: " .. steam .. " id: " .. string.format("%-8d", players[steam].id) .. " name: " .. players[steam].name .. " [ " .. string.trim(isAdmin .. " " .. isADonor .. " " .. isPrisoner) .. " ] seen " .. players[steam].seen .. " playtime " .. players[steam].playtime .. " cash " .. players[steam].cash
			irc_chat(irc_params.name, cmd)
		else
			irc_chat(irc_params.name, "No player found like " .. irc_params.pname)
		end
	end

	irc_chat(name, ".")
end


function irc_listAllArchivedPlayers(name) --tested
    local a = {}
	local n, id, steam, isADonor, isAdmin, isPrisoner, isBanned

    for n in pairs(playersArchived) do
		table.insert(a, playersArchived[n].name)
	end

	table.sort(a)

	if irc_params.pname == nil then
		irc_chat(name, "These are all the archived players on record:")

		for k, v in ipairs(a) do
			steam = LookupArchivedPlayer(v, "all")

			if tonumber(steam) > 0 then
				if playersArchived[steam].prisoner then
					isPrisoner = "Prisoner"
				else
					isPrisoner = ""
				end

				if isDonor(steam) then
					isADonor = "Donor"
				else
					isADonor = ""
				end

				if playersArchived[steam].accessLevel < 3 then
					isAdmin = "Admin"
				else
					isAdmin = "Player"
				end

				cmd = "steam: " .. steam .. " id: " .. string.format("%-8d", playersArchived[steam].id) .. " name: " .. v .. " [ " .. isAdmin .. " " .. isADonor .. " " .. isPrisoner .. " ] seen " .. playersArchived[steam].seen .. " playtime " .. playersArchived[steam].playtime
				irc_chat(irc_params.name, cmd)
			end
		end
	else
		irc_chat(name, "Archived player " .. irc_params.pname .. ":")
		steam = LookupArchivedPlayer(irc_params.pname)

		if playersArchived[steam] then
			if playersArchived[steam].prisoner then
				isPrisoner = "Prisoner"
			else
				isPrisoner = ""
			end

			if isDonor(steam) then
				isADonor = "Donor"
			else
				isADonor = ""
			end

			if playersArchived[steam].accessLevel < 3 then
				isAdmin = "Admin"
			else
				isAdmin = "Player"
			end

			cmd = "steam: " .. steam .. " id: " .. string.format("%-8d", playersArchived[steam].id) .. " name: " .. playersArchived[steam].name .. " [ " .. string.trim(isAdmin .. " " .. isADonor .. " " .. isPrisoner) .. " ] seen " .. playersArchived[steam].seen .. " playtime " .. playersArchived[steam].playtime .. " cash " .. playersArchived[steam].cash
			irc_chat(irc_params.name, cmd)
		else
			irc_chat(irc_params.name, "No player found like " .. irc_params.pname)
		end
	end

	irc_chat(name, ".")
end


function irc_IGPlayerInfo()
	if (players[irc_params.pid]) then
		if igplayers[irc_params.pid] then
			irc_chat(irc_params.name, "In-Game Player record of: " .. irc_params.pname)
			for k, v in pairs(igplayers[irc_params.pid]) do
				cmd = ""

				if k ~= "inventory" and k ~= "inventoryLast" then
					if irc_params.search ~= "" then
						if string.find(string.lower(k), irc_params.search) then
							cmd = k .. "," .. tostring(v)
						end
					else
						cmd = k .. "," .. tostring(v)
					end

					if cmd ~= "" then
						irc_chat(irc_params.name, cmd)
					end
				end
			end
		else
			irc_chat(irc_params.name, "There is currently no in-game record for " .. irc_params.pname .. ". It gets deleted after they leave the server.")
		end
	else
		irc_chat(irc_params.name, "I do not know a player called " .. irc_params.pname)
	end

	irc_chat(irc_params.name, ".")
end


function irc_playerStatus()
	local protected
	local base

	if (players[irc_params.pid].protect == true) then
		protected = "protected"
	else
		protected = "not protected (unless you have LCB's down)"
	end

	if (players[irc_params.pid].homeX == 0 and players[irc_params.pid].homeY == 0 and players[irc_params.pid].homeZ == 0) then
		base = "Has not done " .. server.commandPrefix .. "setbase"
	else
		base = "Has set a base"
	end
	irc_chat(irc_params.name, irc_params.pname .. " has " .. string.format("%d", players[irc_params.pid].cash) .. " " .. server.moneyPlural .. "")

	irc_chat(irc_params.name, "Base status for " .. irc_params.pname .. " is..")
	irc_chat(irc_params.name, base)
	irc_chat(irc_params.name, "The base is " .. protected)
	irc_chat(irc_params.name, "Protection size is " .. players[irc_params.pid].protectSize .. " meters")

	if (players[irc_params.pid].protectPaused ~= nil) then
		irc_chat(irc_params.name, "Protection is paused")
	end


	if (players[irc_params.pid].protect2 == true) then
		protected = "protected"
	else
		protected = "not protected (unless you have LCB's down)"
	end

	if (players[irc_params.pid].home2X == 0 and players[irc_params.pid].home2Y == 0 and players[irc_params.pid].home2Z == 0) then
		base = "Has not done " .. server.commandPrefix .. "setbase2"
	else
		base = "Has set a base"
	end

	irc_chat(irc_params.name, "Second Base status for " .. irc_params.pname .. " is..")
	irc_chat(irc_params.name, base)
	irc_chat(irc_params.name, "Base2 is " .. protected)
	irc_chat(irc_params.name, "Protection size is " .. players[irc_params.pid].protect2Size .. " meters")

	if (players[irc_params.pid].protect2Paused ~= nil) then
		irc_chat(irc_params.name, "Protection is paused")
	end

	if players[irc_params.pid].bedX ~= 0 and players[irc_params.pid].bedY ~= 0 and players[irc_params.pid].bedZ ~= 0 then
		irc_chat(irc_params.name, "Has a bedroll at " .. players[irc_params.pid].bedX .. " " .. players[irc_params.pid].bedY .. " " .. players[irc_params.pid].bedZ )
	else
		irc_chat(irc_params.name, "Does not have a bedroll down or its location is not recorded yet.")
	end

	if players[irc_params.pid].homeX ~= 0 and players[irc_params.pid].homeY ~= 0 and players[irc_params.pid].homeZ ~= 0 then
		irc_chat(irc_params.name, "Base one is at " .. players[irc_params.pid].homeX .. " " .. players[irc_params.pid].homeY .. " " .. players[irc_params.pid].homeZ )
	else
		irc_chat(irc_params.name, "Has not set base one.")
	end

	if players[irc_params.pid].home2X ~= 0 and players[irc_params.pid].home2Y ~= 0 and players[irc_params.pid].home2Z ~= 0 then
		irc_chat(irc_params.name, "Base two is at " .. players[irc_params.pid].home2X .. " " .. players[irc_params.pid].home2Y .. " " .. players[irc_params.pid].home2Z )
	else
		irc_chat(irc_params.name, "Has not set base two.")
	end

	irc_chat(irc_params.name, ".")
end
