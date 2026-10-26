--!strict
-- Art Deco inventory and secure merchant interface. Client never alters items
-- or coins; it submits an action and waits for validated replicated attributes.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local HttpService=game:GetService("HttpService")
local Items=require(ReplicatedStorage.Riftbound.Shared.ItemConfig)
local Deco=require(script.Parent.ArtDecoUI)
local InventoryUI={}

function InventoryUI.Init(player,gui)
	local remotes=ReplicatedStorage.Riftbound.Remotes
	local request=remotes:WaitForChild("EconomyRequest",6)
	if not request then warn("[RIFTBOUND Inventory] EconomyRequest is missing.") end

	local open=Deco.MakeButton(gui,"InventoryToggle","INVENTORY [I]",
		UDim2.new(1,-153,0,174),UDim2.fromOffset(140,36))
	open.TextSize=12
	local panel=Instance.new("Frame")
	panel.Name="DecoInventory"
	panel.AnchorPoint=Vector2.new(0.5,0.5)
	panel.Position=UDim2.fromScale(0.5,0.5)
	panel.Size=UDim2.new(0.96,0,0,515)
	panel.Visible=false
	panel.Parent=gui
	Deco.Panel(panel)
	local limit=Instance.new("UISizeConstraint")
	limit.MaxSize=Vector2.new(530,515)
	limit.MinSize=Vector2.new(320,515)
	limit.Parent=panel

	Deco.Heading(Deco.Text(panel,"Heading","RIFTBOUND  /  INVENTORY",
		UDim2.fromOffset(19,12),UDim2.new(1,-95,0,34),22,true))
	local close=Deco.MakeButton(panel,"Close","X",
		UDim2.new(1,-52,0,13),UDim2.fromOffset(34,30))
	close.Activated:Connect(function()panel.Visible=false end)

	local coins=Deco.Text(panel,"Coins","RIFT COINS  0",
		UDim2.fromOffset(20,51),UDim2.new(1,-40,0,22),14,true)
	local gear=Deco.Text(panel,"Gear","EQUIPPED GEAR: NONE",
		UDim2.fromOffset(20,75),UDim2.new(1,-40,0,21),12,false)
	local menu={}
	local modes={"Inventory","Buy","Sell"}
	for i,mode in modes do
		local b=Deco.MakeButton(panel,mode.."Tab",string.upper(mode),
			UDim2.new((i-1)/3,9,0,106),UDim2.new(1/3,-18,0,34))
		menu[mode]=b
	end
	local scroll=Instance.new("ScrollingFrame")
	scroll.Name="ItemList"
	scroll.Position=UDim2.fromOffset(19,151)
	scroll.Size=UDim2.new(1,-38,1,-236)
	scroll.BackgroundTransparency=1
	scroll.ScrollBarThickness=5
	scroll.ScrollBarImageColor3=Deco.Gold
	scroll.BorderSizePixel=0
	scroll.ScrollingDirection=Enum.ScrollingDirection.Y
	scroll.CanvasSize=UDim2.fromOffset(0,0)
	scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
	scroll.Parent=panel
	local layout=Instance.new("UIListLayout")
	layout.SortOrder=Enum.SortOrder.LayoutOrder
	layout.Padding=UDim.new(0,8)
	layout.Parent=scroll

	local info=Deco.Text(panel,"ShopNote","Visit merchants in Haven to buy or sell.",
		UDim2.new(0,20,1,-73),UDim2.new(1,-40,0,48),12,false)
	info.TextColor3=Deco.Muted

	local currentMode="Inventory"
	local currentShop=nil
	local function readBag()
		local packed=player:GetAttribute("RiftInventoryJSON")
		if typeof(packed)~="string" then return {} end
		local ok,result=pcall(HttpService.JSONDecode,HttpService,packed)
		return ok and typeof(result)=="table" and result or {}
	end
	local function send(action,itemId)
		if request then
			request:FireServer(action,itemId)
		else
			info.Text="Economy offline: check Rojo and default.project.json."
		end
	end
	local function addRow(itemId,index,bag)
		local def=Items.Items[itemId]
		if not def then return end
		local qty=bag[itemId] or 0
		local card=Deco.Card(scroll,"Item "..itemId,
			UDim2.fromOffset(0,0),UDim2.new(1,-8,0,88))
		card.LayoutOrder=index
		local icon=Instance.new("Frame")
		icon.Size=UDim2.fromOffset(38,38)
		icon.Position=UDim2.fromOffset(11,11)
		icon.BackgroundColor3=def.Color or Deco.Gold
		icon.BorderSizePixel=0
		icon.Parent=card
		local diamond=Instance.new("Frame")
		diamond.Size=UDim2.fromOffset(19,19)
		diamond.Position=UDim2.fromScale(0.5,0.5)
		diamond.AnchorPoint=Vector2.new(0.5,0.5)
		diamond.Rotation=45
		diamond.BackgroundColor3=Deco.Ink
		diamond.Parent=icon
		local name=Deco.Text(card,"ItemName",def.Name,
			UDim2.fromOffset(58,8),UDim2.new(1,-177,0,22),15,true)
		name.TextColor3=Deco.PaleGold
		local description=Deco.Text(card,"Details",def.Description,
			UDim2.fromOffset(58,32),UDim2.new(1,-174,0,47),11,false)
		description.TextColor3=Deco.Muted

		local caption,disabled,act=nil,false,nil
		if currentMode=="Buy" then
			caption=tostring(def.Price or 0).." COINS"
			act=function()send("Buy",itemId)end
			disabled=(player:GetAttribute("Level") or 1)<(def.MinLevel or 1)
				or (player:GetAttribute("RiftCoins") or 0)<(def.Price or 0)
		elseif currentMode=="Sell" then
			caption="SELL +"..tostring(def.SellValue or 0)
			act=function()send("Sell",itemId)end
		elseif def.Kind=="Consumable" then
			caption="USE  x"..tostring(qty)
			act=function()send("Use",itemId)end
		elseif def.Kind=="Gear" then
			local equipped=player:GetAttribute("EquippedGear")==itemId
			caption=equipped and "UNEQUIP" or "EQUIP"
			act=function()send("Equip",equipped and "" or itemId)end
		else
			caption="x"..tostring(qty)
			disabled=true
		end
		local b=Deco.MakeButton(card,"Action",caption,
			UDim2.new(1,-119,0,26),UDim2.fromOffset(109,36))
		b.TextSize=11
		b.Active=not disabled
		b.BackgroundTransparency=disabled and 0.65 or 0
		b.TextTransparency=disabled and 0.45 or 0
		if act and not disabled then b.Activated:Connect(act) end
	end

	local function render()
		for _,child in scroll:GetChildren() do
			if child:IsA("Frame") or child.Name=="EmptyRow" then child:Destroy() end
		end
		local bag=readBag()
		coins.Text="RIFT COINS  "..tostring(player:GetAttribute("RiftCoins") or 0)
		local equipped=player:GetAttribute("EquippedGear") or ""
		gear.Text="GEAR: "..(Items.Items[equipped] and Items.Items[equipped].Name or "NONE")
		for mode,b in menu do
			b.BackgroundColor3=mode==currentMode and Deco.Bronze or Deco.Slate
			b.Active=mode=="Inventory" or currentShop~=nil
			b.TextTransparency=b.Active and 0 or 0.56
		end
		local count=0
		for _,id in Items.Order do
			local def=Items.Items[id]
			local owns=(bag[id] or 0)>0
			local listed= currentMode=="Inventory" and owns
				or currentMode=="Buy" and def.Shop==currentShop
				or currentMode=="Sell" and owns and def.Kind=="Material"
			if listed then count+=1 addRow(id,count,bag) end
		end
		if count==0 then
			local empty=Deco.Text(scroll,"Empty","No items here yet.",
				UDim2.fromOffset(9,12),UDim2.new(1,-15,0,50),16,false)
			empty.Name="EmptyRow"
			-- Static label not cleared by frame cleanup next render.
			empty.LayoutOrder=0
			task.delay(0,function()
				if empty.Parent and count==0 then empty.Text="No items here yet." end
			end)
		end
	end
	local function selectMode(mode)
		if mode~="Inventory" and not currentShop then
			info.Text="Talk to Dr. Liora or the Gilded Broker in Haven."
			return
		end
		currentMode=mode
		render()
	end
	for mode,b in menu do
		b.Activated:Connect(function()selectMode(mode)end)
	end
	local function toggle()
		if not panel.Visible then currentMode="Inventory" end
		panel.Visible=not panel.Visible
		if panel.Visible then render() end
	end
	open.Activated:Connect(toggle)
	ContextActionService:BindAction("RiftInventoryOpen",function(_,state)
		if state==Enum.UserInputState.Begin then toggle() end
		return Enum.ContextActionResult.Pass
	end,false,Enum.KeyCode.I)
	for _,attribute in {"RiftInventoryJSON","RiftCoins","EquippedGear","Level"} do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if panel.Visible then render() end
		end)
	end
	local function feedback(remote)
		remote.OnClientEvent:Connect(function(action,a,b)
			if action=="OpenShop" then
				currentShop=a
				currentMode="Buy"
				panel.Visible=true
				info.Text=Items.Shops[a] and
					("WELCOME TO "..Items.Shops[a].Name.."  •  SHOPPING REQUIRES PROXIMITY.")
					or "Merchant ready."
				render()
			elseif action=="Message" then
				info.Text=tostring(b)
				info.TextColor3=a and Deco.Green or Deco.Red
				if panel.Visible then render() end
			end
		end)
	end
	local fx=remotes:FindFirstChild("EconomyFX")
	if fx and fx:IsA("RemoteEvent") then feedback(fx)
	else
		remotes.ChildAdded:Connect(function(inst)
			if inst.Name=="EconomyFX" and inst:IsA("RemoteEvent") then feedback(inst) end
		end)
	end
end
return InventoryUI
