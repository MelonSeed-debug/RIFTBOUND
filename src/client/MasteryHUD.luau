--!strict
-- Persistent mastery progress, visible skill gates and dungeon telegraphs.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Mastery=require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local Deco=require(script.Parent.ArtDecoUI)
local UI={}

function UI.Init(player,gui)
	local card=Instance.new("Frame")
	card.Name="RiftMasteryHUD"
	card.Position=UDim2.fromOffset(15,165)
	card.Size=UDim2.fromOffset(310,93)
	card.Parent=gui
	Deco.Panel(card)
	local title=Deco.Heading(Deco.Text(card,"MasteryTitle","SPEC MASTERY",
		UDim2.fromOffset(14,9),UDim2.new(1,-25,0,25),16,true))
	local progress=Deco.Text(card,"MasteryCount","0 / 100",
		UDim2.fromOffset(14,35),UDim2.fromOffset(270,17),12,false)
	local bar=Instance.new("Frame")
	bar.Size=UDim2.fromOffset(281,7)
	bar.Position=UDim2.fromOffset(14,55)
	bar.Parent=card
	local fill=Instance.new("Frame")
	fill.Size=UDim2.fromScale(0,1)
	fill.Parent=bar
	Deco.Progress(bar,fill)
	local gates=Deco.Text(card,"SkillGates","C:3   V:10   G:25",
		UDim2.fromOffset(14,67),UDim2.new(1,-25,0,22),12,true)
	local warning=Deco.Text(gui,"CombatNotice","",
		UDim2.new(0.5,-190,0.73,0),UDim2.fromOffset(380,48),18,true)
	warning.TextXAlignment=Enum.TextXAlignment.Center
	warning.TextTransparency=1
	warning.TextStrokeTransparency=1
	local serial=0
	local function toast(message,tint)
		serial+=1
		local token=serial
		warning.Text=message
		warning.TextColor3=tint or Deco.PaleGold
		warning.TextTransparency=0
		warning.TextStrokeColor3=Color3.new(0,0,0)
		warning.TextStrokeTransparency=0.2
		task.delay(2.6,function()
			if token~=serial or not warning.Parent then return end
			TweenService:Create(warning,TweenInfo.new(0.3),{
				TextTransparency=1,TextStrokeTransparency=1,
			}):Play()
		end)
	end
	local function refresh()
		local spec=player:GetAttribute("EquippedSpec")
		local valid=spec=="AshleySimmons" or spec=="VoidDisciple"
		card.Visible=valid
		if not valid then return end
		local value=math.clamp(player:GetAttribute("SpecMastery_"..spec) or 0,0,Mastery.MaxMastery)
		title.Text=(spec=="AshleySimmons" and "ASHLEY SIMMONS" or "VOID DISCIPLE").." / MASTERY"
		progress.Text=tostring(value).." / "..Mastery.MaxMastery.." DEFEATS"
		TweenService:Create(fill,TweenInfo.new(0.25),{
			Size=UDim2.fromScale(value/Mastery.MaxMastery,1),
		}):Play()
		local function gate(key)
			local required=Mastery.SkillRequirements[key]
			return key..":"..(value>=required and "READY" or tostring(required))
		end
		gates.Text=gate("C").."    "..gate("V").."    "..gate("G")
		gates.TextColor3=value>=25 and Deco.Green or Deco.PaleGold
	end
	for _,id in {"AshleySimmons","VoidDisciple"} do
		player:GetAttributeChangedSignal("SpecMastery_"..id):Connect(refresh)
	end
	player:GetAttributeChangedSignal("EquippedSpec"):Connect(refresh)
	player:GetAttributeChangedSignal("LastLootSerial"):Connect(function()
		local drop=player:GetAttribute("LastLoot")
		if typeof(drop)=="string" then toast("LOOT  •  "..drop,Deco.PaleGold) end
	end)
	refresh()
	local remotes=ReplicatedStorage.Riftbound.Remotes
	local mastery=remotes:WaitForChild("MasteryFX",6)
	if mastery then
		mastery.OnClientEvent:Connect(function(key,required,owned)
			toast(key.." LOCKED — "..tostring(owned).."/"..tostring(required).." SPEC MASTERY",Deco.Gold)
		end)
	end
	local dungeon=remotes:WaitForChild("DungeonFX",6)
	if dungeon then
		dungeon.OnClientEvent:Connect(function(action,message)
			if action=="Warning" then
				toast(tostring(message),Deco.Red)
			elseif action=="Victory" then
				toast(tostring(message),Deco.PaleGold)
			else
				toast(tostring(message),Deco.Paper)
			end
		end)
	end
end
return UI
