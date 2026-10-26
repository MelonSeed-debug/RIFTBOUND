--!strict
-- RIFTBOUND inventory / shop balance, shared for displaying item descriptions.
-- The server owns all prices, quantities, purchases, effects and equipment.
return {
	MaxDistinctItems = 24,
	MaxStack = 99,
	Order = {"FieldBandage","RiftTonic","IronGrips","GildedCrest","EmberDraught","WardVial","ScrapMetal","RiftShard","AbyssSigil"},
	Items = {
		FieldBandage = {Name="Field Bandage", Description="Restores 45 health.", Kind="Consumable",
			Price=35, Restore=45, Shop="Apothecary", MinLevel=1, Color=Color3.fromRGB(137,218,178)},
		RiftTonic = {Name="Rift Tonic", Description="Restores 125 health.", Kind="Consumable",
			Price=100, Restore=125, Shop="Apothecary", MinLevel=5, Color=Color3.fromRGB(90,211,238)},
		EmberDraught = {Name="Ember Draught", Description="+15% dealt damage for 45 seconds.", Kind="Consumable",
			Price=160, Buff="Damage", BuffValue=1.15, Duration=45, Shop="Apothecary",
			MinLevel=10, Color=Color3.fromRGB(255,153,80)},
		WardVial = {Name="Ward Vial", Description="20% less incoming damage for 40 seconds.", Kind="Consumable",
			Price=135, Buff="Defense", BuffValue=0.8, Duration=40, Shop="Apothecary",
			MinLevel=8, Color=Color3.fromRGB(181,123,243)},
		IronGrips = {Name="Iron Grips", Description="Equip for +8% permanent damage while worn.", Kind="Gear",
			Price=260, Multiplier=1.08, Shop="Gear", MinLevel=5, Color=Color3.fromRGB(184,180,167)},
		GildedCrest = {Name="Gilded Crest", Description="Equip for +15% permanent damage while worn.", Kind="Gear",
			Price=850, Multiplier=1.15, Shop="Gear", MinLevel=20, Color=Color3.fromRGB(246,206,107)},
		ScrapMetal = {Name="Forged Scrap", Description="A trade good dropped by Ironworks enemies.", Kind="Material",
			SellValue=20, Color=Color3.fromRGB(169,167,165)},
		RiftShard = {Name="Rift Shard", Description="Rift-corrupted crafting material. Trade it for Rift Coins.", Kind="Material",
			SellValue=42, Color=Color3.fromRGB(175,106,251)},
		AbyssSigil = {Name="Abyss Sigil", Description="Proof of conquering the Abyss dungeon. Rare drop.", Kind="Material",
			SellValue=225, Color=Color3.fromRGB(252,113,209)},
	},
	Shops = {
		Apothecary = {Name="HAVEN APOTHECARY", Stock={"FieldBandage","RiftTonic","EmberDraught","WardVial"}},
		Gear = {Name="GILDED GEAR DEPOT", Stock={"IronGrips","GildedCrest"}},
	},
	Loot = {
		["Street Brawler"] = {{Item="FieldBandage",Chance=0.14}},
		["Street Guard"] = {{Item="FieldBandage",Chance=0.18}},
		["Scrap Enforcer"] = {{Item="ScrapMetal",Chance=0.42}},
		["Forge Marauder"] = {{Item="ScrapMetal",Chance=0.58},{Item="RiftShard",Chance=0.07}},
		["Rift Sentinel"] = {{Item="RiftShard",Chance=0.42}},
		["Rift Stalker"] = {{Item="RiftShard",Chance=0.48}},
		["Void Ravager"] = {{Item="RiftShard",Chance=0.72},{Item="AbyssSigil",Chance=0.14}},
		["Abyss Warden"] = {{Item="RiftShard",Chance=1,Amount=3},{Item="AbyssSigil",Chance=0.48}},
	},
}
