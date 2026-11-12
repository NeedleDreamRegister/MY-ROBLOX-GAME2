-- Run with execute_luau in an isolated Studio Client (SessionOnly).
-- Synthetic LOCAL render geometry; does not touch game cells, remotes or saves.
assert(game:GetService("RunService"):IsStudio()and game:GetService("RunService"):IsClient(),"Studio Client only")
local player=game.Players.LocalPlayer
local mountain=require(game.ReplicatedStorage.SandPrototypeClientContext).GetMountain(player)
assert(mountain:GetAttribute("PersistenceStatus")=="SessionOnly","Disable persistence for render benchmark")
local mp=require("@rbx/LibMP")
assert(mp.Control:IsBackendReady(),"MicroProfiler backend unavailable")
local camera=workspace.CurrentCamera
local oldType,oldCFrame=camera.CameraType,camera.CFrame
local root=Instance.new("Folder")root.Name="__SandRenderBenchmark"root.Parent=workspace
local driver=Instance.new("LocalScript")driver.Name="__BenchmarkCamera"
driver.Source=[[
local c=workspace.CurrentCamera
local pose=CFrame.lookAt(Vector3.new(340,35,45),Vector3.new(300,10,0))
local connection=game:GetService("RunService").RenderStepped:Connect(function()c.CameraType=Enum.CameraType.Scriptable c.CFrame=pose end)
script.Destroying:Connect(function()connection:Disconnect()end)
]]
driver.Parent=player.PlayerGui
local results={}
local ok,reason=pcall(function()
	assert(mp.Control:EnableProfiler(true))
	mp.Control:SetFrameLimit(128)
	for _,radius in{4,6,10}do
		root:ClearAllChildren()
		local model=Instance.new("Model")model.Name="Radius_"..radius model.Parent=root
		local batch=Instance.new("Folder")batch.Name="Cells"
		local count,inBatch,maxChunk=0,0,0
		local buildStart,chunkStart=os.clock(),os.clock()
		for y=0,radius do
			local width=radius-y
			for x=-width,width do for z=-width,width do
				local p=Instance.new("Part")p.Name="SandCell"p.Size=Vector3.new(2,2,2)
				p.Position=Vector3.new(300+x*2,1+y*2,z*2)
				p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
				p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
				p.Color=Color3.fromRGB(209,184,120)p.Material=Enum.Material.Sand p.Parent=batch
				count+=1 inBatch+=1
				if inBatch>=200 then
					batch.Parent=model maxChunk=math.max(maxChunk,(os.clock()-chunkStart)*1000)
					task.wait()batch=Instance.new("Folder")batch.Name="Cells"inBatch=0 chunkStart=os.clock()
				end
			end end
		end
		if inBatch>0 then batch.Parent=model else batch:Destroy()end
		maxChunk=math.max(maxChunk,(os.clock()-chunkStart)*1000)
		local buildMs=(os.clock()-buildStart)*1000
		task.wait(0.5)
		assert((camera.CFrame.Position-Vector3.new(340,35,45)).Magnitude<0.01,"Benchmark camera did not lock")
		local centre,onScreen=camera:WorldToViewportPoint(Vector3.new(300,10,0))
		assert(onScreen and centre.Z>0,"Synthetic mountain outside view")
		mp.Control:EnableCapture(true)
		for _=1,132 do game:GetService("RunService").RenderStepped:Wait()end
		local bytes=mp.Control:CaptureToBufferSync()
		mp.Control:EnableCapture(false)
		local session=assert(mp.Session.OpenFromBuffer(bytes))
		local summaryOk,summary=pcall(function()
			local scale=session:FetchGlobalDesc().TickToMsCpu
			local first,last=session:GetFrameIdMin(),session:GetFrameIdMax()
			local values={}
			for id=first,last do
				local f=session:FetchFrameDesc(id)
				if not f.IsPaused and not f.IsIncomplete and f.TickEndCpu>f.TickStartCpu then table.insert(values,(f.TickEndCpu-f.TickStartCpu)*scale)end
			end
			assert(#values>=64,"Too few complete frames")table.sort(values)
			return{parts=count,radius=radius,frames=#values,medianCpuFrameMs=values[math.ceil(#values*0.5)],p95CpuFrameMs=values[math.ceil(#values*0.95)],
				maxCpuFrameMs=values[#values],buildWallMs=buildMs,maxBuildChunkMs=maxChunk,
				firstFrame=first,lastFrame=last,firstAbsoluteFrame=session:FetchFrameDesc(first).FrameAbsoluteId,lastAbsoluteFrame=session:FetchFrameDesc(last).FrameAbsoluteId}
		end)
		session:Dispose()
		assert(summaryOk,summary)table.insert(results,summary)
	end
end)
driver:Destroy()root:Destroy()
camera.CameraType=oldType camera.CFrame=oldCFrame
mp.Control:EnableCapture(false)
assert(ok,reason)
return{environment="Studio on this Windows PC; local render-only geometry; one client",viewport=tostring(camera.ViewportSize),results=results}
