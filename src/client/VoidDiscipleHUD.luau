--!strict
-- Void Disciple cooldowns live in a responsive center-top skill dock instead of
-- overlapping the red/blue/green combat bars at the bottom-left.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Deco=require(script.Parent.ArtDecoUI)
local cfg=require(ReplicatedStorage.Riftbound.Shared.VoidDiscipleSpec)
local masteryCfg=require(ReplicatedStorage.Riftbound.Shared.MasteryConfig)
local HUD={}

function HUD.Init(player,gui)
	local dock=Instance.new("Frame")
	dock.Name="VoidAbilityDock"
	dock.AnchorPoint=Vector2.new(0.5,0)
	dock.Position=UDim2.new(0.5,0,0,143)
	dock.Size=UDim2.fromOffset(566,77)
	dock.Visible=false
	dock.Parent=gui
	Deco.Panel(dock)

	local scale=Instance.new("UIScale")
	scale.Name="ResponsiveAbilityScale"
	scale.Parent=dock

	local rows={}
	local order={"Z","X","C","V","G"}
	for i,key in order do
		local ability=cfg.Abilities[key]
		local cell=Deco.Card(dock,"Void"..key.."Cell",
			UDim2.fromOffset(10+(i-1)*111,11),UDim2.fromOffset(105,45))
		local label=Deco.Text(cell,"Caption",key.."  "..string.upper(ability.Name),
			UDim2.fromOffset(5,3),UDim2.fromOffset(96,21),11,true)
		label.TextXAlignment=Enum.TextXAlignment.Center
		label.TextScaled=true
		local cooldown=Deco.Text(cell,"Cooldown","READY",
			UDim2.fromOffset(5,23),UDim2.fromOffset(96,17),11,true)
		cooldown.TextXAlignment=Enum.TextXAlignment.Center
		rows[key]={Title=label,State=cooldown}
	end
	local passive=Deco.Text(dock,"Passive","PASSIVE   •   VOID MARK: 3 HITS",
		UDim2.fromOffset(12,59),UDim2.new(1,-24,0,15),10,false)
	passive.TextXAlignment=Enum.TextXAlignment.Center

	task.spawn(function()
		while gui.Parent do
			local isVoid=player:GetAttribute("EquippedSpec")==cfg.Id
			dock.Visible=isVoid and dock:GetAttribute("RiftHideInCompact")~=true
			if isVoid then
				local now=workspace:GetServerTimeNow()
				local mastery=player:GetAttribute("SpecMastery_VoidDisciple") or 0
				for key,cell in rows do
					local needed=masteryCfg.SkillRequirements[key] or 0
					if mastery<needed then
						cell.State.Text="LOCKED  "..needed.." XP"
						cell.State.TextColor3=Deco.Red
					else
						local left=math.max(0,math.ceil((player:GetAttribute("Void"..key.."ReadyAt") or 0)-now))
						cell.State.Text=left>0 and (tostring(left).."s") or "READY"
						cell.State.TextColor3=left>0 and Deco.Muted or Deco.Green
					end
				end
			end
			task.wait(0.18)
		end
	end)
end

return HUD
