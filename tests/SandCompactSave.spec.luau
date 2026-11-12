return function(modules)
	local Codec,Session,Plot,Finds=modules.SandPrototypeSaveCodec,modules.SandPrototypeSaveSession,modules.SandPrototypePlotData,modules.SandPrototypeFindData
	local validate=Finds.Validator(1)
	local initial=assert(validate(Plot.Fresh()))
	local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
	local data=copy(initial)
	local hole=table.remove(data.cells,1)
	for _,c in data.cells do if c.x==0 and c.y==6 and c.z==0 then c.x=hole.x c.y=hole.y c.z=hole.z break end end
	data.dugCells=1 data.movedCells=1 data.account.CarriedCells=1 data.account.XP=1
	assert(validate(data),"test shape invalid")
	local packed=Codec.Pack(data)
	assert(not packed.cells and data.cells and #data.cells==454,"packing mutated live profile")
	local restored=assert(validate(assert(Codec.Unpack(packed))))
	local function same(a,b)
		assert(a.dugCells==b.dugCells and a.movedCells==b.movedCells and a.account.XP==b.account.XP and a.account.CarriedCells==b.account.CarriedCells)
		local keys={}
		for _,v in a.cells do keys[string.format("%d,%d,%d",v.x,v.y,v.z)]=true end
		for _,v in b.cells do local k=string.format("%d,%d,%d",v.x,v.y,v.z)assert(keys[k],"shape changed")keys[k]=nil end
		assert(next(keys)==nil,"sand disappeared")
	end
	same(data,restored)
	for _,key in {"-0,0,0","5000,0,0","0,-1,0","0,0,00","bad"}do
		local corrupt=copy(packed)corrupt.voxelChunks={[key]="0000000000000001"}
		assert(not Codec.Unpack(corrupt),"invalid address accepted")
	end
	local corrupt=copy(packed)corrupt.voxelChunks["0,0,0"]="not-bits"
	assert(not Codec.Unpack(corrupt),"invalid bits accepted")
	corrupt=copy(packed)corrupt.cells={}
	assert(not Codec.Unpack(corrupt),"ambiguous geometry accepted")
	local store={value={formatVersion=1,snapshot=copy(data),legacy165Backup={proof="untouched"}}}
	function store:UpdateAsync(_,callback)
		callback(copy(self.value))local nextValue=callback(copy(self.value))
		if nextValue then self.value=copy(nextValue)end
		if self.loseResponse then self.loseResponse=false error("injected response lost")end
		return copy(nextValue)
	end
	local now=100
	local function options(owner)return {owner=owner,compact=true,validate=validate,transition=Finds.Advances,now=function()return now end,ttl=30}end
	local session=assert(Session.Open(store,"qa",initial,options("first")))
	assert(store.value.formatVersion==2 and store.value.snapshot.cells==nil and store.value.legacy165Backup.proof=="untouched")
	same(data,session.snapshot)
	local blocked,reason=Session.Open(store,"qa",initial,options("second"))
	assert(not blocked and reason=="locked","compact lease bypassed")
	assert(session:Save(session.snapshot,true))
	for i=1,2 do session=assert(Session.Open(store,"qa",initial,options("reload"..i)))same(data,session.snapshot)assert(session:Save(session.snapshot,true))end
	session=assert(Session.Open(store,"qa",initial,options("lost-response")))
	local revision=session.revision store.loseResponse=true
	assert(not session:Save(session.snapshot,false)and session.revision==revision)
	local ok,conflict=session:Save(session.snapshot,false)
	assert(not ok and conflict=="revision conflict","lost response duplicated a write")
	now+=31
	session=assert(Session.Open(store,"qa",initial,options("recovery")))same(data,session.snapshot)assert(session:Save(session.snapshot,true))
	return {shapeCells=#restored.cells,oldFormatRead=true,reloads=2,lease=true,lostResponse=true,bytesOld=#game:GetService("HttpService"):JSONEncode(data),bytesPacked=#game:GetService("HttpService"):JSONEncode(packed)}
end
