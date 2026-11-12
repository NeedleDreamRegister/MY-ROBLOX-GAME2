-- Edit-only regression for the actual Plots initialization code, using fake stores.
-- No real services, DataStores, players, or gameplay scripts are started.
return function(source)
	local first = assert(string.find(source, "\t\t\tlocal initial=PlotData.Fresh()", 1, true), "initializer start missing")
	local last = assert(string.find(source, "\t\t\tentry.world=World.Start(", first, true), "initializer end missing")
	local compile = assert(loadstring("return function(game, PlotData, player, mountain, persistent)\n"
		.. string.sub(source, first, last - 1) .. "\nreturn initial\nend"))
	local prepare = compile()
	local passed = 0
	local function check(record, blocked, persistent, legacy)
		local original = record
		local writes, reads, resets = 0, 0, 0
		local fresh = { marker = "fresh" }
		local store = {}
		function store:GetAsync(key)
			reads += 1
			return key == "player_42" and record or legacy
		end
		function store:SetAsync(_, value)
			writes += 1
			record = value
		end
		local service = { GetDataStore = function() return store end }
		local fakeGame = { GameId = 1, GetService = function() return service end }
		local data = {
			Fresh = function() return fresh end,
			LegacyToFresh = function() resets += 1 return fresh end,
			Initial = function(_, value) assert(value == legacy) return fresh, "fresh" end,
		}
		local mountain = { SetAttribute = function() end }
		local ok, value = pcall(prepare, fakeGame, data, { UserId = 42 }, mountain, persistent)
		assert(writes == 0, "startup overwrote a profile before lease acquisition")
		assert(record == original, "startup replaced the existing record")
		assert(resets == 0, "startup reset legacy progress")
		if blocked then
			assert(not ok and string.find(tostring(value), "Legacy mountain migration required", 1, true), "legacy load must stop explicitly")
		else
			assert(ok and value == fresh, tostring(value))
		end
		if not persistent then assert(reads == 0, "isolated mode contacted a store") end
		passed += 1
	end
	for _, schema in { 1, 2, 3 } do
		for _, expires in { 0, 9999999999 } do
			check({ formatVersion = 1, snapshot = { schemaVersion = schema, initialCells = 165 },
				lease = { owner = "another-server", expiresAt = expires } }, true, true)
		end
	end
	check({ formatVersion = 1, snapshot = { schemaVersion = 3, initialCells = 455 } }, false, true)
	check(nil, false, true)
	check(nil, false, false)
	return { passed = passed, realDataStoreCalls = 0 }
end
