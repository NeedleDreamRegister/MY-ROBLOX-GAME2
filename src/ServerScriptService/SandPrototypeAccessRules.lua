local Rules={}
function Rules.Allows(ownerId,actorId,mode,isFriend)
	if ownerId==actorId then return true end
	if mode=="Open"then return true end
	return mode=="Friends"and isFriend==true
end
return Rules
