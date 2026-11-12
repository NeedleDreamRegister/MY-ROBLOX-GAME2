return function(m,adopt)
 local Plot,Finds,Codec,Field=m.SandPrototypePlotData,m.SandPrototypeFindData,m.SandPrototypeSaveCodec,m.SandPrototypeVoxelField
 local function copy(v)if type(v)~="table"then return v end local r={}for k,c in v do r[k]=copy(c)end return r end
 Plot.Fresh(12)
 local original=assert(Finds.Validator(1)(Plot.Fresh()))
 for _=1,10 do table.remove(original.cells,1)end
 original.dugCells=10 original.account.CarriedCells=10 original.account.XP=10
 original=assert(Finds.Validator(1)(original))
 local baseline={formatVersion=2,snapshot=Codec.Pack(original)}
 local candidate=assert(Plot.Grow(1,original,2925))
 local field=Field.Create(candidate.voxelChunks)
 assert(field.Set(0,12,0,false)and field.Set(0,11,0,false))
 candidate.voxelChunks=field.Export()candidate.dugCells+=2 candidate.account.CarriedCells+=2 candidate.account.XP+=2
 candidate=assert(Finds.Validator(1,false,false,2925)(candidate))
 local final={formatVersion=3,snapshot=Codec.Pack(candidate)}
 local function store(record,lost)
  local s={record=copy(record),writes=0,lost=lost}
  function s:UpdateAsync(_,callback)
   callback(copy(self.record))local v=callback(copy(self.record))
   if v then self.record=copy(v)self.writes+=1
    if self.lost then self.lost=false error("lost write response")end
   end
   return copy(v)
  end
  return s
 end
 local opts={owner="qa-adoption",now=function()return 100 end}
 local s=store(baseline)
 assert(adopt(m,s,"qa",1,baseline,final,opts))
 assert(s.record.snapshot.dugCells==12 and s.record.snapshot.account.XP==12 and not s.record.lease)
 assert(s.record.migrationBackups["455"].snapshot.dugCells==10)
 local again=assert(adopt(m,s,"qa",1,baseline,final,opts))
 assert(again.mode=="already-current"and s.record.snapshot.dugCells==12,"duplicate import minted rewards")
 local changed=copy(original)changed.account.Coins=1 changed.account.CarriedCells=9
 local c=store({formatVersion=2,snapshot=Codec.Pack(changed)})
 local no,why=adopt(m,c,"qa",1,baseline,final,opts)
 assert(not no and why=="source progress changed"and c.writes==0,"newer source overwritten")
 local locked=copy(baseline)locked.lease={owner="other",expiresAt=200}c=store(locked)
 no,why=adopt(m,c,"qa",1,baseline,final,opts)
 assert(not no and why=="locked"and c.writes==0,"active lease stolen")
 c=store(nil)no,why=adopt(m,c,"qa",1,baseline,final,opts)
 assert(not no and why=="source missing"and c.writes==0,"missing source seeded")
 c=store(baseline,true)no,why=adopt(m,c,"qa",1,baseline,final,opts)
 assert(not no and c.record.snapshot.dugCells==12,"lost response did not retain imported data")
 assert(adopt(m,c,"qa",1,baseline,final,opts))
 assert(c.record.snapshot.dugCells==12 and not c.record.lease,"retry duplicated progress or lost lease")
 return {importedDigs=12,idempotent=true,newerSourceProtected=true,leaseProtected=true,missingSourceRejected=true,lostResponseRecovered=true}
end
