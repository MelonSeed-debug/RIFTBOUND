--!strict
-- Story NPC dialogue is display-only. Server ProximityPrompts advance talk objectives.
return {
	Order = {"WardenVale","DrLiora","GildedBroker","Kestrel","ForemanBrass","OracleNyx"},
	Actors = {
		WardenVale = {
			Name="WARDEN VALE",Role="Keeper of Haven",District="Haven",
			Position=Vector3.new(-8,0,62),Color=Color3.fromRGB(220,194,119),
			Lines={
				"Welcome to Haven, traveler. The sky has been tearing open since the first Rift.",
				"If you plan to cross the causeways, earn some practice in the Old Quarter.",
				"The Archivist can assign your work. Dr. Liora tends the wounded. Speak to them both.",
			},
			QuestHint="Start THE FIRST SPARK in the Quest Journal and speak with Dr. Liora.",
			QuestId="FirstSpark",
		},
		DrLiora = {
			Name="DR. LIORA",Role="Apothecary of Haven",District="Haven",
			Position=Vector3.new(61,0,-2),Color=Color3.fromRGB(96,203,200),
			Lines={
				"Not every wound can be mended with power. Sometimes a bandage is enough.",
				"Rift Coins buy field bandages and tonics. They can save your expedition.",
				"The city is safe, but the bridges are not. Stock up before you leave.",
			},
			QuestHint="Completes THE FIRST SPARK when you have accepted it.",
			QuestId="FirstSpark",Shop="Apothecary",
		},
		GildedBroker = {
			Name="GILDED BROKER",Role="Gear merchant of Haven",District="Haven",
			Position=Vector3.new(-66,0,-6),Color=Color3.fromRGB(241,203,92),
			Lines={
				"A proper set of gear changes a fight before the first punch.",
				"Get your Iron Grips here. When you're experienced enough, the Gilded Crest is worth every Rift Coin.",
				"Scrap and Rift Shards? I can exchange those for currency as well.",
			},
			QuestHint="Equip gear from your inventory. Materials can be sold at the shop.",
			Shop="Gear",
		},
		Kestrel = {
			Name="KESTREL",Role="Old Quarter Informant",District="OldQuarter",
			Position=Vector3.new(-266,0,-179),Color=Color3.fromRGB(219,104,196),
			Lines={
				"Keep your voice down. The guards don't like questions.",
				"Someone in the Ironworks has been moving Rift fragments across the waterways.",
				"If you want answers, look for Foreman Brass near the foundry road.",
			},
			QuestHint="Completes SHADOWS ON THE MARKET when accepted.",
			QuestId="MarketWhispers",
		},
		ForemanBrass = {
			Name="FOREMAN BRASS",Role="Ironworks Foreman",District="Ironworks",
			Position=Vector3.new(185,0,-201),Color=Color3.fromRGB(235,156,77),
			Lines={
				"These furnaces run on more than coal. The Rift Sentinel is guarding a broken reactor.",
				"That beast answers to something beyond the Expanse.",
				"Don't venture into the Abyss Citadel without supplies or allies.",
			},
			QuestHint="Completes THE FOUNDRY SECRET when accepted.",
			QuestId="FoundrySecret",
		},
		OracleNyx = {
			Name="ORACLE NYX",Role="Rift Expanse Oracle",District="RiftExpanse",
			Position=Vector3.new(358,0,-358),Color=Color3.fromRGB(179,110,249),
			Lines={
				"The citadel remembers every traveler who enters.",
				"Beyond the gate walks the Abyss Warden, chained to the heart of this corruption.",
				"Claim its sigil, and return alive. The Rift has yet to show its true face.",
			},
			QuestHint="Completes VOICES OF THE VEIL when accepted.",
			QuestId="VeilVoices",
		},
	},
}
