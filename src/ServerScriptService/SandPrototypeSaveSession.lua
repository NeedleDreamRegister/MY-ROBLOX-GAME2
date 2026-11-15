-- One atomic record for the small shared test world. Store is injected for tests.
local Snapshot = require(script.Parent:WaitForChild("SandPrototypeSnapshot"))
local Codec = require(script.Parent:WaitForChild("SandPrototypeSaveCodec"))
local Geometry=require(game:GetService("ReplicatedStorage").SandPrototypeGeometry)
local SaveSession = {}
SaveSession.__index = SaveSession

local function decode(value,validate)
	if type(value) ~= "table" or(value.formatVersion~=1 and value.formatVersion~=2 and value.formatVersion~=3 and value.formatVersion~=4)then return nil,nil,"invalid save envelope"end
	local raw,reason=value.snapshot
	if value.formatVersion>=2 then
		raw,reason=Codec.Unpack(raw)
		if not raw then return nil,nil,reason end
	end
	local snapshot
	snapshot,reason=(validate or Snapshot.Validate)(raw)
	if not snapshot then return nil, nil, "invalid saved snapshot: " .. reason end
	local lease = value.lease
	if lease ~= nil and (type(lease) ~= "table" or type(lease.owner) ~= "string"
		or type(lease.expiresAt) ~= "number" or lease.expiresAt ~= lease.expiresAt
		or lease.expiresAt < 0 or lease.expiresAt > 1000000000000) then
		return nil, nil, "invalid lease"
	end
	return snapshot, lease
end

-- Read-only access for offline cooperative proofs uses the same envelope decoder.
function SaveSession.Read(record,validate)
	local snapshot,_,reason=decode(record,validate)
	return snapshot,reason
end

function SaveSession.Open(store, key, initial, options)
	local validate = options.validate or Snapshot.Validate
	local validated, reason = validate(initial)
	if not validated then return nil, reason end
	assert(type(options.owner) == "string" and #options.owner > 0, "session owner required")
	local now = options.now or os.time
	local ttl = options.ttl or 180
	assert(ttl >= 30 and ttl <= 600, "invalid lease duration")
	local denied
	local ok, result = pcall(function()
		return store:UpdateAsync(key, function(old)
			denied = nil
			local data, lease = validated, nil
			local legacyBackup = type(old)=="table" and old.legacy165Backup or nil
			local migrationBackups=type(old)=="table"and old.migrationBackups or nil
			if old ~= nil then
				local errorMessage
				local oldSize=type(old)=="table"and type(old.snapshot)=="table"and old.snapshot.initialCells
				if options.migrate and Geometry.Height(oldSize)and oldSize<validated.initialCells then
					-- Validate the envelope and lease before converting the old snapshot.
					local legacy
					legacy, lease, errorMessage = decode(old,function(raw) return raw end)
					if not legacy then denied = errorMessage return nil end
					if lease and lease.owner ~= options.owner and lease.expiresAt > now() then
						denied = "locked" return nil
					end
					data, errorMessage = options.migrate(legacy)
					if data then
						if oldSize==165 then legacyBackup=legacyBackup or old.snapshot end
						migrationBackups=type(migrationBackups)=="table"and table.clone(migrationBackups)or {}
						local id=tostring(oldSize)
						migrationBackups[id]=migrationBackups[id]or {formatVersion=old.formatVersion,snapshot=old.snapshot}
					end
				else
					data, lease, errorMessage = decode(old,validate)
				end
				if not data then denied = errorMessage return nil end
				data, errorMessage = validate(data)
				if not data then denied = errorMessage return nil end
			end
			if lease and lease.owner ~= options.owner and lease.expiresAt > now() then
				denied = "locked" return nil
			end
			return { formatVersion = Codec.Format(data,options.compact), snapshot = options.compact and Codec.Pack(data)or data, legacy165Backup = legacyBackup,migrationBackups=migrationBackups,
				lease = { owner = options.owner, expiresAt = now() + ttl } }
		end)
	end)
	if not ok then return nil, "datastore error: " .. tostring(result) end
	if not result then return nil, denied or "save acquisition cancelled" end
	local data, lease, decodeError = decode(result,validate)
	if not data or not lease or lease.owner ~= options.owner then return nil, decodeError or "lease acquisition failed" end
	return setmetatable({ store = store, key = key, owner = options.owner, now = now, ttl = ttl, validate = validate, transition = options.transition,
		snapshot = data, revision = data.revision, expiresAt = lease.expiresAt, compact=options.compact==true, closed = false }, SaveSession)
end

function SaveSession:Save(raw, release)
	if self.closed then return false, "session closed" end
	local data, reason = self.validate(raw)
	if not data then return false, reason end
	local expectedRevision = self.revision
	if data.revision ~= expectedRevision then return false, "local revision conflict" end
	data.revision = expectedRevision + 1
	local denied
	local ok, result = pcall(function()
		return self.store:UpdateAsync(self.key, function(old)
			denied = nil
			local previous, lease, decodeError = decode(old,self.validate)
			if not previous then denied = decodeError return nil end
			previous, decodeError = self.validate(previous)
			if not previous then denied = decodeError return nil end
			if not lease or lease.owner ~= self.owner then denied = "lease lost" return nil end
			if previous.revision ~= expectedRevision then denied = "revision conflict" return nil end
			if self.transition and not self.transition(previous,data)then denied="non-monotonic progress"return nil end
			return { formatVersion = Codec.Format(data,self.compact), snapshot = self.compact and Codec.Pack(data)or data, legacy165Backup = old.legacy165Backup,migrationBackups=old.migrationBackups,
				lease = not release and { owner = self.owner, expiresAt = self.now() + self.ttl } or nil }
		end)
	end)
	if not ok then return false, "datastore error: " .. tostring(result) end
	if not result then return false, denied or "save cancelled" end
	self.snapshot = data
	self.revision = data.revision
	self.expiresAt = not release and result.lease.expiresAt or 0
	self.closed = release == true
	return true
end

return SaveSession
