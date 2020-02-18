--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug
debug = false -- should be false unless testing


function loadBadItems()
	local cursor, errorString, row, k, v

	--debug = false
	calledFunction = "badItems"
	if (debug) then dbug("debug badItems line " .. debugger.getinfo(1).currentline) end

	-- load badItems
	getTableFields("badItems")

	badItems = {}
	cursor,errorString = conn:execute("select * from badItems")
	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadBadItem " .. row.item) end

		badItems[row.item] = {}

		for k,v in pairs(badItemsFields) do
			if v.type == "var" or v.type == "big" then
				badItems[row.item][k] = row[k]
			end

			if v.type == "int" then
				badItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				badItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				badItems[row.item][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug badItems line end") end
end


function loadBadWords()
	local cursor, errorString, row

	-- load badWords
	getTableFields("badWords")

	badWords = {}
	cursor,errorString = conn:execute("select * from badWords")
	row = cursor:fetch({}, "a")
	while row do
		badWords[row.badWord] = {}
		badWords[row.badWord].cost = tonumber(row.cost)
		badWords[row.badWord].counter = tonumber(row.counter)
		row = cursor:fetch(row, "a")
	end
end


function loadBans()
	local cursor, errorString, row
	-- load bans

	getTableFields("bans")

    bans = {}
	cursor,errorString = conn:execute("select * from bans")
	row = cursor:fetch({}, "a")
	while row do
		bans[row.Steam] = {}
		bans[row.Steam].steam = row.Steam
		bans[row.Steam].BannedTo = row.BannedTo
		bans[row.Steam].Reason = row.Reason
		bans[row.Steam].expiryDate = row.expiryDate

		row = cursor:fetch(row, "a")
	end
end


function loadBases()
	local cursor, errorString, row
	-- load bases

	getTableFields("bases")

    bases = {}
	cursor,errorString = conn:execute("select * from bases")
	row = cursor:fetch({}, "a")
	while row do
		bases[row.steam .. "_" .. row.baseNumber] = {}
		bases[row.steam .. "_" .. row.baseNumber].steam = row.steam
		bases[row.steam .. "_" .. row.baseNumber].baseNumber = row.baseNumber
		bases[row.steam .. "_" .. row.baseNumber].title = row.title
		bases[row.steam .. "_" .. row.baseNumber].x = row.x
		bases[row.steam .. "_" .. row.baseNumber].y = row.y
		bases[row.steam .. "_" .. row.baseNumber].z = row.z
		bases[row.steam .. "_" .. row.baseNumber].exitX = row.exitX
		bases[row.steam .. "_" .. row.baseNumber].exitY = row.exitY
		bases[row.steam .. "_" .. row.baseNumber].exitZ = row.exitZ
		bases[row.steam .. "_" .. row.baseNumber].size = row.size
		bases[row.steam .. "_" .. row.baseNumber].protect = row.protect
		bases[row.steam .. "_" .. row.baseNumber].keepOut = row.keepOut
		bases[row.steam .. "_" .. row.baseNumber].creationTimestamp = row.creationTimestamp
		bases[row.steam .. "_" .. row.baseNumber].creationGameDay = row.creationGameDay

		row = cursor:fetch(row, "a")
	end
end


function loadCustomMessages()
	local cursor, errorString, row

	-- load customMessages
	getTableFields("customMessages")

	customMessages = {}
	cursor,errorString = conn:execute("select * from customMessages")
	row = cursor:fetch({}, "a")
	while row do
		customMessages[row.command] = {}
		customMessages[row.command].message = row.message
		customMessages[row.command].accessLevel = tonumber(row.accessLevel)
		row = cursor:fetch(row, "a")
	end
end


function loadDonors()
	local cursor, errorString, row
	-- load donors

	getTableFields("donors")

    donors = {}
	cursor,errorString = conn:execute("select * from donors")
	row = cursor:fetch({}, "a")
	while row do
		donors[row.steam] = {}
		donors[row.steam].steam = row.steam
		donors[row.steam].level = row.level
		donors[row.steam].expiry = row.expiry
		row = cursor:fetch(row, "a")
	end
end


function loadFriends()
	local cursor, errorString, row

	-- load friends
	getTableFields("friends")

	friends = {}
	cursor,errorString = conn:execute("select * from friends")
	row = cursor:fetch({}, "a")
	while row do
		if friends[row.steam] == nil then
			friends[row.steam] = {}
			friends[row.steam].friends = ""
		end

		if friends[row.steam].friends == "" then
			friends[row.steam].friends = row.friend
		else
			friends[row.steam].friends = friends[row.steam].friends .. "," .. row.friend
		end

		row = cursor:fetch(row, "a")
	end
end


function loadGimmeZombies()
	local cursor, errorString, row, rows, k, v, n, m, strIdx

	--debug = false
	calledFunction = "gimmeZombies"
	if (debug) then dbug("debug gimmeZombies line " .. debugger.getinfo(1).currentline) end

	-- load gimmeZombies
	getTableFields("gimmeZombies")

	gimmeZombies = {}

	cursor,errorString = conn:execute("select * from gimmeZombies")
	rows = tonumber(cursor:numrows())
	row = cursor:fetch({}, "a")

	botman.maxGimmeZombies = tonumber(rows)

	if row then
		cols = cursor:getcolnames()
	end

	while row do
		strIdx = tostring(row.entityID)
		gimmeZombies[strIdx] = {}
		gimmeZombies[strIdx].entityID = row.entityID
		gimmeZombies[strIdx].zombie = row.zombie
		gimmeZombies[strIdx].minPlayerLevel = row.minPlayerLevel
		gimmeZombies[strIdx].minArenaLevel = row.minArenaLevel
		gimmeZombies[strIdx].bossZombie = dbTrue(row.bossZombie)
		gimmeZombies[strIdx].doNotSpawn = dbTrue(row.doNotSpawn)
		gimmeZombies[strIdx].maxHealth = row.maxHealth
		gimmeZombies[strIdx].remove = dbTrue(row.remove)

		row = cursor:fetch(row, "a")
	end

	for k,v in pairs(gimmeZombies) do
		if string.find(v.zombie, "Radiated") or string.find(v.zombie, "Feral") then
			v.bossZombie = true
		end
	end

	if (debug) then dbug("debug gimmeZombies line end") end
end


function loadHotspots()
	local idx, nextidx
	local cursor, errorString, row

	nextidx = -1

	--debug = false
	calledFunction = "hotspots"
	if (debug) then dbug("debug hotspots line " .. debugger.getinfo(1).currentline) end

	-- load hotspots
	getTableFields("hotspots")

	hotspots = {}
	cursor,errorString = conn:execute("select * from hotspots")
	row = cursor:fetch({}, "a")

	if row then
		cols = cursor:getcolnames()
	end

	while row do
		idx = tonumber(row.idx)

		if idx == 0 then
			if nextidx == -1 then
				idx = 1
				nextidx = 2
			else
				idx = nextidx
				nextidx = nextidx + 1
			end

			conn:execute("update hotspots set idx = " .. idx .. " where id = " .. row.id)
		end

		hotspots[idx] = {}

		for k,v in pairs(cols) do
			for n,m in pairs(row) do
				if n == _G["hotspotsFields"][v].field then
					if _G["hotspotsFields"][v].type == "var" or _G["hotspotsFields"][v].type == "big" then
						hotspots[idx][n] = m
					end

					if _G["hotspotsFields"][v].type == "int" then
						hotspots[idx][n] = tonumber(m)
					end

					if _G["hotspotsFields"][v].type == "tin" then
						hotspots[idx][n] = dbTrue(m)
					end
				end
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadKeystones()
	local cursor, errorString, row, k, v, m, n, cols

	--debug = false
	calledFunction = "loadKeystones"
	if (debug) then dbug("debug loadKeystones line " .. debugger.getinfo(1).currentline) end

	getTableFields("keystones")

	if type(keystones) ~= "table" then
		keystones = {}
	end

	keystones = {}
	cursor,errorString = conn:execute("select * from keystones")
	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadKeystones " .. row.name) end

		keystones[row.x .. row.y .. row.z] = {}

		for k,v in pairs(keystonesFields) do
			if v.type == "var" or v.type == "big" then
				keystones[row.x .. row.y .. row.z][k] = row[k]
			end

			if v.type == "int" then
				keystones[row.x .. row.y .. row.z][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				keystones[row.x .. row.y .. row.z][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				keystones[row.x .. row.y .. row.z][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug loadKeystones end") end
end


function loadLocationCategories()
	local cursor, errorString, row

	-- load locationCategories
	getTableFields("locationCategories")

	locationCategories = {}
	cursor,errorString = conn:execute("select * from locationCategories")
	row = cursor:fetch({}, "a")
	while row do
		locationCategories[row.categoryName] = {}
		locationCategories[row.categoryName].minAccessLevel = row.minAccessLevel
		locationCategories[row.categoryName].maxAccessLevel = row.maxAccessLevel
		row = cursor:fetch(row, "a")
	end
end


function loadLocations(loc)
	local cursor, errorString, row, k, v, m, n, cols

	--debug = false
	calledFunction = "loadLocations"
	if (debug) then dbug("debug loadLocations line " .. debugger.getinfo(1).currentline) end

	getTableFields("locations")

	if type(locations) ~= "table" then
		locations = {}
	end

	if loc == nil then
		locations = {}
		cursor,errorString = conn:execute("select * from locations")
	else
		cursor,errorString = conn:execute("select * from locations where name = '" .. escape(loc) .. "'")
	end

	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadLocation " .. row.name) end

		locations[row.name] = {}

		for k,v in pairs(locationsFields) do
			if v.type == "var" or v.type == "big" then
				locations[row.name][k] = row[k]
			end

			if v.type == "int" then
				locations[row.name][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				locations[row.name][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				locations[row.name][k] = dbTrue(row[k])
			end
		end

		locations[row.name].open = true
		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug loadLocations end") end
end


function loadModBotman()
	local cursor, errorString, row, modBotmanOld
	-- load modBotman

	getTableFields("modBotman")

	if type(modBotman) == "table" then
		-- copy the current contents of the modBotman table into modBotmanOld so we can see what's changed later
		modBotmanOld = {}
		for k,v in pairs(modBotman) do
			modBotmanOld[k] = v
		end
	end

    modBotman = {}
	cursor,errorString = conn:execute("select * from modBotman")
	row = cursor:fetch({}, "a")

	if row then
		modBotman.clanEnabled = dbTrue(row.clanEnabled)
		modBotman.clanMaxClans = row.clanMaxClans
		modBotman.clanMaxPlayers = row.clanMaxPlayers
		modBotman.clanMinLevel = row.clanMinLevel
		modBotman.resetsEnabled = dbTrue(row.resetsEnabled)
		modBotman.resetsDelay = row.resetsDelay
		modBotman.resetsPrefabsOnly = dbTrue(row.resetsPrefabsOnly)
		modBotman.resetsRemoveLCB = dbTrue(row.resetsRemoveLCB)
	end
end


function loadOtherEntities()
	local idx, cursor, errorString, row

	-- load otherEntities
	getTableFields("otherEntities")

    otherEntities = {}
	cursor,errorString = conn:execute("select * from otherEntities")
	row = cursor:fetch({}, "a")
	while row do
		idx = tostring(row.entityID)

		otherEntities[idx] = {}
		otherEntities[idx].entity = row.entity
		otherEntities[idx].entityID = row.entityID
		otherEntities[idx].doNotSpawn = dbTrue(row.doNotSpawn)
		otherEntities[idx].doNotDespawn = dbTrue(row.doNotDespawn)

		if string.find(row.entity, "Trader") or string.find(row.entity, "ehicle") or string.find(row.entity, "emplate") or string.find(row.entity, "Plane") or string.find(row.entity, "sc_") or string.find(row.entity, "nvisible") or string.find(row.entity, "ontainer") then
			otherEntities[idx].doNotSpawn = true
			otherEntities[idx].doNotDespawn = true
		end

		row = cursor:fetch(row, "a")
	end
end


function loadPlayers(steam)
	local cursor, errorString, row
	local word, words, rdate, ryear, rmonth, rday, rhour, rmin, rsec, k, v

	-- load players table)
	getPlayerFields()

	if not steam then
		players = {}
		cursor,errorString = conn:execute("select * from players")
	else
		cursor,errorString = conn:execute("select * from players where steam = " .. steam)
	end

	row = cursor:fetch({}, "a")
	while row do
		-- don't load the player if they are in the table playersArchived
		if not playersArchived[row.steam] then
			if not players[row.steam] then
				players[row.steam] = {}
			end

			for k,v in pairs(playerFields) do
				if v.type == "var" or v.type == "big" then
					players[row.steam][k] = row[k]
				end

				if v.type == "int" then
					players[row.steam][k] = tonumber(row[k])
				end

				if v.type == "flo" then
					players[row.steam][k] = tonumber(row[k])
				end

				if v.type == "tin" then
					players[row.steam][k] = dbTrue(row[k])
				end
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadPlayersArchived(steam)
	local cursor, errorString, row
	local word, words, rdate, ryear, rmonth, rday, rhour, rmin, rsec, k, v

	-- load playersArchived table)
	getTableFields("playersArchived")

	if steam == nil then
		playersArchived = {}
		cursor,errorString = conn:execute("select * from playersArchived")
	else
		cursor,errorString = conn:execute("select * from playersArchived where steam = " .. steam)
	end

	row = cursor:fetch({}, "a")

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	while row do
		playersArchived[row.steam] = {}

		for k,v in pairs(playersArchivedFields) do
			if v.type == "var" or v.type == "big" then
				playersArchived[row.steam][k] = row[k]
			end

			if v.type == "int" then
				playersArchived[row.steam][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				playersArchived[row.steam][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				playersArchived[row.steam][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end
end


function loadPrefabCopies()
	local cursor, errorString, row

	-- load prefabs
	getTableFields("prefabCopies")

    prefabCopies = {}
	cursor,errorString = conn:execute("select * from prefabCopies")
	row = cursor:fetch({}, "a")
	while row do
		prefabCopies[row.owner .. row.name] = {}
		prefabCopies[row.owner .. row.name].x1 = tonumber(row.x1)
		prefabCopies[row.owner .. row.name].y1 = tonumber(row.y1)
		prefabCopies[row.owner .. row.name].z1 = tonumber(row.z1)
		prefabCopies[row.owner .. row.name].x2 = tonumber(row.x2)
		prefabCopies[row.owner .. row.name].y2 = tonumber(row.y2)
		prefabCopies[row.owner .. row.name].z2 = tonumber(row.z2)
		prefabCopies[row.owner .. row.name].owner = row.owner
		prefabCopies[row.owner .. row.name].name = row.name
		row = cursor:fetch(row, "a")
	end
end


function loadProxies()
	local proxy
	local cursor, errorString, row

	-- load proxies
	getTableFields("proxies")

	proxies = {}
	cursor,errorString = conn:execute("select * from proxies")
	row = cursor:fetch({}, "a")
	while row do
		proxy = string.trim(row.scanString)
		proxies[proxy] = {}
		proxies[proxy].scanString = proxy
		proxies[proxy].action = row.action
		proxies[proxy].hits = tonumber(row.hits)
		row = cursor:fetch(row, "a")
	end

	if botman.db2Connected then
		-- check for new proxies in the bots db
		cursor,errorString = connBots:execute("select * from proxies")
		row = cursor:fetch({}, "a")
		while row do
			proxy = string.trim(row.scanString)

			if not proxies[proxy] then
				proxies[proxy] = {}
				proxies[proxy].scanString = proxy
				proxies[proxy].action = row.action
				proxies[proxy].hits = 0

				conn:execute("INSERT INTO proxies (scanString, action, hits) VALUES ('" .. escape(proxy) .. "','" .. escape(row.action) .. "',0)")
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function loadResetZones()
	local cursor, errorString, row
	-- load reset zones

	getTableFields("resetZones")

	resetRegions = {}
	cursor,errorString = conn:execute("select * from resetZones")
	row = cursor:fetch({}, "a")
	while row do
		resetRegions[row.region] = {}

		if server.botman then
			sendCommand("bm-resetregions add " .. row.x .. "." .. row.z)
		end

		row = cursor:fetch(row, "a")
	end
end


function loadRestrictedItems()
	local cursor, errorString, row, k, v

	--debug = false
	calledFunction = "restrictedItems"
	if (debug) then dbug("debug restrictedItems line " .. debugger.getinfo(1).currentline) end

	-- load restrictedItems
	getTableFields("restrictedItems")

	restrictedItems = {}
	cursor,errorString = conn:execute("select * from restrictedItems")
	row = cursor:fetch({}, "a")

	while row do
		if (debug) then dbug("debug loadBadItem " .. row.item) end

		restrictedItems[row.item] = {}

		for k,v in pairs(restrictedItemsFields) do
			if v.type == "var" or v.type == "big" then
				restrictedItems[row.item][k] = row[k]
			end

			if v.type == "int" then
				restrictedItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				restrictedItems[row.item][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				restrictedItems[row.item][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug restrictedItems line end") end
end


function loadServer(setupStuff)
	local temp, cursor, errorString, row, rows, k, v, serverOld

--	debug = false
	calledFunction = "loadServer"

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	-- load server
	getServerFields()

	if type(server) ~= "table" then
		server = {}
	end

	cursor,errorString = conn:execute("select * from server")
	rows = tonumber(cursor:numrows())

	if rows == 0 then
		initServer()
	end

	-- copy the current contents of the server table into serverOld so we can see what's changed later
	serverOld = {}
	for k,v in pairs(server) do
		serverOld[k] = v
	end

	cursor,errorString = conn:execute("select * from server")
	row = cursor:fetch({}, "a")

	for k,v in pairs(serverFields) do
		if v.type == "var" or v.type == "big" then
			server[k] = row[k]
		end

		if v.type == "int" then
			server[k] = tonumber(row[k])
		end

		if v.type == "flo" then
			server[k] = tonumber(row[k])
		end

		if v.type == "tin" then
			server[k] = dbTrue(row[k])
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if row.chatlogPath == "" or row.chatlogPath == nil then
		botman.chatlogPath = homedir .. "/chatlogs"
	end

	botman.chatlogPath = row.chatlogPath

	if row.moneyName == nil or row.moneyName == "|" then
		-- fix if missing money
		temp = string.split("Zenny|Zennies", "|")
	else
		temp = string.split(row.moneyName, "|")
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	server.moneyName = temp[1]

	if temp[2] == nil then
		-- fix if missing money plural
		server.moneyPlural = temp[1]
	else
		server.moneyPlural = temp[2]
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.ircServer then
		if string.find(server.ircServer, ":") then
			temp = string.split(server.ircServer, ":")
			server.ircServer = temp[1]
			server.ircPort = temp[2]
		end
	else
		if row.ircServer ~= "" then
			server.ircServer = row.ircServer
		else
			server.ircServer = ircServer
		end

		if row.ircPort ~= "" then
			server.ircPort = row.ircPort
		else
			server.ircPort = ircPort
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.ircMain == "#new" then
		server.ircMain = ircChannel
		server.ircAlerts = ircChannel .. "_alerts"
		server.ircWatch = ircChannel .. "_watch"
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	if server.telnetPass ~= "" then
		telnetPassword = server.telnetPass
	else
		server.telnetPass = telnetPassword
		conn:execute("UPDATE server SET telnetPass = '" .. escape(telnetPassword) .. "'")
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

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

-- somehow these irc reconnects are crashing the bot if the code is reloaded.  the bot connects to irc without them anyway it seems.
	-- if restartIrc ~= nil then
		-- restartIrc()
	-- end

	-- if ircReconnect ~= nil then
		-- ircReconnect()
	-- end

	whitelistedCountries = {}
	if row.whitelistCountries then
		temp = string.split(row.whitelistCountries, ",")

		max = table.maxn(temp)
		for i=1,max,1 do
			whitelistedCountries[temp[i]] = {}
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	blacklistedCountries = {}
	if row.blacklistCountries then
		temp = string.split(row.blacklistCountries, ",")

		max = table.maxn(temp)
		for i=1,max,1 do
			blacklistedCountries[temp[i]] = {}
		end
	end

	if not server.uptime then
		server.uptime = 0
	end

	if telnetPort then
		if server.telnetPort == 0 then
			server.telnetPort = telnetPort
		end
	end

	if (debug) then display("debug loadServer line " .. debugger.getinfo(1).currentline .. "\n") end

	-- stuff to do after loading the server table when applicable

	-- set everyone's chat colour
	if setupStuff or (server.chatColourPrisoner ~= serverOld.chatColourPrisoner) or (server.chatColourMod ~= serverOld.chatColourMod) or (server.chatColourAdmin ~= serverOld.chatColourAdmin) or (server.chatColourOwner ~= serverOld.chatColourOwner) or (server.chatColourDonor ~= serverOld.chatColourDonor) or (server.chatColourPlayer ~= serverOld.chatColourPlayer) or (server.chatColourNewPlayer ~= serverOld.chatColourNewPlayer) then
		for k,v in pairs(igplayers) do
			setChatColour(k, players[k].accessLevel)
		end
	end

	if setupStuff or (server.botNameColour ~= serverOld.botNameColour) or (server.botName ~= serverOld.botName) or (server.commandPrefix ~= serverOld.commandPrefix) then
		-- if using botman mod
		if server.botman then
			-- set the colour of the bot's name
			sendCommand("bm-change botname [" .. server.botNameColour .. "]" .. server.botName)

			-- update the command prefix
			sendCommand("bm-chatcommands prefix " .. server.commandPrefix)

			if server.commandPrefix == "" then
				sendCommand("bm-chatcommands hide false")
			end

			return
		end

		-- if using BC mod
		if server.stompy and not server.botman then
			-- update the command prefix
			sendCommand("bc-chatprefix " .. prefix)

			if server.commandPrefix == "" then
				sendCommand("bc-chatprefix \"\"")
			end

			return
		end
	end

	if (server.ircPort ~= serverOld.ircPort) or (server.ircServer ~= serverOld.ircServer) or (server.ircBotName ~= serverOld.ircBotName) or (server.ircMain ~= serverOld.ircMain) or (server.ircWatch ~= serverOld.ircWatch) or (server.ircAlerts ~= serverOld.ircAlerts) then
		joinIRCServer()
	end
end


function loadShopCategories()
	local cursor, errorString, row, cat
	-- load shop categories

	getTableFields("shopCategories")

	shopCategories = {}
	cursor,errorString = conn:execute("select * from shopCategories")

	-- add the misc category so it always exists
	if cursor:numrows() > 0 then
		shopCategories["misc"] = {}
		shopCategories["misc"].idx = 1
		shopCategories["misc"].code = "misc"
	end

	row = cursor:fetch({}, "a")
	while row do
		cat = string.lower(row.category) -- only cool cats allowed

		shopCategories[cat] = {}
		shopCategories[cat].idx = row.idx
		shopCategories[cat].code = string.lower(row.code)
		row = cursor:fetch(row, "a")
	end
end


function loadStaff()
	local cursor, errorString, row, adminLevel
	-- load staff

	getTableFields("staff")

    staffList = {}
	cursor,errorString = conn:execute("select * from staff")
	row = cursor:fetch({}, "a")

	while row do
		adminLevel = tonumber(row.adminLevel)

		staffList[row.steam] = {}
		staffList[row.steam].adminLevel = row.adminLevel

		if adminLevel == 0 then
			owners[row.steam] = {}
		end

		if adminLevel == 1 then
			admins[row.steam] = {}
		end

		if adminLevel == 2 then
			mods[row.steam] = {}
		end

		row = cursor:fetch(row, "a")
	end
end


function loadTables(skipPlayers)
	if (debug) then display("debug loadTables\n") end

	loadServer()
	if (debug) then display("debug loaded server\n") end

	if not skipPlayers then
		loadPlayersArchived()
		if (debug) then display("debug loaded playersArchived\n") end
	end

	if not skipPlayers then
		loadPlayers()
		if (debug) then display("debug loaded players\n") end
	end

	loadStaff()
	if (debug) then display("debug loaded staff list\n") end

	loadResetZones()
	if (debug) then display("debug loaded reset zones\n") end

	loadTeleports()
	if (debug) then display("debug loaded teleports\n") end

	loadLocations()
	if (debug) then display("debug loaded locations\n") end

	loadLocationCategories()

	loadBadItems()
	if (debug) then display("debug loaded badItems\n") end

	loadRestrictedItems()
	if (debug) then display("debug loaded restrictedItems\n") end

	loadFriends()
	if (debug) then display("debug loaded friends\n") end

	loadHotspots()
	if (debug) then display("debug loaded hotspots\n") end

	loadVillagers()
	if (debug) then display("debug loaded villagers\n") end

	loadShopCategories()
	if (debug) then display("debug loaded shopCategories\n") end

	loadCustomMessages()
	if (debug) then display("debug loaded customMessages\n") end

	loadProxies()
	if (debug) then display("debug loaded proxies\n") end

	loadBadWords()
	if (debug) then display("debug loaded badWords\n") end

	loadPrefabCopies()
	if (debug) then display("debug loaded prefabCopies\n") end

	loadWaypoints()
	if (debug) then display("debug loaded waypoints\n") end

	loadWhitelist()
	if (debug) then display("debug loaded whitelist\n") end

	loadGimmeZombies()
	if (debug) then display("debug loaded gimmeZombies\n") end

	loadOtherEntities()
	if (debug) then display("debug loaded otherEntities\n") end

	loadBans()
	if (debug) then display("debug loaded bans\n") end

	loadKeystones()
	if (debug) then display("debug loaded keystones\n") end

	loadBases()
	if (debug) then display("debug loaded bases\n") end

	loadDonors()
	if (debug) then display("debug loaded donors\n") end

	loadModBotman()
	if (debug) then display("debug loaded modBotman\n") end

	loadBotMaintenance()

	migrateDonors() -- if the donors table is empty, try to populate it from donors in the players table.

	if (debug) then display("debug loadTables completed\n") end
end


function loadTeleports(tp)
	local cursor, errorString, row, k, v

--	debug = false
	calledFunction = "teleports"
	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	-- load teleports
	getTableFields("teleports")

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if type(teleports) ~= "table" then
		teleports = {}
	end

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	if tp == nil then
		teleports = {}
		cursor,errorString = conn:execute("select * from teleports")
	else
		cursor,errorString = conn:execute("select * from teleports where name = '" .. escape(tp) .. "'")
	end

	row = cursor:fetch({}, "a")

	if (debug) then dbug("debug teleports line " .. debugger.getinfo(1).currentline) end

	while row do
		teleports[row.name] = {}

		for k,v in pairs(teleportsFields) do
			if v.type == "var" or v.type == "big" then
				teleports[row.name][k] = row[k]
			end

			if v.type == "int" then
				teleports[row.name][k] = tonumber(row[k])
			end

			if v.type == "flo" then
				teleports[row.name][k] = tonumber(row[k])
			end

			if v.type == "tin" then
				teleports[row.name][k] = dbTrue(row[k])
			end
		end

		row = cursor:fetch(row, "a")
	end

	if (debug) then dbug("debug teleports line end") end
end


function loadVillagers()
	local cursor, errorString, row

	-- load villagers
	getTableFields("villagers")

	villagers = {}
	cursor,errorString = conn:execute("select * from villagers")
	row = cursor:fetch({}, "a")
	while row do
		villagers[row.steam .. row.village] = {}
		villagers[row.steam .. row.village].steam = row.steam
		villagers[row.steam .. row.village].village = row.village
		row = cursor:fetch(row, "a")
	end
end


function loadWaypoints(steam)
	local idx, k, v
	local cursor, errorString, row

	-- load waypoints
	if steam == nil then
		-- refresh the waypoints table from the db is no steam is specified
		waypoints = {}
	else
		-- first delete all the waypoints belonging to this steam id so we can reload them from the db
		-- we have to do this because we only index them by their record id in the db
		for k,v in pairs(waypoints) do
			if v.steam == steam then
				waypoints[k] = nil
			end
		end
	end

	getTableFields("waypoints")

	if steam == nil then
		cursor,errorString = conn:execute("select * from waypoints")
	else
		cursor,errorString = conn:execute("select * from waypoints where steam = " .. steam)
	end

	row = cursor:fetch({}, "a")
	while row do
		idx = tonumber(row.id)
		waypoints[idx] = {}
		waypoints[idx].id = idx
		waypoints[idx].steam = row.steam
		waypoints[idx].name = row.name
		waypoints[idx].x = tonumber(row.x)
		waypoints[idx].y = tonumber(row.y)
		waypoints[idx].z = tonumber(row.z)
		waypoints[idx].shared = dbTrue(row.shared)
		waypoints[idx].linked = tonumber(row.linked)
		row = cursor:fetch(row, "a")
	end
end


function loadWhitelist()
	local cursor, errorString, row

	-- load whitelist
	getTableFields("whitelist")

    whitelist = {}
	cursor,errorString = conn:execute("select * from whitelist")
	row = cursor:fetch({}, "a")
	while row do
		whitelist[row.steam] = {}
		row = cursor:fetch(row, "a")
	end
end