--!strict
-- Art Deco mastery HUD: each successful ability earns XP for the equipped Spec.
-- Levels require increasing XP; Z/X/C/V/G have total-XP skill unlock gates.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Mastery=require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local Deco=require(script.Parent.ArtDecoUI)
local UI={}

function UI.Init(player,gui)
	local card=Instance.new("Frame")
	card.Name="RiftMasteryHUD"
	card.Position=UDim2.fromOffset(15,157)
	card.Size=UDim2.fromOffset(320,125)
	card.Parent=gui
	Deco.Panel(card)

	local title=Deco.Heading(Deco.Text(card,"MasteryTitle","SPEC MASTERY",
		UDim2.fromOffset(14,9),UDim2.new(1,-25,0,24),16,true))
	local progress=Deco.Text(card,"MasteryCount","MASTERY LV 0   •   0/10 XP",
		UDim2.fromOffset(14,34),UDim2.new(1,-26,0,20),13,false)
	local bar=Instance.new("Frame")
	bar.Name="MasteryXPTrack"
	bar.Size=UDim2.new(1,-28,0,9)
	bar.Position=UDim2.fromOffset(14,61)
	bar.ClipsDescendants=true
	bar.Parent=card
	local fill=Instance.new("Frame")
	fill.Name="MasteryXPFill"
	fill.Size=UDim2.fromScale(0,1)
	fill.Parent=bar
	Deco.Progress(bar,fill)

	local gates=Deco.Text(card,"SkillGates","Z:READY   X:10 XP   C:25 XP",
		UDim2.fromOffset(14,76),UDim2.new(1,-26,0,20),12,true)
	local extra=Deco.Text(card,"SkillGatesMore","V:40 XP   G:60 XP",
		UDim2.fromOffset(14,98),UDim2.new(1,-26,0,19),12,true)

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
		local total=math.clamp(player:GetAttribute("SpecMastery_"..spec) or 0,0,Mastery.MaxMasteryXP)
		local level,inLevel,required=Mastery.LevelDetails(total)
		title.Text=(spec=="AshleySimmons" and "ASHLEY SIMMONS" or "VOID DISCIPLE").."  /  MASTERY"
		progress.Text=level>=Mastery.MaxLevel
			and ("MASTERED  •  LEVEL "..level.." / "..Mastery.MaxLevel)
			or ("MASTERY LV "..level.."  •  "..inLevel.." / "..required.." XP")
		local ratio=required==0 and 1 or math.clamp(inLevel/required,0,1)
		TweenService:Create(fill,TweenInfo.new(0.25),{
			Size=UDim2.fromScale(ratio,1),
		}):Play()
		local function gate(key)
			local needed=Mastery.SkillRequirements[key]
			return key..":"..(total>=needed and "READY" or (needed.."XP"))
		end
		gates.Text=gate("Z").."    "..gate("X").."    "..gate("C")
		extra.Text=gate("V").."    "..gate("G").."    •  "..total.." TOTAL XP"
		gates.TextColor3=total>=25 and Deco.Green or Deco.PaleGold
		extra.TextColor3=total>=60 and Deco.Green or Deco.PaleGold
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
			toast(key.." LOCKED  •  "..tostring(owned).."/"..tostring(required).." MASTERY XP",Deco.Gold)
		end)
	end
	local progressFX=remotes:FindFirstChild("ProgressionFX")
	if progressFX then
		progressFX.OnClientEvent:Connect(function(action,spec,amount,total,level,leveledUp)
			if action~="MasteryGain" then return end
			if leveledUp then
				toast("SPEC MASTERY LEVEL "..level.."!",Deco.PaleGold)
				return
			end
			for _,key in Mastery.SkillOrder do
				local needed=Mastery.SkillRequirements[key]
				if needed>0 and total>=needed and total-amount<needed then
					toast(key.." SKILL UNLOCKED!",Deco.Green)
					return
				end
			end
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
