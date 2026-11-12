return function(modules,height)
	local Finds,Plot,Session,Codec,Coop=modules.SandPrototypeFindData,modules.SandPrototypePlotData,modules.SandPrototypeSaveSession,modules.SandPrototypeSaveCodec,modules.SandPrototypeCoopData
	local fresh=Plot.Fresh(height)
	local validate=Finds.Validator(1,false,true,fresh.initialCells)
	local source=assert(validate(fresh))
	if source.cells then table.remove(source.cells,1)
	else
		local field=modules.SandPrototypeVoxelField.Create(source.voxelChunks)field.Set(0,0,0,false)source.voxelChunks=field.Export()
	end
	source.dugCells=1 source.outbound["2"]=1
	source=assert(validate(source))
	local legacy=assert(Session.Read({formatVersion=1,snapshot=source},validate))
	local format=Codec.Format(source,true)
	local compact=assert(Session.Read({formatVersion=format,snapshot=Codec.Pack(source)},validate))
	assert(legacy.outbound["2"]==1 and compact.outbound["2"]==1,"offline helper proof lost")
	local helper=assert(Finds.Validator(2)(Plot.Fresh()))
	helper.imports["1"]=0
	local delta=Coop.CreditDelta(helper.account,helper.imports["1"],compact.outbound["2"])
	assert(delta==1)
	helper.imports["1"]+=delta helper.account.CarriedCells+=delta helper.account.XP+=delta
	assert(Finds.Validator(2)(helper))
	assert(Coop.CreditDelta(helper.account,helper.imports["1"],legacy.outbound["2"])==0,"duplicate offline reward")
	assert(not Session.Read({formatVersion=99,snapshot=source},validate))
	assert(not Session.Read({formatVersion=format,snapshot=Codec.Pack(source),lease={owner=false,expiresAt=0}},validate))
	return {legacy=true,compact=true,format=format,credited=1,duplicateCredit=0,invalidEnvelopeRejected=true}
end
