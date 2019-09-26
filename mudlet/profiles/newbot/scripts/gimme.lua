--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- a17 items done

local debug

debug = false -- this should be false unless testing

function arenaPicknMix(wave, counter, playerLevel)
	local r

	counter = counter + 1

	if tonumber(counter) > 10 then
		return 0
	end

	r = tostring(rand(botman.maxGimmeZombies))

	if tablelength(gimmeZombies) == 0 or gimmeZombies == nil then
		return 0
	end

	if not gimmeZombies[r] then
		r = arenaPicknMix(wave, counter, playerLevel)
	else
		if gimmeZombies[r].doNotSpawn then
			r = arenaPicknMix(wave, counter, playerLevel)
		end
	end

	if tonumber(wave) < 4 then
		if (gimmeZombies[r].bossZombie or gimmeZombies[r].doNotSpawn or string.find(gimmeZombies[r].zombie, "eral")) then
			r = arenaPicknMix(wave, counter, playerLevel) -- don't allow feral zombies or boss zombies before round 4
		end
	else
		if tablelength(gimmeZombieBosses) == 0 or gimmeZombieBosses == nil then
			return 0
		end

		if maxBossZombies then
			r = rand(maxBossZombies)
			r = gimmeZombieBosses[r].entityID
		end
	end

	return r
end


function PicknMix(level)
	local r

	if level == nil then
		level = 9001
	end

	if tablelength(gimmeZombies) == 0 or gimmeZombies == nil then
		return 0
	end

	r = tostring(rand(botman.maxGimmeZombies))

	if not gimmeZombies[r] then
		r = PicknMix(level)
	else
		if gimmeZombies[r].doNotSpawn or tonumber(gimmeZombies[r].minPlayerLevel) > tonumber(level) then
			r = PicknMix(level)
		end
	end

	return r
end


function setupArenaPlayers(pid)
	local dist, pointyStick, r, t, i, cmd, k, v

	t = os.time()
	arenaPlayers = {}
	botman.arenaCount = 0

	for k, v in pairs(igplayers) do
		if (distancexyz(v.xPos, v.yPos, v.zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z) < tonumber(locations["arena"].size)) and math.abs(v.yPos - locations["arena"].y) < 4 then
			botman.arenaCount = botman.arenaCount + 1
			arenaPlayers[k] = {}
			arenaPlayers[k].id = v.id
			arenaPlayers[k].steam = k

			-- give arena players stuff
			if not server.botman and not server.stompy then
				sendCommand("give " .. k .. " medicalFirstAidBandage 1")
				sendCommand("give " .. k .. " medicalSplint 1")
				sendCommand("give " .. k .. " drinkJarBeer 1")
				sendCommand("give " .. k .. " trapSpikesNew 3")
			end

			if server.stompy and not server.botman then
				sendCommand("bc-give " .. k .. " medicalFirstAidBandage /c=1 /silent")
				sendCommand("bc-give " .. k .. " medicalSplint /c=1 /silent")
				sendCommand("bc-give " .. k .. " drinkJarBeer /c=1 /silent")
				sendCommand("bc-give " .. k .. " trapSpikesNew /c=3 /silent")
			end

			if server.botman then
				sendCommand("bm-give " .. k .. " medicalFirstAidBandage 1")
				sendCommand("bm-give " .. k .. " medicalSplint 1")
				sendCommand("bm-give " .. k .. " drinkJarBeer 1")
				sendCommand("bm-give " .. k .. " trapSpikesNew 3")
			end

			message("pm " .. k .. " [" .. server.chatColour .. "]You have 10 seconds to prepare for battle![-]")
		end
	end

	if (botman.arenaCount == 0) then
		message("pm " .. pid .. " [" .. server.chatColour .. "]Nobody is in the arena and you can't play from the spectator area.  Get in the arena coward.[-]")
		botman.gimmeHell = 0
	end
end


function announceGimmeHell(wave, delay)
	local cmd

	if (wave == 1) then
		cmd = "Here they come!"
	else
		cmd = "Here comes round " .. wave .. "!"
	end

	conn:execute("INSERT into playerQueue (command, arena, steam, delayTimer) VALUES ('" .. escape(cmd) .. "', true, " .. 0 .. ",'" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + delay) .. "')")
end


function resetGimmeArena()
	local k, v

	botman.gimmeHell = 0
	arenaPlayers = {}
	conn:execute("TRUNCATE playerQueue")

	for k, v in pairs(igplayers) do
		if (distancexyz(v.xPos, v.yPos, v.zPos, locations["arena"].x, locations["arena"].y, locations["arena"].z) < tonumber(locations["arena"].size) + 20) then
			message("pm " .. k .. " [" .. server.chatColour .. "]The Gimme Arena is ready to play![-]")
		end
	end

	botman.faultyChat = false
	return true
end


function queueGimmeHell(wave, level, silent)
	local multiplier, i, zed, p, k, v, cmd

	multiplier = 5

	if botman.gimmeDifficulty == 1 then
		multiplier = 5
	end

	if botman.gimmeDifficulty == 2 then
		multiplier = 8
	end

	if botman.gimmeDifficulty == 3 then
		multiplier = 10
	end

	if botman.gimmeDifficulty == 4 then
		multiplier = 12
	end

	for i = 1, botman.arenaCount * multiplier do
		-- the level of the player that started gimmehell is used to control which zombies can be picked
		pickCounter = 0
		zed = arenaPicknMix(wave, 0, level)

		if tonumber(zed) > 0 then
			p = pickRandomArenaPlayer()

			if tonumber(p) > 0 then
				if gimmeZombies[zed] then
					cmd = "se " .. arenaPlayers[p].id .. " " .. zed
					conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('" .. cmd .. "', true, " .. p .. ")")
				end
			end
		end
	end

	if tonumber(wave) == 4 and silent == nil then
		cmd = "Congratulations!  You have survived to the end of the fight!  Rest now. Tend to your wounded and mourn the fallen."
		conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('" .. escape(cmd) .. "', true, 0)")
		conn:execute("INSERT into playerQueue (command, arena, steam) VALUES ('reset', true, 0)")
	end
end


function gimmeReset()
	local k, v

	-- reset gimmeCount for everyone
	for k, v in pairs(players) do
		players[k].gimmeCount = 0
	end

	if (botman.playersOnline > 0) and server.allowGimme == true then
		message("say [" .. server.chatColour .. "]Gimme has been reset!  Type " .. server.commandPrefix .. "gimme to play. " .. server.commandPrefix .. "help gimme for info.")
	end
end


function gimme(pid, testGimme)
	if (debug) then
		dbug("debug gimme line " .. debugger.getinfo(1).currentline)
		dbug("gimme pid " .. pid)
	end

	local cmd, maxGimmies, dist, r, rows, row, prize, category, entity, description, quality
	local pname = players[pid].name
	local playerid = igplayers[pid].id
	local zombies = tonumber(igplayers[pid].zombies)

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if botman.maxGimmeZombies == nil then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]Oh No! Gimme is empty![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]Oh No! Gimme is empty![-]")
		end

		-- the gimmeZombies table is empty so run se to fill it.
		sendCommand("se")
		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (botman.faultyGimme) then
		dbugi("Fault occurred in Gimme #: " .. botman.faultyGimmeNumber)
	end

	botman.faultyGimme = true

	if players[pid].donor == true then
		maxGimmies = 16
	else
		maxGimmies = 11
	end

	if players[pid].gimmeCount == nil then
		players[pid].gimmeCount = 0
	end

	if tonumber(players[pid].gimmeCount) < tonumber(maxGimmies) then
		players[pid].gimmeCount = players[pid].gimmeCount + 1
	else
		message("pm " .. pid .. " [" .. server.chatColour .. "]You are out of gimmies.  You have to wait until the next gimme reset.[-]")
		botman.faultyGimme = false
		return
	end

	if testGimme ~= nil then
		r = tonumber(testGimme)
		message("pm " .. pid .. " [" .. server.chatColour .. "]Testing gimme prize " .. testGimme .. "[-]")
	else
		if server.gimmeZombies then
			r = math.random(1, botman.maxGimmeZombies + 30)
		else
			r = rand(5)

			if r==1 then
				if (not server.gimmePeace) then
					message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
				else
					message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
				end

				botman.faultyGimme = false
				return
			end

			if r == 2 or r == 3 then
				r = botman.maxGimmeZombies + 1
			end

			if r==4 then
				if (not server.gimmePeace) then
					message("say [" .. server.chatColour .. "]" .. pname .. " nearly won a cool prize![-]")
				else
					message("pm " .. pid .. " [" .. server.chatColour .. "]You nearly won a cool prize![-]")
				end

				botman.faultyGimme = false
				return
			end

			if r==5 then
				if (not server.gimmePeace) then
					message("say [" .. server.chatColour .. "]Surprise! " .. pname .. " didn't win anything.[-]")
				else
					message("pm " .. pid .. " [" .. server.chatColour .. "]Surprise! You didn't win anything.[-]")
				end

				botman.faultyGimme = false
				return
			end
		end
	end

	botman.faultyGimmeNumber = r

	if debug then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end
	if debug then dbug("gimme random  " .. r .. " player = " .. pname) end
	if debug then dbug("max zombie id " .. botman.maxGimmeZombies) end

	if r <= botman.maxGimmeZombies then
		if gimmeZombies[tostring(r)] == nil then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
			end

			botman.faultyGimme = false
			return
		else
			if (gimmeZombies[tostring(r)].doNotSpawn) then
				if (not server.gimmePeace) then
					message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
				else
					message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
				end

				botman.faultyGimme = false
				return
			end
		end
	end

	if debug then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	-- get name of entity
	if gimmeZombies[tostring(r)] then
		entity = gimmeZombies[tostring(r)].zombie

		if string.find(entity, "emplate") or string.find(entity, "nvisible") then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " won a party but nobody came.[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You won a party but nobody came.[-]")
			end

			botman.faultyGimme = false
			return
		end
	end

	spawnCount = 1

	if r <= botman.maxGimmeZombies then
		-- nasty zombies
		descriptor = rand(6)
		chanceOfMultiples = rand(50)

		if (chanceOfMultiples > 25) then
			if (zombies > 99) and (zombies < 300) then spawnCount = rand(3) end
			if (zombies > 299) and (zombies < 500) then spawnCount = rand(4) end
			if (zombies > 499) and (zombies < 1000) then spawnCount = rand(5) end
			if (zombies > 999) and (zombies < 5000) then spawnCount = rand(6) end
			if (zombies > 4999) then spawnCount = rand(8) end
		end

		if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

		-- set up critter description
		if (spawnCount == 1) then
			if (descriptor == 1) then
				description = "a surprised "
			end

			if (descriptor == 2) then
				description = "an angry "
			end

			if (descriptor == 3) then
				description = "a very dangerous "
			end

			if (descriptor == 4) then
				description = "a murderous "
			end

			if (descriptor == 5) then
				description = "a pissed off "
			end

			if (descriptor == 6) then
				description = "an adorable "
			end
		else
			if (descriptor == 1) then
				description = "surprised "
			end

			if (descriptor == 2) then
				description = "angry "
			end

			if (descriptor == 3) then
				description = "very dangerous "
			end

			if (descriptor == 4) then
				description = "murderous "
			end

			if (descriptor == 5) then
				description = "pissed off "
			end

			if (descriptor == 6) then
				description = "adorable "
			end
		end

		if (specialDay == "christmas") then
			if (spawnCount == 1) then
				if (descriptor == 1) then
					description = "a jolly "
				end

				if (descriptor == 2) then
					description = "an over-weight "
				end

				if (descriptor == 3) then
					description = "a very festive "
				end

				if (descriptor == 4) then
					description = "a party "
				end

				if (descriptor == 5) then
					description = "a rather drunk "
				end

				if (descriptor == 6) then
					description = "a red nosed "
				end
			else
				if (descriptor == 1) then
					description = "jolly "
				end

				if (descriptor == 2) then
					description = "santa "
				end

				if (descriptor == 3) then
					description = "cheerful "
				end

				if (descriptor == 4) then
					description = "celebrating "
				end

				if (descriptor == 5) then
					description = "drunk "
				end

				if (descriptor == 6) then
					description = "partying "
				end
			end
		end

		if (specialDay == "valentine") then
			if (spawnCount == 1) then
				if (descriptor == 1) then
					description = "a romantic "
				end

				if (descriptor == 2) then
					description = "an attractive "
				end

				if (descriptor == 3) then
					description = "a very special "
				end

				if (descriptor == 4) then
					description = "a besotted "
				end

				if (descriptor == 5) then
					description = "a single and looking "
				end

				if (descriptor == 6) then
					description = "an eligible "
				end
			else
				if (descriptor == 1) then
					description = "eligible "
				end

				if (descriptor == 2) then
					description = "super sexy "
				end

				if (descriptor == 3) then
					description = "lusty "
				end

				if (descriptor == 4) then
					description = "infatuated "
				end

				if (descriptor == 5) then
					description = "approachable "
				end

				if (descriptor == 6) then
					description = "gorgeous "
				end
			end
		end
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 1) then
		if botman.maxGimmePrizes == nil then
			botman.maxGimmePrizes = getMaxGimmePrizes()
		end

		r = rand(botman.maxGimmePrizes)
		cursor,errorString = conn:execute("select * from gimmePrizes limit " .. r - 1 .. ",1")
		row = cursor:fetch({}, "a")

		qty = rand(tonumber(row.prizeLimit))
		category = row.category
		prize = row.name
		qual = row.quality
		quality = (10 * players[pid].level) + rand(50, -50)
		if quality < 50 then quality = 50 end

		if tonumber(server.gameVersionNumber) < 17 then
			if quality > 600 then quality = 600 end
		else
			if quality > 600 then quality = 6 end
		end

		description = ""
		if (qty == 1) then description = "a " end

		if (category == "weapon") then
			descr = rand(12)

			if (descr==1) then
				description = description .. "shiny new "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 600
				else
					quality = 5
				end
			end

			if (descr==2) then description = description .. "dangerous " end

			if (descr==3) then
				description = description .. "sharp "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 450
				else
					quality = 4
				end
			end

			if (descr==4) then
				description = description .. "well crafted "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 500
				else
					quality = 5
				end
			end

			if (descr==5) then
				description = description .. "knock-off "
			end

			if (descr==6) then
				description = description .. "banged up "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 200
				else
					quality = 2
				end
			end

			if (descr==7) then
				description = description .. "basic "
			end

			if (descr==8) then
				description = description .. "barely used "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 560
				else
					quality = 5
				end
			end

			if (descr==9) then
				description = description .. "blood stained "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 250
				else
					quality = 2
				end
			end

			if (descr==10) then
				description = description .. "common "
			end

			if (descr==11) then
				description = description .. "dull "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 100
				else
					quality = 1
				end
			end

			if (descr==12) then
				description = description .. "rusty "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 50
				else
					quality = 1
				end
			end
		end

		if (category == "book") then
			descr = rand(12)

			if (descr==1) then description = description .. "rare " end
			if (descr==2) then description = description .. "wordy " end
			if (descr==3) then description = description .. "well written " end
			if (descr==4) then description = description .. "useful " end
			if (descr==5) then description = description .. "tatty old " end
			if (descr==6) then description = description .. "scruffy " end
			if (descr==7) then description = description .. "faded " end
			if (descr==8) then description = description .. "torn " end
			if (descr==9) then description = description .. "soggy " end
			if (descr==10) then description = description .. "dirty " end
			if (descr==11) then description = description .. "chewed " end
			if (descr==12) then description = description .. "ratty " end
		end

		if (category == "misc") then
			descr = rand(12)

			if (descr==1) then description = description .. "common " end
			if (descr==2) then description = description .. "boring " end
			if (descr==3) then description = description .. "interesting " end
			if (descr==4) then description = description .. "damaged " end
			if (descr==5) then description = description .. "rare " end
			if (descr==6) then description = description .. "stupid " end
			if (descr==7) then description = description .. "stinky " end
			if (descr==8) then description = description .. "useless " end
			if (descr==9) then description = description .. "amazing " end
			if (descr==10) then description = description .. "collectable " end
			if (descr==11) then description = description .. "dull " end
			if (descr==12) then description = description .. "uninteresting " end
		end

		if (category == "health") then
			descr = rand(10)

			if (descr==1) then description = description .. "dodgy " end
			if (descr==2) then description = description .. "sterile " end
			if (descr==3) then description = description .. "generic " end
			if (descr==4) then description = description .. "expensive " end
			if (descr==5) then description = description .. "highly saught after " end
			if (descr==6) then description = description .. "common " end
			if (descr==7) then description = description .. "knock-off " end
			if (descr==8) then description = description .. "yucky " end
			if (descr==9) then description = description .. "gross " end
			if (descr==10) then description = description .. "spare " end
		end

		if (category == "food") then
			descr = rand(12)

			if (descr==1) then description = description .. "delicious " end
			if (descr==2) then description = description .. "yummy " end
			if (descr==3) then description = description .. "yucky " end
			if (descr==4) then description = description .. "tasty " end
			if (descr==5) then description = description .. "bland " end
			if (descr==6) then description = description .. "boring " end
			if (descr==7) then description = description .. "expired " end
			if (descr==8) then description = description .. "chewy " end
			if (descr==9) then description = description .. "crunchy " end
			if (descr==10) then description = description .. "tainted " end
			if (descr==11) then description = description .. "stinky " end
			if (descr==12) then description = description .. "funky " end
		end

		if (category == "tools") then
			descr = rand(10)

			if (descr==1) then description = description .. "handy " end
			if (descr==2) then description = description .. "utilitarian " end
			if (descr==3) then description = description .. "dirty " end
			if (descr==4) then description = description .. "rusty " end
			if (descr==5) then description = description .. "sturdy " end
			if (descr==6) then description = description .. "ACME " end
			if (descr==7) then description = description .. "knock-off " end
			if (descr==8) then description = description .. "genuine " end
			if (descr==9) then description = description .. "basic " end
			if (descr==10) then description = description .. "designer " end
		end

		if (category == "clothes") then
			descr = rand(10)

			if (descr==1) then
				description = description .. "shitty "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 200
				else
					quality = 2
				end
			end

			if (descr==2) then
				description = description .. "sturdy "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 500
				else
					quality = 5
				end
			end

			if (descr==3) then
				description = description .. "tatty "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 200
				else
					quality = 2
				end
			end

			if (descr==4) then
				description = description .. "used "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 300
				else
					quality = 3
				end
			end

			if (descr==5) then
				description = description .. "brand new "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 600
				else
					quality = 5
				end
			end

			if (descr==6) then
				description = description .. "soiled "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 400
				else
					quality = 4
				end
			end

			if (descr==7) then
				description = description .. "boring "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 300
				else
					quality = 3
				end
			end

			if (descr==8) then
				description = description .. "fabulous "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 550
				else
					quality = 5
				end
			end

			if (descr==9) then
				description = description .. "natty "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 550
				else
					quality = 5
				end
			end

			if (descr==10) then
				description = description .. "stylish "

				if tonumber(server.gameVersionNumber) < 17 then
					quality = 550
				else
					quality = 5
				end
			end
		end

		description = description .. prize

		if (qty > 1) then
			description = qty .. " " .. description .. "s"
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won " .. description .. "[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You won " .. description .. "[-]")
		end

		cmd = ""
		if qual ~= 0 then
			cmd = "give " .. pid .. " " .. prize .. " " .. qty .. " " .. quality

			if server.stompy then
				cmd = "bc-give " .. pid .. " " .. prize .. " /c=" .. qty .. " /q=" .. quality .. " /silent"
			end

			if server.botman then
				cmd = "bm-give " .. pid .. " " .. prize .. " " .. qty .. " " .. quality
			end
		else
			cmd = "give " .. pid .. " " .. prize .. " " .. qty

			if server.stompy then
				cmd = "bc-give " .. pid .. " " .. prize .. " /c=" .. qty .. " /silent"
			end

			if server.botman then
				cmd = "bm-give " .. pid .. " " .. prize .. " " .. qty
			end
		end

		sendCommand(cmd)

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 2) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " almost won a prize![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won a prize![-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 3) then
		tmp = {}
		for k,v in pairs(otherEntities) do
			if string.find(v.entity, "abbit") then
				tmp.entityid = k
			end
		end

		if tmp.entityid ~= nil then
			spawnCount = rand(7,2)
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " BUNNIES![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You won " .. spawnCount .. " BUNNIES![-]")
			end

			for i = 1, spawnCount do
				cmd = "se " .. playerid .. " " .. tmp.entityid
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
			end
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			end
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 4) then
		r = rand(100)
		if (r < 70) then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " almost won an epic prize![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You almost won an epic prize![-]")
			end

			botman.faultyGimme = false
			return
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won epic litter![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You won epic litter![-]")
		end

		t = os.time()
		for i = 1, 100 do
			r = rand(7)

			if tonumber(server.gameVersionNumber) < 17 then
				if (r == 1) then litter = "canEmpty" end -- A16
				if (r == 2) then litter = "candyTin" end -- A16
				if (r == 3) then litter = "paper" end -- A16
				if (r == 4) then litter = "cloth" end -- A16
				if (r == 5) then litter = "yuccaFibers" end -- A16
				if (r == 6) then litter = "dirt" end -- A16
				if (r == 6) then litter = "bulletCasing" end -- A16
				if (r == 7) then litter = "emptyJar" end -- A16
			else
				if (r == 1) then litter = "drinkCanEmpty" end
				if (r == 2) then litter = "resourceCandyTin" end
				if (r == 3) then litter = "resourcePaper" end
				if (r == 4) then litter = "resourceRockSmall" end
				if (r == 5) then litter = "resourceYuccaFibers" end
				if (r == 6) then litter = "resourceScrapIron" end
				if (r == 6) then litter = "resourceBulletCasing" end
				if (r == 7) then litter = "drinkJarEmpty" end
			end

			cmd = "give " .. pid .. " " .. litter .. " 1"
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 5) then
		item = rand(12)

		if tonumber(server.gameVersionNumber) < 17 then
			if (item == 1) then prize = "canBeef" end -- A16
			if (item == 2) then prize = "canChili" end -- A16
			if (item == 3) then prize = "canPasta" end -- A16
			if (item == 4) then prize = "gasCan" end -- A16
			if (item == 5) then prize = "firstAidBandage" end -- A16
			if (item == 6) then prize = "beer" end -- A16
			if (item == 7) then prize = "shades" end -- A16
			if (item == 8) then prize = "bottledWater" end -- A16
			if (item == 9) then prize = "baconAndEggs" end -- A16
			if (item == 10) then prize = "vegetableStew" end -- A16
			if (item == 11) then prize = "goldenRodTea" end -- A16
			if (item == 12) then prize = "coffee" end -- A16
		else
			if (item == 1) then prize = "foodCanBeef" end
			if (item == 2) then prize = "foodCcanChili" end
			if (item == 3) then prize = "foodCcanPasta" end
			if (item == 4) then prize = "ammoGasCan" end
			if (item == 5) then prize = "medicalFirstAidBandage" end
			if (item == 6) then prize = "drinkJarBeer" end
			if (item == 7) then prize = "shades" end
			if (item == 8) then prize = "drinkJarBoiledWater" end
			if (item == 9) then prize = "foodBaconAndEggs" end
			if (item == 10) then prize = "foodVegetableStew" end
			if (item == 11) then prize = "drinkJarGoldenRodTea" end
			if (item == 12) then prize = "drinkJarCoffee" end
		end

		for k, v in pairs(igplayers) do
			if (k ~= pid) then
				cmd = "give " .. k .. " " .. prize .. " 1"

				if server.stompy then
					cmd = "bc-give " .. k .. " " .. prize .. " /c=1 /silent"
				end

				if server.botman then
					cmd = "bm-give " .. k .. " " .. prize .. " 1"
				end

				sendCommand(cmd)
			end
		end

		message("say [" .. server.chatColour .. "]" .. pname .. " won a " .. prize .. " for everyone! One for you, one for you, and you and.. oh sorry " .. pname .. " none left.[-]")
		message("say [" .. server.chatColour .. "]Everyone else collect your prize![-]")
		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 6) then
		descr = rand(9)

		if (descr == 1) then cmd = "Nothing!" end
		if (descr == 2) then cmd = "Nothing!" end
		if (descr == 3) then cmd = "Nothing!" end

		if (descr == 4) then
			cmd = "*BZZT*  Oh no!  It's eaten another gimmie![-]"
			players[pid].gimmeCount = players[pid].gimmeCount + 1
		end

		if (descr == 5) then
			i = rand(4)

			cmd = i .. " extra gimmies! =D"
			players[pid].gimmeCount = players[pid].gimmeCount - i
		end

		if (descr > 5 and descr < 10) then
			r = rand(10)
			 if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
				cmd = "say Every panels lit up! They're coming out of the walls! RUN !![-]"
			else
				message("pm [" .. server.chatColour .. "]" .. playerid .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
				cmd = "pm " .. playerid .. " [" .. server.chatColour .. "]Every panels lit up! They're coming out of the walls! RUN !![-]"
			end

			tempTimer( 1, [[message("]].. cmd .. [[")]] )

			for i = 1, r do
				z = PicknMix(players[pid].level)

				if gimmeZombies[z] then
					cmd = "se " .. playerid .. " " .. z
					conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
				end
			end

			botman.faultyGimme = false
			return
		end

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " Ruh Roh! Gimmies short circuited!  You win..[-]")
			cmd = "say [" .. server.chatColour .. "]" .. cmd .. "[-]"
			tempTimer( 2, [[message("]].. cmd .. [[")]] )
		else
			cmd = "pm " .. pid .. " [" .. server.chatColour .. "]" .. cmd .. "[-]"
			tempTimer( 2, [[message("]].. cmd .. [[")]] )
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 7) then
		tmp = {}
		for k,v in pairs(gimmeZombies) do
			if string.find(v.zombie, "ZombieDog") then
				tmp.entityid = v.entityID
			end
		end

		if tmp.entityid ~= nil then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]HAPPY BIRTHDAY " .. pname .. "!  We got you a puppy![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]HAPPY BIRTHDAY " .. pname .. "! We got you a puppy![-]")
			end

			cmd = "se " .. playerid .. " " .. tmp.entityid
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			end
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 8) then
		tmp = {}
		for k,v in pairs(gimmeZombies) do
			if string.find(v.zombie, "Snow") then
				tmp.entityid = v.entityID
			end
		end

		if tmp.entityid ~= nil then
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You won a HUGE STEAK!!! " .. pname .. "!  But this guy ate it :(  Deal with him![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You won a HUGE STEAK!!! " .. pname .. "!  But this guy ate it :(  Deal with him![-]")
			end

			cmd = "se " .. playerid .. " " .. tmp.entityid
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
			end
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 9) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won invisiblity!  Press Alt-F4 to claim your prize!!![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You won invisiblity!  Press Alt-F4 to claim your prize!!![-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 10) then
		spawnCount = rand(30,10)
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " ate a bad potato and is shitting potatoes everywhere![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " ate a bad potato and is shitting potatoes everywhere![-]")
		end

		for i = 1, spawnCount do
			if tonumber(server.gameVersionNumber) < 17 then
				cmd = "give " .. pid .. " potato 1"
			else
				cmd = "give " .. pid .. " foodBakedPotato 1"
			end

			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 11) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " voted first place WINNER! Here's your trophy.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " voted first place WINNER! Here's your trophy.[-]")
		end

		if tonumber(server.gameVersionNumber) < 17 then
			cmd = "give " .. pid .. " trophy 1"
		else
			cmd = "give " .. pid .. " resourceTrophy1 1"
		end

		conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 12) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won a care package via air drop.  Gee I hope the pilot knows where the drop zone is![-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " won a care package via air drop.  Gee I hope the pilot knows where the drop zone is![-]")
		end

		sendCommand("spawnairdrop")
		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 13) then
		players[pid].baseCooldown = 0
		conn:execute("UPDATE players SET baseCooldown = 0 WHERE steam = " .. pid)

		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won a get out of Dodge free card!  Their base cooldown has been reset.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. " won a get out of Dodge free card!  Your base cooldown has been reset.[-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	-- if (r == botman.maxGimmeZombies + 14) then
		-- if (not server.gimmePeace) then
			-- message("say [" .. server.chatColour .. "]" .. pname .. " won an air drop, but it is guarded by a boss zombie!  Show him who's boss.[-]")
		-- else
			-- message("pm " .. pid .. " [" .. server.chatColour .. "]You won an air drop, but it is guarded by a boss zombie!  Show him who's boss.[-]")
		-- end

		-- tmp = {}
		-- for k,v in pairs(otherEntities) do
			-- if string.find(v.entity, "eneral") then
				-- tmp.entityid = k
			-- end
		-- end

		-- cmd = "se " .. playerid .. " " .. tmp.entityid
		-- conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

		-- tmp = {}
		-- for k,v in pairs(gimmeZombies) do
			-- if string.find(v.zombie, "ZombieDog") then
				-- tmp.entityid = v.entityID
			-- end
		-- end

		-- cmd = "se " .. playerid .. " " .. tmp.entityid
		-- conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")

		-- botman.faultyGimme = false
		-- return
	-- end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if tonumber(r) > botman.maxGimmeZombies + 14 and tonumber(r) < botman.maxGimmeZombies + 21 then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You lose!  Try again " .. pname .. "[-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (r == botman.maxGimmeZombies + 21) then
		if tonumber(server.gameVersionNumber) < 17 then
			spawnCount = rand(30,10)
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " won some shit.[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]Here is your prize. It's a bit shitty but congrats! [-]")
			end

			for i = 1, spawnCount do
				cmd = "give " .. pid .. " turd 1"
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
			end
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]Something sticky is blocking the Gimme chute.[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]Something sticky is blocking the Gimme chute.[-]")
			end
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if r > botman.maxGimmeZombies + 21 then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " did not win a prize.[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You did not win a prize.[-]")
		end

		botman.faultyGimme = false
		return
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (spawnCount == 1) then
		if (not server.gimmePeace) then
			message("say [" .. server.chatColour .. "]" .. pname .. " won " .. description .. entity .. "[-]")
		else
			message("pm " .. pid .. " [" .. server.chatColour .. "]You have won " .. description .. entity .. "[-]")
		end
	else
		if (zombies > 2499) then
			descr = " won " .. spawnCount .. " Pick 'N Mix Zombies!"

			if spawnCount == 6 then
				descr = " won a 6 pack of Ready-To-Die zombies!"
			end

			if spawnCount == 12 then
				descr = " won a 12 pack of zombies!"
			end

			if spawnCount == 13 then
				descr = " won a bakers dozen of zombies!"
			end

			if spawnCount == 24 then
				descr = " won a hearty 24 pack of zombies!"
			end

			if spawnCount == 50 then
				descr = " won ALL THE ZOMBIES!"
			end

			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. descr .. "[-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]" .. pname .. descr .. "[-]")
			end
		else
			if (not server.gimmePeace) then
				message("say [" .. server.chatColour .. "]" .. pname .. " won " .. spawnCount .. " " .. description .. entity .."s![-]")
			else
				message("pm " .. pid .. " [" .. server.chatColour .. "]You have won " .. spawnCount .. " " .. description .. entity .."s![-]")
			end
		end
	end

	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

	if (spawnCount == 1) then
if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end

		if otherEntities[tostring(r)] then
			if otherEntities[tostring(r)].doNotSpawn then
	if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end
				if (not server.gimmePeace) then
					message("say [" .. server.alertColour .. "][ERROR][-][" .. server.chatColour .. "] Gimme prize stuck in chute! [-][" .. server.alertColour .. "][ERROR][-]")
				else
					message("pm " .. pid .. " [" .. server.alertColour .. "][ERROR][-][" .. server.chatColour .. "] Gimme prize stuck in chute! [-][" .. server.alertColour .. "][ERROR][-]")
				end

				botman.faultyGimme = false
				return
			end
		end

if (debug) then dbug("debug gimme line " .. debugger.getinfo(1).currentline) end
		r = tostring(r)

		if gimmeZombies[r] then
			cmd = "se " .. playerid .. " " .. r
			conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
		end

		if (specialDay == "valentine") then
			z = rand(4)
			if z == 1 then
				if tonumber(server.gameVersionNumber) < 17 then
					sendCommand("give " .. pid .. " yellowflower 1") -- A16
				end
			end

			if z == 2 then
				if tonumber(server.gameVersionNumber) < 17 then
					sendCommand("give " .. pid .. " plantChrysanthemum 1") -- A16
				end
			end

			if z == 3 then
				if tonumber(server.gameVersionNumber) < 17 then
					sendCommand("give " .. pid .. " goldenrod 1") -- A16
				end
			end

			if z == 4 then
				if tonumber(server.gameVersionNumber) < 17 then
					sendCommand("give " .. pid .. " cotton 1") -- A16
				end
			end
		end
	else
		if (zombies > 2499) then
			for i = 1, spawnCount do
				cmd = "se " .. playerid .. " " .. PicknMix()
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
			end
		else
			for i = 1, spawnCount do
				r = tostring(r)

				if gimmeZombies[r] then
					cmd = "se " .. playerid .. " " .. r
					conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
				end

				if (specialDay == "valentine") then
					z = rand(4)

					if tonumber(server.gameVersionNumber) < 17 then
						if z == 1 then cmd = "give " .. pid .. " yellowflower 1" end -- A16
						if z == 2 then cmd = "give " .. pid .. " plantChrysanthemum 1" end -- A16
						if z == 3 then cmd = "give " .. pid .. " goldenrod 1" end -- A16
						if z == 4 then cmd = "give " .. pid .. " cotton 1" end -- A16
					end

					conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. pid .. ")")
				end
			end
		end
	end

if debug then dbug("debug gimme end") end

	botman.faultyGimme = false
	return
end
