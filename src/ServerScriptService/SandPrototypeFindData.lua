-- One prototype collectible per mountain, tied to the durable mining counter.
local Coop=require(script.Parent.SandPrototypeCoopData)
local Geometry=require(game:GetService("ReplicatedStorage").SandPrototypeGeometry)
local Finds={Kind="PotteryShard"}
local function integer(v,lo,hi)return type(v)=="number"and v==v and v>=lo and v<=hi and v%1==0 end
local function validId(id,testIds)
	local n=type(id)=="string"and tonumber(id)
	return n and(integer(n,1,9007199254740991)or(testIds and integer(n,-8,-1)))and string.format("%.0f",n)==id
end
local function cellKey(x,y,z)return string.format("%d,%d,%d",x,y,z)end
local function seed(data)
	local selected=Geometry.Nearest(data,0,1,0)
	return selected and{kind=Finds.Kind,x=selected.x,y=selected.y,z=selected.z}or false
end
function Finds.Validator(userId,testIds,allowLegacy,expectedCells)
	local base=Coop.Validator(userId,testIds,allowLegacy,expectedCells)
	local owner=tostring(userId)
	return function(raw)
		if type(raw)~="table"then return nil,"invalid find snapshot"end
		local modern=raw.schemaVersion==3
		local compatible=table.clone(raw)
		if modern then compatible.schemaVersion=2 end
		local data,reason=base(compatible)
		if not data then return nil,reason end
		local artifact,collection
		if modern then artifact,collection=raw.artifact,raw.collection else artifact,collection=seed(data),{}end
		if modern and raw.artifact==nil then return nil,"missing artifact state"end
		if artifact~=false then
			if type(artifact)~="table"or artifact.kind~=Finds.Kind then return nil,"invalid artifact kind"end
			if artifact.finderId~=nil then
				local finder=artifact.finderId
				if not validId(finder,testIds)or data.dugCells<1 or not integer(artifact.counter,0,Geometry.MaxCells)then return nil,"invalid find proof"end
				if finder==owner then
					if artifact.counter~=0 then return nil,"invalid own find counter"end
				elseif artifact.counter<1 or artifact.counter>(data.outbound[finder]or 0)then return nil,"find exceeds helper contribution"end
				artifact={kind=Finds.Kind,finderId=finder,counter=artifact.counter}
			else
				local height=Geometry.Height(data.initialCells)
				if not integer(artifact.x,-height,height)or not integer(artifact.y,0,height)or not integer(artifact.z,-height,height)then return nil,"invalid hidden find position"end
				local exists=Geometry.Has(data,artifact.x,artifact.y,artifact.z)
				if not exists then return nil,"hidden find has no sand cell"end
				artifact={kind=Finds.Kind,x=artifact.x,y=artifact.y,z=artifact.z}
			end
		end
		if type(collection)~="table"then return nil,"missing collection"end
		local normalized,count={},0
		for sourceId,proof in collection do
			if not validId(sourceId,testIds)or type(proof)~="table"or proof.kind~=Finds.Kind or not integer(proof.counter,0,Geometry.MaxCells)then return nil,"invalid collected find"end
			if sourceId==owner then
				if not artifact or artifact.finderId~=owner or proof.counter~=0 then return nil,"own collection has no find proof"end
			elseif proof.counter<1 or proof.counter>(data.imports[sourceId]or 0)then return nil,"collection exceeds confirmed import"end
			normalized[sourceId]={kind=Finds.Kind,counter=proof.counter}count+=1
			if count>129 then return nil,"collection limit"end
		end
		if artifact and artifact.finderId==owner and normalized[owner]==nil then return nil,"own find missing from collection"end
		data.schemaVersion=3
		data.artifact=artifact
		data.collection=normalized
		local pending=raw.pendingCollapses or {}
		if type(pending)~="table"or #pending>data.initialCells then return nil,"invalid pending collapse list"end
		local retries,seen,budget,entries={},{},0,0
		for index,entry in pending do
			if not integer(index,1,#pending)or type(entry)~="table"then return nil,"invalid pending collapse entry"end
			local x,y,z=entry.x,entry.y,entry.z
			local height=Geometry.Height(data.initialCells)
			if not integer(y,0,height)or not integer(x,-(height-y),height-y)or not integer(z,-(height-y),height-y)
				or not integer(entry.budget,1,math.max(8,height))then return nil,"invalid pending collapse bounds/budget"end
			local key=cellKey(x,y,z)
			if seen[key]then return nil,"duplicate pending collapse"end
			seen[key]=true budget+=entry.budget entries+=1
			retries[index]={x=x,y=y,z=z,budget=entry.budget}
		end
		if entries~=#pending or budget+data.movedCells>data.dugCells*math.max(8,Geometry.Height(data.initialCells))then return nil,"pending collapse exceeds dig budget"end
		data.pendingCollapses=retries
		return data
	end
end
function Finds.Matches(artifact,x,y,z)
	return type(artifact)=="table"and not artifact.finderId and artifact.x==x and artifact.y==y and artifact.z==z
end
function Finds.Move(artifact,x,y,z,dx,dy,dz)
	if not Finds.Matches(artifact,x,y,z)then return artifact end
	return{kind=Finds.Kind,x=dx,y=dy,z=dz}
end
function Finds.CanClaim(proof,recipient,received)
	return type(proof)=="table"and proof.kind==Finds.Kind and proof.finderId==tostring(recipient)
		and integer(proof.counter,1,Geometry.MaxCells)and integer(received,0,Geometry.MaxCells)and received>=proof.counter
end
function Finds.Advances(previous,nextValue)
	if previous.schemaVersion~=3 or nextValue.schemaVersion~=3 then return false end
	local a,b=table.clone(previous),table.clone(nextValue)a.schemaVersion=2 b.schemaVersion=2
	if not Coop.Advances(a,b)then return false end
	for sourceId,proof in previous.collection do
		local nextProof=nextValue.collection[sourceId]
		if not nextProof or nextProof.kind~=proof.kind or nextProof.counter~=proof.counter then return false end
	end
	local artifact=previous.artifact
	if artifact and artifact.finderId then
		local nextArtifact=nextValue.artifact
		if not nextArtifact or nextArtifact.finderId~=artifact.finderId or nextArtifact.counter~=artifact.counter then return false end
	elseif artifact then
		if not nextValue.artifact then return false end
		if nextValue.artifact.finderId and nextValue.dugCells<=previous.dugCells then return false end
		if not nextValue.artifact.finderId and(artifact.x~=nextValue.artifact.x or artifact.y~=nextValue.artifact.y or artifact.z~=nextValue.artifact.z)
			and nextValue.dugCells<=previous.dugCells and nextValue.movedCells<=previous.movedCells then return false end
	elseif nextValue.artifact then return false end
	return true
end
return Finds
