--!strict
-- Rift Coins, purchases, equipped gear and consumables are ALL checked server-side.
-- Selling/buying is permitted only near its real merchant in Haven.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Progression=require(script.Parent.Progression)
local ItemConfig=require(ReplicatedStorage.Riftbound.Shared.ItemConfig)

local Economy={}
local started=false
local sessions=setmetatable({}, {__mode="k"})
local lastCall=setmetatable({}, {__mode="k"})

local function positionOf(localPoint)
	local generated=Workspace:FindFirstChild("RIFTBOUND World")
	if generated then
		return Vector3.new((generated:GetAttribute("SpawnX") or 0)+localPoint.X,
			(generated:GetAttribute("GroundY") or 0)+localPoint.Y,
			(generated:GetAttribute("SpawnZ") or 0)+localPoint.Z)
	end
	local spawn=Workspace:FindFirstChildWhichIsA("SpawnLocation",true)
	return (spawn and spawn.Position or Vector3.zero)+localPoint
end

local function nearMerchant(player,shopId)
	local station=ItemConfig.ShopLocations[shopId]
	if not station then return false end
	local character=player.Character
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health<=0 then return false end
	local target=positionOf(station)
	return (Vector2.new(root.Position.X,root.Position.Z)-Vector2.new(target.X,target.Z)).Magnitude<=21
end

local function ensureRemote(folder,name)
	local existing=folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing end
	if existing then warn("[RIFTBOUND Economy] Unexpected object:",name) return nil end
	local remote=Instance.new("RemoteEvent")
	remote.Name=name
	remote.Parent=folder
	return remote
end

local feedback

function Economy.OpenShop(player,shopId)
	if not ItemConfig.Shops[shopId] then return false,"Unknown merchant." end
	if not nearMerchant(player,shopId) then return false,"Approach the merchant first." end
	if player:GetAttribute("ProgressLoaded")~=true then return false,"Progress is still loading." end
	sessions[player]={id=shopId,expires=os.clock()+90}
	if feedback then feedback:FireClient(player,"OpenShop",shopId) end
	return true,"Welcome to "..ItemConfig.Shops[shopId].Name.."."
end

function Economy.Start()
	if started then return end
	local remotes=ReplicatedStorage:WaitForChild("Riftbound"):WaitForChild("Remotes")
	local request=ensureRemote(remotes,"EconomyRequest")
	feedback=ensureRemote(remotes,"EconomyFX")
	if not request or not feedback then return end
	started=true
	request.OnServerEvent:Connect(function(player,action,itemId)
		if typeof(action)~="string" or #action>24 then return end
		if itemId~=nil and (typeof(itemId)~="string" or #itemId>60) then return end
		local now=os.clock()
		if (lastCall[player] or 0)+0.18>now then return end
		lastCall[player]=now
		local good,msg
		if action=="Open" then
			good,msg=Economy.OpenShop(player,itemId)
			if not good then feedback:FireClient(player,"Message",false,msg) end
			return
		elseif action=="Buy" or action=="Sell" then
			local session=sessions[player]
			if not session or session.expires<now or not nearMerchant(player,session.id) then
				good,msg=false,"Visit a merchant in Haven to trade."
			elseif action=="Buy" then
				good,msg=Progression.BuyItem(player,itemId,session.id)
			else
				good,msg=Progression.SellItem(player,itemId)
			end
		elseif action=="Use" then
			good,msg=Progression.UseItem(player,itemId)
		elseif action=="Equip" then
			good,msg=Progression.EquipGear(player,itemId)
		else
			return
		end
		feedback:FireClient(player,"Message",good==true,msg or "Action unavailable.")
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastCall[player]=nil
		sessions[player]=nil
	end)
	print("[RIFTBOUND Economy] Apothecary, gear, inventory and consumables ready.")
end

return Economy
