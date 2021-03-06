--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       https://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing


function matchAll(line, logDate, logTime)
	local pname, pid, number, died, coords, words, temp, msg, claimRemoved
	local dy, mth, yr, hr, min, sec, pm, reason, timestamp, banDate
	local fields, values, x, y, z, id, loc, reset, steam, k, v, rows, tmp
	local pref, value, isChat, cmd
	local cursor, errorString

	if botman.debugAll then
		debug = true
	end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	-- set counter to help detect the bot going offline
	botman.botOfflineCount = 0
	botman.botOffline = false
	botman.lastServerResponseTimestamp = os.time()

	isChat = false

	if botman.botDisabled then
		return
	end

	if botman.getMetrics then
		metrics.telnetLines = metrics.telnetLines + 1
	end

	if string.find(line, "StackTrace:") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorStackTrace then
				metrics.errorStackTrace = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	if string.find(line, "SleeperVolume") then -- ignore lines containing this.
		return
	end

	if string.find(line, "ERR ") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorERR then
				metrics.errorERR = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	-- monitor falling blocks so we can report if it gets excessive in a region
	if string.find(line, "EntityFallingBlock") then
		temp = string.split(line, ",")
		x = string.sub(temp[2], string.find(temp[2], "pos=") + 5)
		y = string.trim(temp[3])
		z = string.trim(string.sub(temp[4], 1, string.len(temp[4]) - 1))
		x = math.floor(x)
		y = math.floor(y)
		z = math.floor(z)

		temp = getRegion(x,z)
		if not fallingBlocks[temp] then
			fallingBlocks[temp] = {}
			fallingBlocks[temp].count = 1
			fallingBlocks[temp].x = x
			fallingBlocks[temp].y = y
			fallingBlocks[temp].z = z
		else
			fallingBlocks[temp].count = fallingBlocks[temp].count + 1
			fallingBlocks[temp].x = x
			fallingBlocks[temp].y = y
			fallingBlocks[temp].z = z
		end

		return
	end


	if string.find(line, "WRN Invalid Admintoken used from") and string.find(line, server.botsIP) then
		if server.useAllocsWebAPI then
			botman.APIOffline = false
			toggleTriggers("api offline")
		end

		if not botman.webTokensListSent then
			send("webtokens list")
			botman.webTokensListSent = os.time()
		else
			if os.time() - botman.webTokensListSent > 60 then
				send("webtokens list")
				botman.webTokensListSent = os.time()
			end
		end

		return
	end


	if string.find(line, "WRN ") then -- ignore lines containing this.
		if not string.find(line, "DENSITYMISMATCH") then
			return
		end
	end

	if string.find(line, "NaN") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorNAN then
				metrics.errorNA = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	if string.find(line, "INF Delta out") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorDelta then
				metrics.errorDelta = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	if string.find(line, "INF Missing ") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1
		end

		return
	end

	if string.find(line, "INF Error ") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorINFError then
				metrics.errorINFError = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	if string.find(line, "IndexOutOfRangeException") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorIndex then
				metrics.errorIndex = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	if string.find(line, "Unbalanced") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorUnbalanced then
				metrics.errorUnbalanced = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	if string.find(line, "->") then -- ignore lines containing this.
		return
	end

	if string.find(line, "NullReferenceException:") then -- ignore lines containing this.
		if botman.getMetrics then
			metrics.errors = metrics.errors + 1

			if not metrics.errorNULREF then
				metrics.errorNULREF = true
				metrics.errorLines[metrics.errorLinesCount] = line
				metrics.errorLinesCount = metrics.errorLinesCount + 1
			end
		end

		return
	end

	logTelnet(line)

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "Chat") or string.find(line, "BCM") then
		isChat = true
	end

	if customMatchAll ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customMatchAll(line) then
			return
		end
	end

	if string.find(line, "*** ERROR: unknown command 'webtokens'") then -- revert to using telnet
		if server.useAllocsWebAPI then
			server.useAllocsWebAPI = false
			conn:execute("UPDATE server set useAllocsWebAPI = 0")
			irc_chat(server.ircMain, "Alloc's mod missing or not fully installed.  The bot is using telnet.")
		end

		return
	end


	if string.find(line, "*** ERROR: Executing command 'admin'") then -- abort processing the admin list
		-- abort reading admin list
		getAdminList = nil

		return
	end

	if string.find(line, "WRN ") then
		return
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	-- grab the server time
	if botman.serverTime == "" or not botman.serverTimeStamp then
		if string.find(line, "INF ") then
			if string.find(string.sub(line, 1, 19), os.date("%Y")) then

				if not botman.serverTimeStamp then
					botman.serverTime = string.sub(line, 1, 10) .. " " .. string.sub(line, 12, 16)
					botman.serverTimeStamp = dateToTimestamp(botman.serverTime)
					botman.serverHour = string.sub(line, 12, 13)
					botman.serverMinute = string.sub(line, 15, 16)
					specialDay = ""

					if (string.find(botman.serverTime, "02-14", 5, 10)) then specialDay = "valentine" end
					if (string.find(botman.serverTime, "12-25", 5, 10)) then specialDay = "christmas" end

					if server.dateTest == nil then
						server.dateTest = string.sub(botman.serverTime, 1, 10)
					end
				end
			end
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if (string.sub(line, 1, 4) == os.date("%Y")) then
		badPlayerJoined = false
		badJoinLine = ""

		if readAnticheat then
			readAnticheat = nil
		end

		if botman.readGG then
			botman.readGG = false -- must be false not nil

			if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('GamePrefs','panel','" .. escape(yajl.to_string(GamePrefs)) .. "')") end

			if botman.initReservedSlots then
				initSlots()
				botman.initReservedSlots = false
			else
				-- setup or adjust the number of slots in the slots table
				addOrRemoveSlots()
			end
		end

		if readWebTokens then
			readWebTokens = nil

			if not botTokenFound then
				botTokenFound = nil

				if server.useAllocsWebAPI then
					server.allocsWebAPIPassword = generatePassword(20)
					conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "'")
					botman.APIOffline = false
					toggleTriggers("api offline")
					send("webtokens add bot " .. server.allocsWebAPIPassword .. " 0")
					botman.lastBotCommand = "webtokens add bot"
				end
			end
		end
	end

	if not server.useAllocsWebAPI then
		if (string.sub(line, 1, 4) == os.date("%Y")) then
			if echoConsole then
				echoConsole = false
				echoConsoleTo = nil
			end

			if 	readResetRegions then
				tempTimer(3, [[loadResetZones(true)]])
			end

			readResetRegions = nil
			readWebTokens = nil
			botTokenFound = nil
			botman.listItems = false

			if getZombies then
				getZombies = nil

				if botman.dbConnected then conn:execute("DELETE FROM gimmeZombies WHERE remove = 1") end
				loadGimmeZombies()

				if botman.dbConnected then conn:execute("DELETE FROM otherEntities WHERE remove = 1") end
				loadOtherEntities()
			end

			if collectBans then
				collectBans = false
				loadBans()
			end

			if readVersion then
				readVersion = nil
				resetVersion = nil
				table.save(homedir .. "/data_backup/modVersions.lua", modVersions)
				if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('modVersions','panel','" .. escape(yajl.to_string(modVersions)) .. "')") end

				if server.allocs and (server.stompy or server.botman) then
					botMaintenance.modsInstalled = true
				else
					botMaintenance.modsInstalled = false
				end

				if botman.dbConnected then conn:execute("DELETE FROM webInterfaceJSON WHERE ident = 'modVersions'") end
				if botman.dbConnected then conn:execute("INSERT INTO webInterfaceJSON (ident, recipient, json) VALUES ('modVersions','panel','" .. escape(yajl.to_string(modVersions)) .. "')") end
				saveBotMaintenance()
			end
		end

		if echoConsole and echoConsoleTo then
			line = line:gsub(",", "") -- strip out commas
			irc_chat(echoConsoleTo, line)
		end
	end


	-- grab steam ID of player joining server if the server is using reserved slots
	if tonumber(server.reservedSlots) > 0 then
		if string.find(line, "INF Steam authentication successful, allowing user") then
			temp = string.split(line, ",")
			pid = string.sub(temp[3], 12, string.len(temp[3]) -1)

			playerConnected(line)

			return
		end
	end


	if string.find(line, "PlayerSpawnedInWorld") then
		tmp = {}

		tmp.coords = string.sub(line, string.find(line, "position:") + 10, string.find(line, ")") -1)
		tmp.coords = tmp.coords:gsub(",", "")
		tmp.spawnedReason = "N/A"

		temp = string.split(line, ", ")
		tmp.pid = string.match(temp[5], "(-?%d+)")

		if igplayers[tmp.pid] then
			igplayers[tmp.pid].spawnedInWorld = true

			if igplayers[tmp.pid].spawnedCoordsOld == "0 0 0" then
				igplayers[tmp.pid].spawnedCoordsOld = igplayers[tmp.pid].spawnedCoords
				igplayers[tmp.pid].spawnedCoords = tmp.coords
				igplayers[tmp.pid].spawnChecked = true
			else
				igplayers[tmp.pid].spawnedCoords = tmp.coords

				if igplayers[tmp.pid].spawnedCoordsOld ~= igplayers[tmp.pid].spawnedCoords then
					igplayers[tmp.pid].tp = tonumber(igplayers[tmp.pid].tp) - 1
				end

				if string.sub(players[tmp.pid].lastCommand, 2, 4) == "bag" then
					igplayers[tmp.pid].tp = tonumber(igplayers[tmp.pid].tp) + 1
					igplayers[tmp.pid].spawnChecked = true
				end
			end

			temp = string.split(tmp.coords, " ")
			igplayers[tmp.pid].spawnedXPos = temp[1]
			igplayers[tmp.pid].spawnedYPos = temp[2]
			igplayers[tmp.pid].spawnedZPos = temp[3]
		end

		if string.find(line, "reason: Died") then
			tmp.spawnedReason = "died"
			igplayers[tmp.pid].spawnChecked = true
			igplayers[tmp.pid].teleCooldown = 3
		end

		if string.find(line, "reason: JoinMultiplayer") then
			tmp.spawnedReason = "joined"
			igplayers[tmp.pid].spawnChecked = true
			igplayers[tmp.pid].teleCooldown = 3
			irc_chat(server.ircMain, "Player " .. tmp.pid .. " " .. igplayers[tmp.pid].name .. " spawned at " .. igplayers[tmp.pid].spawnedXPos .. " " .. igplayers[tmp.pid].spawnedYPos .. " " .. igplayers[tmp.pid].spawnedZPos)
			irc_chat(server.ircAlerts, "Player " .. tmp.pid .. " " .. igplayers[tmp.pid].name .. " spawned at " .. igplayers[tmp.pid].spawnedXPos .. " " .. igplayers[tmp.pid].spawnedYPos .. " " .. igplayers[tmp.pid].spawnedZPos)

			if players[tmp.pid].accessLevel == 0 and not server.allocs then
				message("pm " .. tmp.pid .. " [" .. server.warnColour .. "]ALERT! The bot requires Alloc's mod but it appears to be missing. The bot will not work well without it.[-]")
			end

			if server.botman then
				if players[tmp.pid].nameOverride ~= "" then
					setOverrideChatName(tmp.pid, players[tmp.pid].nameOverride)
				end
			end
		end

		if string.find(line, "reason: Teleport") then
			tmp.spawnedReason = "teleport"

			if igplayers[tmp.pid].spawnPending then
				igplayers[tmp.pid].spawnChecked = true
			else
				igplayers[tmp.pid].spawnChecked = false
			end
		end

		igplayers[tmp.pid].spawnPending = false
		igplayers[tmp.pid].spawnedReason = tmp.spawnedReason
	end


	if string.find(line, "GamePref.", nil, true) then
		if not botman.readGG then
			GamePrefs = {}
		end

		botman.readGG = true
	end


	if string.find(line, "type=Entity") then
		listEntities(line)

		return
	end


	-- Stompy's Mod stuff
	if server.stompy then
		if (string.find(line, "(BCM) Spawn Detected", nil, true)) then
			botman.stompyReportsSpawns = true
			listEntities(line, "BCM")

			return
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	-- look for general stuff
	died = false
	if (string.find(line, "INF GMSG") and string.find(line, "eliminated")) then
		nameStart = string.find(line, "eliminated ") + 11
		pname = stripQuotes(string.trim(string.sub(line, nameStart)))
		died = true
	end

	if (string.find(line, "INF GMSG") and string.find(line, "killed by")) then
		nameStart = string.sub(line, string.find(line, "Player ") + 8, string.find(line, "killed by ") - 1)
		pname = stripQuotes(string.trim(nameStart))
		died = true
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end


	if (string.find(line, "GMSG: Player") and string.find(line, " died")) then
		pname = string.sub(line, string.find(line, "GMSG") + 14, string.len(line) - 6)
		pname = stripQuotes(string.trim(pname))
		died = true
	end

	if died then
		pid = LookupPlayer(pname, "all")

		if (pid ~= 0) then
			if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. igplayers[pid].xPos .. "," .. igplayers[pid].yPos .. "," .. igplayers[pid].zPos .. ",'" .. botman.serverTime .. "','death','" .. escape(pname) .. " died'," .. pid .. ")") end

			igplayers[pid].tp = 1
			igplayers[pid].hackerTPScore = 0
			igplayers[pid].deadX = igplayers[pid].xPos
			igplayers[pid].deadY = igplayers[pid].yPos
			igplayers[pid].deadZ = igplayers[pid].zPos
			igplayers[pid].teleCooldown = 1000
			igplayers[pid].spawnedInWorld = false

			players[pid].deathX = igplayers[pid].xPos
			players[pid].deathY = igplayers[pid].yPos
			players[pid].deathZ = igplayers[pid].zPos

			if tonumber(server.deathCost) > 0 then
				players[pid].cash = tonumber(players[pid].cash) - server.deathCost

				if tonumber(players[pid].cash) < 0 then
					players[pid].cash = 0
				end
			end

			irc_chat(server.ircMain, "Player " .. pid .. " name: " .. pname .. "'s death recorded at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)
			irc_chat(server.ircAlerts, "Player " .. pid .. " name: " .. pname .. "'s death recorded at " .. igplayers[pid].deadX .. " " .. igplayers[pid].deadY .. " " .. igplayers[pid].deadZ)

			if tonumber(server.packCooldown) > 0 then
				if isDonor(pid) then
					players[pid].packCooldown = os.time() + math.floor(server.packCooldown / 2)
				else
					players[pid].packCooldown = os.time() + server.packCooldown
				end
			end

			-- nuke their gimme queue of zeds
			for k, v in pairs(gimmeQueuedCommands) do
				if (v.steam == pid) and (string.find(v.cmd, "se " .. pid)) then
					gimmeQueuedCommands[k] = nil
				end
			end
		end

		return
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "INF BloodMoon starting") and not isChat then
		server.delayReboot = true

		if botman.scheduledRestart then
			if tonumber(server.feralRebootDelay) == 0 then
				botman.scheduledRestartTimestamp = os.time() + ((server.DayLightLength + server.DayNightLength) * 60)
			else
				botman.scheduledRestartTimestamp = os.time() + (server.feralRebootDelay * 60)
			end
		end
	end


	if (string.find(line, "ServerMaxPlayerCount set to")) then
		number = tonumber(string.match(line, " (%d+)"))
		server.ServerMaxPlayerCount = number

		if server.maxPlayers == 0 then
			server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

			if botman.dbConnected then
				conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
			end

			-- if tonumber(server.reservedSlots) > 0 then
				-- sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
			-- end
		else
			if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if botman.dbConnected then
					conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
				end

				-- if tonumber(server.reservedSlots) > 0 then
					-- sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
				-- end
			end
		end

		return
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if not server.useAllocsWebAPI then
		if getAdminList then
			if string.sub(line, 1, 3) ~= "   " or string.find(line, "Defined Group Permissions") or string.find(line, 1, 8) == "Total of" then
				getAdminList = nil
				removeOldStaff()

				return
			end
		end

if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if readBotmanConfig then
			if string.find(line, "</Botman>", nil, true) then
				readBotmanConfig = nil
				table.insert(botman.config, line)
				processBotmanConfig()

				return
			end

			table.insert(botman.config, line)
		end


		if getAdminList then
			temp = string.split(line, ":")
			temp[1] = string.trim(temp[1])
			temp[2] = string.trim(string.sub(temp[2], 1, 18))

			number = tonumber(temp[1])
			pid = temp[2]

			if number == 0 then
				owners[pid] = {}
				owners[pid].remove = false
				staffList[pid] = {}
			end

			if number == 1 then
				admins[pid] = {}
				admins[pid].remove = false
				staffList[pid] = {}
			end

			if number == 2 then
				mods[pid] = {}
				mods[pid].remove = false
				staffList[pid] = {}
			end

			if players[pid] then
				players[pid].accessLevel = tonumber(number)
				players[pid].newPlayer = false
				players[pid].silentBob = false
				players[pid].walkies = false
				players[pid].timeout = false
				players[pid].botTimeout = false
				players[pid].prisoner = false
				players[pid].exiled = false
				players[pid].canTeleport = true
				players[pid].enableTP = true
				players[pid].botHelp = true
				players[pid].hackerScore = 0
				players[pid].testAsPlayer = nil

				if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, exiled = 0, canTeleport = 1, enableTP = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = " .. pid) end
			end

			return
		end


		if playerListItems ~= nil then
			if string.find(line, "Listed ") then
				playerListItems = nil
			end

			return
		end


		if ircListItems ~= nil then
			if string.sub(string.trim(line), 1, 5) == "Slot " then
				ircListItems = nil
			end

			return
		end


		if ircListItems ~= nil then
			if string.sub(line,1,4) == "    " and string.sub(line,5,5) ~= " " then
				irc_chat(players[ircListItems].ircAlias, string.trim(line))
			end
		end


		if playerListItems ~= nil then
			if string.sub(line,1,4) == "    " and string.sub(line,5,5) ~= " " then
				message("pm " .. playerListItems .. " [" .. server.chatColour .. "]" .. string.trim(line) .. "[-]")
			end
		end


		-- collect the ban list
		if collectBans then
			if not string.find(line, "Reason") then
				if string.find(line, "-") then
					temp = string.split(line, "-")

					bannedTo = string.trim(temp[1] .. "-" .. temp[2] .. "-" .. temp[3])
					steam = string.trim(temp[4])
					reason = string.trim(temp[5])

					if botman.dbConnected then
						conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. steam .. ",'" .. escape(reason) .. "',STR_TO_DATE('" .. bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")

						if players[steam] then
							-- also insert the steam owner (will only work if the steam id is different)
							conn:execute("INSERT INTO bans (BannedTo, steam, reason, expiryDate) VALUES ('" .. bannedTo .. "'," .. players[steam].steamOwner .. ",'" .. escape(reason) .. "',STR_TO_DATE('" .. bannedTo .. "', '%Y-%m-%d %H:%i:%s'))")
						end
					end
				end
			end
		end


		-- get zombies into table gimmeZombies
		if getZombies ~= nil then
			if string.find(line, "ombie") then
				temp = string.split(line, "-")

				local entityID = string.trim(temp[1])
				local zombie = string.trim(temp[2])

				if botman.dbConnected then conn:execute("INSERT INTO gimmeZombies (zombie, entityID) VALUES ('" .. zombie .. "'," .. entityID .. ") ON DUPLICATE KEY UPDATE remove = 0") end
				updateGimmeZombies(entityID, zombie)
			else
				if (string.sub(line, 1, 4) ~= os.date("%Y")) then
					temp = string.split(line, "-")

					local entityID = string.trim(temp[1])
					local entity = string.trim(temp[2])

					if botman.dbConnected then conn:execute("INSERT INTO otherEntities (entity, entityID) VALUES ('" .. entity .. "'," .. entityID .. ")") end
					updateOtherEntities(entityID, entity)
				end
			end
		end


		if botman.listItems then
			if string.find(line, " matching items.") then
				botman.listItems = false

				if not server.useAllocsWebAPI then
					send("pm bot_RemoveInvalidItems \"Test\"")
				end
			else
				if botman.dbConnected then
					temp = string.trim(line)
					spawnableItems[temp] = {}
				end
			end
		end


		if string.find(line, "Executing command 'version") or string.find(line, "Game version:", nil, true) then
			readVersion = true
			resetVersion = true
		end


		if echoConsoleTo ~= nil then
			if string.find(line, "Executing command 'webpermission list") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'bm-listplayerfriends") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'bm-listplayerbed") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'lps") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'SystemInfo") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'traderlist") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'help") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'version") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'le'") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'li ") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'se'") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'si ") and string.find(line, echoConsoleTrigger) then
				echoConsole = true
			end

			if string.find(line, "Executing command 'gg'") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'ggs'") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'llp") then
				echoConsole = true
				conn:execute("DELETE FROM keystones WHERE x = 0 AND y = 0 AND z = 0")
			end

			if string.find(line, "Executing command 'ban list'") then
				echoConsole = true
			end

			if string.find(line, "Executing command 'admin list'") then
				echoConsole = true
			end
		end
	end


	if server.coppi and not server.playersCanFly then
		if string.find(line, "PUG: entity_id") then
			words = {}
			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			pid = words[1]
			pid = LookupPlayer(pid)

			x = igplayers[pid].xPos
			y = igplayers[pid].yPos
			z = igplayers[pid].zPos

			if string.find(line, "isUnderGround=True") and accessLevel(pid) > 2 then
				igplayers[pid].noclip = true

				if igplayers[pid].noclipX == 0 and igplayers[pid].noclipZ == 0 then
					igplayers[pid].noclipX = x
					igplayers[pid].noclipY = y
					igplayers[pid].noclipZ = z
				else
					-- dist is horizontal distance travelled since last detection
					dist = distancexyz(x, y, z, igplayers[pid].noclipX, igplayers[pid].noclipY, igplayers[pid].noclipZ)

					-- update coords
					igplayers[pid].noclipX = x
					igplayers[pid].noclipY = y
					igplayers[pid].noclipZ = z

					if igplayers[pid].noclipCount == nil then
						igplayers[pid].noclipCount = 1
					end

					if tonumber(dist) > 30 then
						igplayers[pid].hackerDetection = "noclipping"

						if players[pid].newPlayer then
							players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
						else
							players[pid].hackerScore = tonumber(players[pid].hackerScore) + 10
						end

						alertAdmins("Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z, "warn")
						irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
						irc_chat(server.ircAlerts, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
					else
						if igplayers[pid].noclipX == x and igplayers[pid].noclipY == y and igplayers[pid].noclipZ == z then
							if igplayers[pid].lastHackerAlert == nil then
								igplayers[pid].lastHackerAlert = os.time()

								irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								alertAdmins("Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist), "warn")
							end

							if tonumber(os.time() - igplayers[pid].lastHackerAlert) > 120 then
								igplayers[pid].lastHackerAlert = os.time()
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								alertAdmins("Player " .. pid .. " " .. igplayers[pid].name .. " detected noclipping (count: " .. igplayers[pid].noclipCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z ..  " moved " .. string.format("%d", dist), "warn")
							end
						end
					end

					igplayers[pid].noclipCount = tonumber(igplayers[pid].noclipCount) + 1
				end
			else
				igplayers[pid].noclip = false

				-- update coords anyway
				igplayers[pid].noclipX = x
				igplayers[pid].noclipY = y
				igplayers[pid].noclipZ = z
			end

			return
		end


		if string.find(line, "PGD: entity_id") then
			words = {}
			for word in string.gmatch(line, "(-?%d+)") do
				table.insert(words, word)
			end

			pid = words[1]
			pid = LookupPlayer(pid)
			igplayers[pid].flying = false
			dist = tonumber(words[2]) -- distance above ground
			igplayers[pid].flyingHeight = dist

			x = igplayers[pid].xPos
			y = igplayers[pid].yPos
			z = igplayers[pid].zPos

			if tonumber(dist) > 5 and accessLevel(pid) > 2 then
				if not players[pid].timeout and not players[pid].botTimeout and igplayers[pid].lastTP == nil and not players[pid].ignorePlayer then
					igplayers[pid].flying = true

					if igplayers[pid].flyingX == 0 then
						igplayers[pid].flyingX = x
						igplayers[pid].flyingY = y
						igplayers[pid].flyingZ = z
					else
						-- distance of travel horizontally
						dist = distancexz(x, z, igplayers[pid].flyingX, igplayers[pid].flyingZ)

						-- update coords
						igplayers[pid].flyingX = x
						igplayers[pid].flyingY = y
						igplayers[pid].flyingZ = z

						if tonumber(dist) > 30 then
							if players[pid].newPlayer then
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 20
							else
								players[pid].hackerScore = tonumber(players[pid].hackerScore) + 10
							end
						end

						if tonumber(dist) > 5 then
							igplayers[pid].flyCount = igplayers[pid].flyCount + 1
							igplayers[pid].hackerDetection = "flying"

							if tonumber(igplayers[pid].flyCount) > 1 then
								irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z)
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].sessionCount .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								alertAdmins("Player " .. pid .. " " .. igplayers[pid].name .. " may be flying (count: " .. igplayers[pid].flyCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist), "warn")
							end
						else
							if igplayers[pid].flyingX == x and igplayers[pid].flyingY == y and igplayers[pid].flyingZ == z then
								if igplayers[pid].lastHackerAlert == nil then
									igplayers[pid].lastHackerAlert = os.time()

									alertAdmins("Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist), "warn")
									irc_chat(server.ircMain, "Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z)
									irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								end

								if os.time() - igplayers[pid].lastHackerAlert > 120 then
									alertAdmins("Player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist), "warn")
									irc_chat(server.ircAlerts, server.gameDate .. " player " .. pid .. " " .. igplayers[pid].name .. " detected flying (count: " .. igplayers[pid].flyCount .. ") (session: " .. players[pid].session .. " hacker score: " .. players[pid].hackerScore .. ") " .. x .. " " .. y .. " " .. z .. " moved " .. string.format("%d", dist))
								end
							end
						end
					end
				end
			end

			if not igplayers[pid].noclip and not igplayers[pid].flying then
				if tonumber(players[pid].hackerScore) > 0 then
					players[pid].hackerScore = tonumber(players[pid].hackerScore) - 5
				end
			end

			return
		end
	end

	-- ===================================
	-- infrequent telnet events below here
	-- ===================================

	if string.find(line, "No spawn point found near player!") then
		for k,v in pairs(igplayers) do
			if v.voteRewarded then
				if os.time() - v.voteRewarded < 10 then
					v.voteRewardOwing = 1
					message("pm " .. k .. " [" .. server.warnColour .. "]Oh no! Your reward failed to spawn.  Move outside to somewhere more open and try again by typing {#}claim vote[-]")
					message("pm " .. k .. " [" .. server.warnColour .. "]Claim it before you leave the server.[-]")
					break
				end
			end
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if not server.useAllocsWebAPI then
		if string.find(line, "Executing command 'le'") and string.find(line, server.botsIP) then
			if string.find(line, server.botsIP) then
				botman.listEntities = true
				botman.lastListEntities = os.time()
				connMEM:execute("DELETE FROM memEntities")
			end

			return
		end


		if string.find(line, "Executing command 'li ") then
			botman.listItems = true
			spawnableItems = {}

			return
		end


		if (string.find(line, "Banned until -")) then
			collectBans = true
			conn:execute("TRUNCATE bans")

			return
		end


		-- update owners, admins and mods
		if string.find(line, "Level: SteamID (Player name if online", nil, true) then
			flagAdminsForRemoval()
			getAdminList = true

			return
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if botman.readGG and not string.find(line, "GamePref.", nil, true) then
		botman.readGG = false
	end

	if botman.readGG then
		number = tonumber(string.match(line, " (%d+)"))

		temp = string.split(line, " = ")
		pref = string.sub(temp[1], 10)

		if not temp[2] then
			return
		end

		value = string.sub(line, string.find(line, " = ") + 3)
		GamePrefs[pref] = value

		if (string.find(line, "HideCommandExecutionLog =")) then
			server.HideCommandExecutionLog = number

			return
		end

		if (string.find(line, "MaxSpawnedZombies set to")) then
			server.MaxSpawnedZombies = number

			return
		end

		if (string.find(line, "MaxSpawnedAnimals set to")) then
			server.MaxSpawnedAnimals = number

			return
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number

			return
		end

		if (string.find(line, "BlockDurabilityModifier =")) then
			server.BlockDurabilityModifier = number

			return
		end

		if (string.find(line, "DayNightLength =")) then
			server.DayNightLength = number

			return
		end

		if (string.find(line, "DayLightLength =")) then
			server.DayLightLength = number

			return
		end

		if (string.find(line, "DropOnDeath =")) then
			server.DropOnDeath = number

			return
		end

		if (string.find(line, "DropOnQuit =")) then
			server.DropOnQuit = number

			return
		end

		if (string.find(line, "EnemyDifficulty =")) then
			server.EnemyDifficulty = number

			return
		end

		if (string.find(line, "LandClaimSize =")) then
			server.LandClaimSize = number

			return
		end

		if (string.find(line, "LandClaimExpiryTime =")) then
			server.LandClaimExpiryTime = number

			return
		end

		if (string.find(line, "LootAbundance =")) then
			server.LootAbundance = number

			return
		end

		if (string.find(line, "LootRespawnDays =")) then
			server.LootRespawnDays = number

			return
		end

		if (string.find(line, "ServerPort =")) then
			server.ServerPort = number
			if botman.dbConnected then
				conn:execute("UPDATE server SET ServerPort = " .. server.ServerPort)
			end

			if botman.botsConnected then
				connBots:execute("UPDATE servers SET ServerPort = " .. server.ServerPort .. " WHERE botID = " .. server.botID)
			end

			return
		end

		if (string.find(line, "ZombiesRun =")) then
			server.ZombiesRun = number

			return
		end

		if (string.find(line, "ZombieMove =")) then
			server.ZombiesRun = -1
			server.ZombieMove = number

			return
		end

		if (string.find(line, "ZombieMoveNight =")) then
			server.ZombieMoveNight = number

			return
		end

		if (string.find(line, "ZombieBMMove =")) then
			server.ZombieBMMove = number

			return
		end

		if (string.find(line, "ZombieFeralMove =")) then
			server.ZombieFeralMove = number

			return
		end

		if (string.find(line, "BloodMoonFrequency =")) then
			server.BloodMoonFrequency = number
			server.hordeNight = number

			return
		end

		if (string.find(line, "BloodMoonRange =")) then
			server.BloodMoonRange = number

			return
		end

		if (string.find(line, "ServerName =")) then
			server.serverName = string.trim(string.sub(line, 22))

			if botman.dbConnected then
				conn:execute("UPDATE server SET serverName = '" .. escape(server.serverName) .. "'")
			end

			if botman.botsConnected then
				connBots:execute("UPDATE servers SET serverName = '" .. escape(server.serverName) .. "' WHERE botID = " .. server.botID)
			end

			if string.find(string.lower(server.serverName), "pvp") and not string.find(string.lower(server.serverName), "pve") then
				server.gameType = "pvp"

				if server.northeastZone == "" then
					server.northeastZone = "pvp"
				end

				if server.northwestZone == "" then
					server.northwestZone = "pvp"
				end

				if server.southeastZone == "" then
					server.southeastZone = "pvp"
				end

				if server.southwestZone == "" then
					server.southwestZone = "pvp"
				end
			else
				if server.northeastZone == "" then
					server.northeastZone = "pve"
				end

				if server.northwestZone == "" then
					server.northwestZone = "pve"
				end

				if server.southeastZone == "" then
					server.southeastZone = "pve"
				end

				if server.southwestZone == "" then
					server.southwestZone = "pve"
				end
			end

			return
		end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if (string.find(line, "GameName =")) then
			server.GameName = string.trim(string.sub(line, 20))

			return
		end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if (string.find(line, "ServerMaxPlayerCount =")) then
			number = tonumber(string.match(line, " (%d+)"))
			server.ServerMaxPlayerCount = number

			if server.maxPlayers == 0 then
				server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

				if botman.dbConnected then
					conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
				end

				-- if server.reservedSlots > 0 then
					-- sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
				-- end
			else
				if tonumber(server.maxPlayers) ~= tonumber(server.ServerMaxPlayerCount) - 1 then
					if tonumber(server.reservedSlots) > 0 then
						if tonumber(server.maxPlayers) > tonumber(server.ServerMaxPlayerCount) then
							server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

							if botman.dbConnected then
								conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
							end

	--display("bump max players by 1")
							--sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full

							return
						end

						if tonumber(server.maxPlayers) < tonumber(server.ServerMaxPlayerCount) -1 then
							server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

							if botman.dbConnected then
								conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
							end

	--display("bump max players by 1")
							--sendCommand("sg ServerMaxPlayerCount " .. server.maxPlayers + 1) -- add a slot so reserved slot players can join even when the server is full
						end
					else
						server.maxPlayers = tonumber(server.ServerMaxPlayerCount)

						if botman.dbConnected then
							conn:execute("UPDATE server SET maxPlayers = " .. server.maxPlayers)
						end
					end
				end
			end

			return
		end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

		if (string.find(line, "MaxSpawnedZombies =")) then
			server.MaxSpawnedZombies = number
			-- If we detect this line it means we are receiving data from the server so we set a flag to let us know elsewhere that we got server data ok.
			serverDataLoaded = true

			return
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.sub(line, 1, 4) == "Mod " then
		if resetVersion and not server.useAllocsWebAPI then
			modVersions = {}
			server.allocs = false
			server.botman = false
			server.coppi = false
			server.csmm = false
			server.SDXDetected = false
			server.stompy = false
			server.ServerToolsDetected = false
			server.djkrose = false

			if botman.dbConnected then
				conn:execute("UPDATE server SET SDXDetected = 0, ServerToolsDetected = 0")
			end

			resetVersion = nil
		end

		modVersions[line] = {}
	end


	-- detect CSMM Patrons Mod
	if string.find(line, "Mod CSMM Patrons") then
		server.coppi = true
		server.csmm = true
		temp = string.split(line, ":")
		server.coppiRelease = temp[1]
		server.coppiVersion = tonumber(temp[2])

		return
	end


	-- detect Alloc's Mod
	if string.find(line, "Mod Allocs server fixes") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsServerFixes = temp[2]

		return
	end


	if string.find(line, "Mod Allocs command extensions") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsCommandExtensions = temp[2]

		return
	end


	if string.find(line, "Mod Allocs MapRendering") then
		server.allocs = true
		temp = string.split(line, ":")
		server.allocsMap = temp[2]

		return
	end


	if (string.find(line, "please specify one of the entities")) then
		-- flag all the zombies for removal so we can detect deleted zeds
		if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET remove = 1") end
		if botman.dbConnected then conn:execute("UPDATE otherEntities SET remove = 1") end

		getZombies = true

		return
	end


	if string.find(line, "INF World.Unload") then
		saveLuaTables()

		return
	end

	if string.find(line, "ERROR: unknown command 'bm-playerunderground'") then
		server.scanNoclip = false

		return
	end


	-- detect server version
	if string.find(line, "Game version:") then
		temp = string.sub(line, string.find(line, "Game version:") + 13)
		modVersions["Server " .. string.trim(temp)] = {}

		server.gameVersion = string.trim(string.sub(line, string.find(line, "Game version:") + 14, string.find(line, "Compatibility") - 2))
		if botman.dbConnected then conn:execute("UPDATE server SET gameVersion = '" .. escape(server.gameVersion) .. "'") end

		temp = string.split(server.gameVersion, " ")
		server.gameVersionNumber = tonumber(temp[2])

		if server.gameVersionNumber == 17 and server.updateBranch == "stable" then
			server.updateBranch = "a17"
		end

		return
	end

	-- detect Stompy's API mod
	if string.find(line, "Mod Bad Company Manager:") then
		server.stompy = true
		temp = string.split(line, ":")
		server.stompyVersion = temp[2]

		return
	end

	-- detect Botman mod
	if string.find(line, "Mod Botman:") then
		server.botman = true
		temp = string.split(line, ":")
		server.botmanVersion = temp[2]
		modBotman.version = temp[2]
		if botman.dbConnected then conn:execute("UPDATE modBotman SET version = '" .. temp[2] .. "'") end

		return
	end

	-- detect Jims_Commands mod
	if string.find(line, "Mod Jims_Commands") then
		server.JimsCommands = true
		temp = string.split(line, ":")
		server.JimsCommandsVersion = temp[2]

		return
	end

	-- detect SDX mods
	if string.find(line, "Mod SDX:") or string.find(line, "SDX: ") and not server.SDXDetected then
		server.SDXDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET SDXDetected = 1") end

		return
	end

	-- detect server tools
	if string.find(line, "Mod Server Tools:") or string.find(line, "mod 'Server Tools'") and not server.ServerToolsDetected then
		server.ServerToolsDetected = true
		if botman.dbConnected then conn:execute("UPDATE server SET ServerToolsDetected = 1") end

		return
	end

	-- detect CBSM
	if string.find(line, "pm CBSM") and server.CBSMFriendly then
		if server.commandPrefix == "/" then
			message("say [" .. server.chatColour .. "]CBSM detected.  Bot commands now begin with a ! to not clash with CBSM commands.[-]")
			message("say [" .. server.chatColour .. "]To use bot commands such as /who you must now type !who[-]")
			server.commandPrefix = "!"
			if botman.dbConnected then conn:execute("UPDATE server SET commandPrefix = '!'") end

			return
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if server.coppi then
		-- player bed
		if string.sub(line, 1, 11) == "PlayerBed: " then
			local name = string.sub(line, 12, string.find(line, " at ") - 1)
			steam = LookupPlayer(name)

			if steam then
				local split = string.split(string.sub(line, string.find(line, " at ") + 4), ",")
				x = string.trim(split[1])
				y = string.trim(split[2])
				z = string.trim(split[3])

				players[steam].bedX = x
				players[steam].bedY = y
				players[steam].bedZ = z
				if botman.dbConnected then conn:execute("UPDATE players SET bedX = " .. x .. ", bedY = " .. y .. ", bedZ = " .. z .. " WHERE steam = " .. steam) end
			end

			return
		end
	end


	if (string.find(line, "Process chat error")) then
		irc_chat(server.ircAlerts, "Server error detected. Re-validate to fix: " .. line)
	end


	-- -- check for lag
	-- if string.find(line, "pm LagCheck ") then
		-- temp = string.split(line, "'")
		-- timestamp = tonumber(string.match(temp[2], " (%d+)"))

		-- server.lagged = false
		-- local lag = os.time() - timestamp

		-- if botman.getMetrics then
			-- metrics.telnetCommandLag = lag
		-- end

		-- if tonumber(lag) > server.commandLagThreshold then
			-- server.lagged = true
		-- end

		-- return
	-- end


	if string.find(line, "Playername or entity ID not found.") then

		return
	end


	if string.find(line, "bot_RemoveInvalidItems") then
		removeInvalidItems()
		updateShopItems()
		spawnableItems = {}
		tempTimer(3, [[loadShop()]])

		return
	end


	if string.find(line, "Version mismatch") then
		irc_chat(server.ircAlerts, line)

		return
	end


	if string.find(line, "ERR EXCEPTION:") and string.find(line, "Cannot expand this MemoryStream") and not botman.serverErrorReported then
		-- report memory error
		botman.serverErrorReported = true
		irc_chat(server.ircAlerts, "Server error detected.")
		irc_chat(server.ircAlerts, line)

		return
	end


	if string.find(line, "INF World.Unload") and not string.find(line, "Chat") then
		irc_chat(server.ircMain, "The server has shut down.")
		botman.telnetOffline = true
		botman.APIOffline = true
		toggleTriggers("api offline")
		botman.botOffline = true
		botman.playersOnline = 0
		server.uptime = 0
		anticheatBans = {}

		return
	end


	if string.find(line, "INF StartGame done") and not string.find(line, "Chat") then
		botman.worldGenerating = nil
		botman.APIOffline = false
		toggleTriggers("api offline")
		botman.playersOnline = 0
		server.uptime = 0

		send("gt")
		tempTimer( 2, [[sendCommand("admin list")]] )
		tempTimer( 5, [[sendCommand("version")]] )
		tempTimer( 7, [[sendCommand("gg")]] )

		if server.botman then
			tempTimer( 10, [[sendCommand("bm-resetregions list")]] )
		end

		return
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "INF Reloading serveradmin.xml") then
		sendCommand("admin list")

		return
	end

	if string.find(line, "INF BlockAdded") then
		temp = string.split(line, " ")
		pid = string.match(temp[5], "(-?%d+)")
		x = string.match(temp[6], "(-?%d+)")
		y = string.match(temp[7], "(-?%d+)")
		z = string.match(temp[8], "(-?%d+)")
		claimRemoved = false

		if players[pid].accessLevel > 2 then
			if accessLevel(pid) > 3 then
				region = getRegion(x, z)
				loc, reset = inLocation(x, z)

				if (resetRegions[region] or reset or players[pid].removeClaims) and not players[pid].testAsPlayer then
					claimRemoved = true
					if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. pid .. ",'" .. escape("rlp " .. x .. " " .. y .. " " .. z) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 5) .. "')") end
				else
					if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES (" .. pid .. "," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",0,0) ON DUPLICATE KEY UPDATE expired = " .. dbBool(expired) .. ", remove = 0, removed = 0") end
				end
			else
				if botman.dbConnected then conn:execute("INSERT INTO keystones (steam, x, y, z, expired, remove, removed) VALUES (" .. pid .. "," .. x .. "," .. y .. "," .. z .. "," .. dbBool(expired) .. ",0,0) ON DUPLICATE KEY UPDATE expired = " .. dbBool(expired) .. ", remove = 0, removed = 0") end
			end

			if not claimRemoved then
				if not keystones[x .. y .. z] then
					keystones[x .. y .. z] = {}
					keystones[x .. y .. z].x = x
					keystones[x .. y .. z].y = y
					keystones[x .. y .. z].z = z
					keystones[x .. y .. z].steam = pid
				end
			end
		end

		return
	end


	if getuptime then
		getuptime = nil
		temp = string.split(line, ":")

		-- hours
		tmp  = tonumber(string.match(temp[1], "(%d+)"))
		server.uptime = tmp * 60 * 60

		-- minutes
		tmp  = tonumber(string.match(temp[2], "(%d+)"))
		server.uptime = server.uptime + (tmp * 60)

		-- seconds
		tmp  = tonumber(string.match(temp[3], "(%d+)"))
		server.uptime = server.uptime + tmp

		return
	end


	if string.find(line, "INF Executing command 'bm-uptime'", nil, true) and not server.useAllocsWebAPI then
		getuptime = true
		return
	end


	if string.find(line, "BotStartupCheck")  then
		if string.find(line, "by Telnet from ") then
			temp = string.sub(line, string.find(line, "by Telnet from ") + 15)
			temp = string.split(temp, ":")
			server.botsIP = temp[1]

			conn:execute("UPDATE server SET botsIP = '" .. server.botsIP .. "'")
			return
		end
	end


	if string.find(line, "Server IP:") and not string.find(line, "Chat") then
		if server.IP == "0.0.0.0" then
			temp = string.split(line, ": ")
			server.IP = string.trim(temp[2])
			conn:execute("UPDATE server SET IP = '" .. server.IP .. "'")
		end
	end


	if string.find(line, "INF Started Webserver") then
		botman.worldGenerating = nil
		temp = string.sub(line, string.find(line, " on ") + 4)
		temp = tonumber(temp) - 2
		server.webPanelPort = temp
		conn:execute("UPDATE server set webPanelPort = " .. server.webPanelPort)
		anticheatBans = {}

		if tonumber(server.webPanelPort) == 0 then
			if not server.useAllocsWebAPI then
				server.allocsWebAPIPassword = generatePassword(20)
				conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
				os.remove(homedir .. "/temp/apitest.txt")
				server.useAllocsWebAPI = true

				botman.APIOffline = false
				toggleTriggers("api offline")
				send("webtokens add bot " .. server.allocsWebAPIPassword .. " 0")
				botman.lastBotCommand = "webtokens add bot"
				botman.webTokenLastAdded = os.timer()
			else
				botman.APIOffline = false
				startUsingAllocsWebAPI()
			end
		end

		stackLimits = {}
		tempTimer( 20, [[fixShop()]] )
	end


	if string.find(line, "INF WorldGenerator:Generating", nil, true) then
		if not botman.worldGenerating then
			botman.worldGenerating = true
			irc_chat(server.ircMain, "The bot is temporarily paused while the world is being generated.  If it is still paused by the time you can join the server type " .. server.commandPrefix .. "unpause bot")
		end
	end


	if botman.worldGenerating then
		temp = string.sub(line, string.find(line, "INF") + 4)
		irc_chat(server.ircMain, temp)
	end


	if server.botman then
		if (readAnticheat or string.find(line,"~Botman AntiCheat~", nil, true)) and (not string.find(line, "unauthorized locked container")) then
			tmp = {}
			tmp.name = string.sub(line, string.find(line, "-NAME:") + 6, string.find(line, "--ID:") - 2)
			tmp.id = string.sub(line, string.find(line, "-ID:") + 4, string.find(line, "--LVL:") - 2)
			tmp.hack = ""
			tmp.level = string.sub(line, string.find(line, "-LVL:") + 5)
			tmp.level = string.match(tmp.level, "(-?%d+)")
			tmp.alert = string.sub(line, string.find(line, "-LVL:") + 5)
			tmp.alert = string.sub(tmp.alert, string.find(tmp.alert, " ") + 1)

			if (not staffList[tmp.id]) and (not players[tmp.id].testAsPlayer) and (not bans[tmp.id]) and (not anticheatBans[tmp.id]) then
				if string.find(line, " spawned ") then
					temp = string.split(tmp.alert, " ")
					tmp.entity = stripQuotes(temp[3])
					tmp.x = string.match(temp[4], "(-?\%d+)")
					tmp.y = string.match(temp[5], "(-?\%d+)")
					tmp.z = string.match(temp[6], "(-?\%d+)")
					tmp.hack = "spawned " .. tmp.entity .. " at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

					if tonumber(tmp.level) > 2 then
						irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " Steam: " .. tmp.id .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
						irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " Steam: " .. tmp.id .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
					end
				else
					tmp.x = players[tmp.id].xPos
					tmp.y = players[tmp.id].yPos
					tmp.z = players[tmp.id].zPos
					tmp.hack = "using dm at " .. tmp.x .. " " .. tmp.y .. " " .. tmp.z

					if tonumber(tmp.level) > 2 then
						irc_chat(server.ircMain, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " Steam: " .. tmp.id .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
						irc_chat(server.ircAlerts, "ALERT! Unauthorised admin detected. Player " .. tmp.name .. " Steam: " .. tmp.id .. " Permission level: " .. tmp.level .. " " .. tmp.alert)
					end
				end

				if tonumber(tmp.level) > 2 then
					anticheatBans[tmp.id] = {}
					banPlayer(tmp.id, "10 years", "hacking", "")
					logHacker(botman.serverTime, "Botman anticheat detected " .. tmp.id .. " " .. tmp.name .. " " .. tmp.hack)
					message("say [" .. server.chatColour .. "]Banning player " .. tmp.name .. " 10 years for using hacks.[-]")
					irc_chat("#hackers", "[BANNED] Player " .. tmp.id .. " " .. tmp.name .. " has has been banned for hacking by anticheat.")
					irc_chat("#hackers", line)
					irc_chat(server.ircMain, "[BANNED] Player " .. tmp.id .. " " .. tmp.name .. " has has been banned for hacking.")
					irc_chat(server.ircAlerts, botman.serverTime .. " " .. server.gameDate .. " [BANNED] Player " .. tmp.id .. " " .. tmp.name .. " has has been banned for 10 years for hacking.")
					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. tmp.x .. "," .. tmp.y .. "," .. tmp.z .. ",'" .. botman.serverTime .. "','ban','Player " .. tmp.id .. " " .. escape(tmp.name) .. " has has been banned for 10 years for hacking.'," .. tmp.id .. ")")
					--connBots:execute("INSERT INTO events (server, serverTime, type, event, steam) VALUES ('" .. escape(server.serverName) .. "','" .. botman.serverTime .. "','player banned','Player banned by anticheat " .. escape(tmp.name) .. "'," .. tmp.id .. ")")
				end
			end
		end
	end


	if readWebTokens and not string.find(line, "Defined") then
		if string.find(line, " bot ") then
			readWebTokens = nil
			botTokenFound = nil
			server.useAllocsWebAPI = true
			server.allocsWebAPIUser = "bot"
			server.allocsWebAPIPassword = string.sub(line, string.find(line, " / ") + 3)
			conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
			botman.APIOffline = false
			toggleTriggers("api online")
		end
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "webtokens list", nil, true) then
		botTokenFound = false
		readWebTokens = true
	end

	if string.find(line, "bm-anticheat report", nil, true) then
		readAnticheat = true
	end

--if (debug) then dbug("debug matchAll line " .. debugger.getinfo(1).currentline) end

	if string.find(line, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", nil, true) then
		readBotmanConfig = true
		botman.config = {}
	end

	if string.find(line, "Web user with name=bot and password") and string.find(line, "added with permission level of 0.")  then
		temp = string.sub(line, string.find(line, "password=") + 9, string.find(line, "added with permission") - 1)
		temp = string.trim(temp)
		server.useAllocsWebAPI = true
		server.allocsWebAPIUser = "bot"
		server.allocsWebAPIPassword = temp
		conn:execute("UPDATE server set allocsWebAPIUser = 'bot', allocsWebAPIPassword = '" .. escape(server.allocsWebAPIPassword) .. "', useAllocsWebAPI = 1")
		botman.APIOffline = false
		toggleTriggers("api online")
	end

	if badPlayerJoined then
		if string.find(line, "INF Player set to online") or string.find(line, "INF PlayerSpawnedInWorld") then
			-- abort!  abort!
			badPlayerJoined = false
			badJoinLine = ""
		end

		if badPlayerJoined and not string.find(line, "INF Player connected") then
			playerConnected(badJoinLine .. line)
		end
	end

	-- if Allocs webmap has this error, force the bot to use telnet mode
	if string.find(line, "at AllocsFixes.NetConnections.Servers.Web.Web.HandleRequest") then
		if server.useAllocsWebAPI then
			server.useAllocsWebAPI = false
			conn:execute("UPDATE server set useAllocsWebAPI = 0")
		end
	end

	if readResetRegions then
		if string.find(line, "There are currently no reset regions") then
			readResetRegions = nil
			return
		end

		if string.sub(line, 1, 2) == "r." then
			temp = string.split(v, "%.")
			x = temp[2]
			z = temp[3]

			if not resetRegions[v .. ".7rg"] then
				resetRegions[v .. ".7rg"] = {}
			end

			resetRegions[v .. ".7rg"].x = x
			resetRegions[v .. ".7rg"].z = z
			resetRegions[v .. ".7rg"].inConfig = true
			conn:execute("INSERT INTO resetZones (region, x, z) VALUES ('" .. escape(v .. ".7rg") .. "'," .. x .. "," .. z .. ")")
		end
	end

	if string.find(line, "bm-resetregions list", nil, true) and string.find(line, server.botsIP) then
		readResetRegions = true

		for k,v in pairs(resetRegions) do
			v.inConfig = false
		end
	end

	if string.find(line, "ERROR") and string.find(line, "can only be executed") and not isChat then
		botman.serverStarting = true
	end

end

