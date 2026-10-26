--!strict
-- Art Deco NPC conversations; actual interactions come from trusted server prompts.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Actors=require(ReplicatedStorage.Riftbound.Shared.DialogueConfig)
local Quests=require(ReplicatedStorage.Riftbound.Shared.QuestConfig)
local Deco=require(script.Parent.ArtDecoUI)
local Dialogue={}

function Dialogue.Init(player,gui)
	local panel=Instance.new("Frame")
	panel.Name="RiftStoryDialogue"
	panel.Size=UDim2.new(0.92,0,0,274)
	panel.AnchorPoint=Vector2.new(0.5,1)
	panel.Position=UDim2.new(0.5,0,1,-27)
	panel.Visible=false
	panel.Parent=gui
	Deco.Panel(panel)
	local limit=Instance.new("UISizeConstraint")
	limit.MaxSize=Vector2.new(650,274)
	limit.MinSize=Vector2.new(305,274)
	limit.Parent=panel
	local name=Deco.Heading(Deco.Text(panel,"Actor","STORY CHARACTER",
		UDim2.fromOffset(22,11),UDim2.new(1,-100,0,29),21,true))
	local title=Deco.Text(panel,"Role","",UDim2.fromOffset(24,42),
		UDim2.new(1,-60,0,21),12,false)
	title.TextColor3=Deco.Muted
	local close=Deco.MakeButton(panel,"Exit","X",UDim2.new(1,-54,0,13),UDim2.fromOffset(33,32))
	close.Activated:Connect(function()panel.Visible=false end)
	local words=Deco.Text(panel,"Speech","",
		UDim2.fromOffset(22,77),UDim2.new(1,-44,0,93),18,false)
	words.TextYAlignment=Enum.TextYAlignment.Top
	local hint=Deco.Text(panel,"QuestHint","",
		UDim2.fromOffset(23,169),UDim2.new(1,-46,0,41),12,true)
	hint.TextColor3=Deco.Muted
	local nextButton=Deco.MakeButton(panel,"Next","NEXT",
		UDim2.new(0,20,1,-54),UDim2.new(0.33,-15,0,38))
	local actionButton=Deco.MakeButton(panel,"QuestAction","QUEST",
		UDim2.new(0.34,1,1,-54),UDim2.new(0.33,-15,0,38))
	local shopButton=Deco.MakeButton(panel,"Merchant","VISIT SHOP",
		UDim2.new(0.68,-3,1,-54),UDim2.new(0.32,-14,0,38))
	local npc,step=nil,1

	local function refresh()
		if not npc then return end
		local actor=Actors.Actors[npc]
		if not actor then return end
		name.Text=actor.Name
		name.TextColor3=actor.Color
		title.Text=actor.Role.."  /  "..actor.District
		words.Text=actor.Lines[step] or actor.Lines[#actor.Lines]
		nextButton.Text=step<#actor.Lines and "CONTINUE >" or "FINISH"
		hint.Text=actor.QuestHint or ""
		shopButton.Visible=actor.Shop~=nil
		actionButton.Visible=actor.QuestId~=nil
		if actor.QuestId then
			local q=Quests.Quests[actor.QuestId]
			local done=player:GetAttribute("QuestCompleted_"..actor.QuestId)==true
			local active=player:GetAttribute("QuestActiveId") or ""
			actionButton.Text=done and "COMPLETED"
				or active==actor.QuestId and "TRACKED"
				or ("ACCEPT QUEST")
			actionButton.Active=not done and active==""
		end
	end
	nextButton.Activated:Connect(function()
		if not npc then return end
		if step<#Actors.Actors[npc].Lines then
			step+=1
			refresh()
		else
			panel.Visible=false
		end
	end)
	actionButton.Activated:Connect(function()
		if not npc then return end
		local actor=Actors.Actors[npc]
		if not actor or not actor.QuestId then return end
		if (player:GetAttribute("QuestActiveId") or "")=="" then
			local r=ReplicatedStorage.Riftbound.Remotes:FindFirstChild("QuestRequest")
			if r then r:FireServer("Accept",actor.QuestId) end
		elseif gui:FindFirstChild("QuestJournal") then
			gui.QuestJournal.Visible=true
			panel.Visible=false
		end
		refresh()
	end)
	shopButton.Activated:Connect(function()
		if not npc then return end
		local actor=Actors.Actors[npc]
		if actor and actor.Shop then
			local remote=ReplicatedStorage.Riftbound.Remotes:FindFirstChild("EconomyRequest")
			if remote then
				remote:FireServer("Open",actor.Shop)
				panel.Visible=false
			end
		end
	end)
	local remote=ReplicatedStorage.Riftbound.Remotes:WaitForChild("DialogueFX",8)
	if not remote then warn("[RIFTBOUND Story] DialogueFX remote not found.") return end
	remote.OnClientEvent:Connect(function(action,id)
		if action~="Open" or typeof(id)~="string" or not Actors.Actors[id] then return end
		npc=id
		step=1
		panel.Visible=true
		refresh()
	end)
	player:GetAttributeChangedSignal("QuestActiveId"):Connect(function()
		if panel.Visible then refresh() end
	end)
end
return Dialogue
