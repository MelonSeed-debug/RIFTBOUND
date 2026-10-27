--!strict
-- RIFTBOUND progression tuning. Levels start at 1 and STOP at 50.
-- XP is progress toward the next level (not lifetime XP).
local LevelConfig = {}

LevelConfig.MaxLevel = 50
LevelConfig.StartLevel = 1
LevelConfig.CurrencyName = "Rift Coins"
LevelConfig.Rewards = {
	-- Curated four-region overworld encounters. Rewards are modest:
	-- exploration/ability mastery, not repetitive enemy farming, drive play.
	["Rootbound Scout"] = {XP = 40, Coins = 9},
	["Thornback Guardian"] = {XP = 75, Coins = 16},
	["Cinder Strider"] = {XP = 120, Coins = 24},
	["Ashforged Bulwark"] = {XP = 195, Coins = 37},
	["Stonewatch Sentinel"] = {XP = 240, Coins = 51},
	["Gale Hunter"] = {XP = 290, Coins = 59},
	["Riftstalker"] = {XP = 395, Coins = 75},
	["Voidbound Knight"] = {XP = 580, Coins = 110},
	["Street Brawler"] = {XP = 80, Coins = 18},
	["Street Guard"] = {XP = 115, Coins = 28},
	["Scrap Enforcer"] = {XP = 180, Coins = 48},
	["Forge Marauder"] = {XP = 235, Coins = 65},
	["Rift Sentinel"] = {XP = 310, Coins = 90},
	["Rift Stalker"] = {XP = 450, Coins = 130},
	["Void Ravager"] = {XP = 740, Coins = 215},
	["Abyss Warden"] = {XP = 1600, Coins = 520},
}

function LevelConfig.XPToNext(level)
	if level >= LevelConfig.MaxLevel then return 0 end
	local tier = math.max(0, level - 1)
	return math.floor(75 + 30 * tier + 1.5 * tier * tier)
end

return LevelConfig
