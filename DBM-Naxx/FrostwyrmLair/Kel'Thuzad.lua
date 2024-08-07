local mod	= DBM:NewMod("Kel'Thuzad", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

local select, tContains = select, tContains
local PickupInventoryItem, PutItemInBackpack, UseEquipmentSet, CancelUnitBuff = PickupInventoryItem, PutItemInBackpack, UseEquipmentSet, CancelUnitBuff
local UnitClass = UnitClass

mod:SetRevision("20221030130154")
mod:SetCreatureID(15990)
mod:SetModelID("creature/lich/lich.m2")
mod:SetMinCombatTime(60)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)

mod:RegisterCombat("combat_yell", L.Yell)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 27808 27819 28410",
	"SPELL_AURA_REMOVED 28410",
	"SPELL_CAST_SUCCESS 27810 27819 27808 28410",
	"SPELL_CAST_START 55802",
	"UNIT_HEALTH_UNFILTERED" -- have to do unfiltered because Zidras doesn't feel like fixing his stuff
)

local warnAddsSoon			= mod:NewAnnounce("warnAddsSoon", 1, "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01")
local warnPhase2			= mod:NewPhaseAnnounce(2, 3)
local warnBlastTargets		= mod:NewTargetAnnounce(27808, 2)
local warnFissure			= mod:NewTargetNoFilterAnnounce(27810, 4)
local warnMana				= mod:NewTargetAnnounce(27819, 2)
local warnChainsTargets		= mod:NewTargetNoFilterAnnounce(28410, 4)
local warnMindControlSoon	= mod:NewSoonAnnounce(28410, 4)

local specwarnP2Soon		= mod:NewSpecialWarning("specwarnP2Soon")
local specWarnManaBomb		= mod:NewSpecialWarningMoveAway(27819, nil, nil, nil, 1, 2)
local specWarnManaBombNear	= mod:NewSpecialWarningClose(27819, nil, nil, nil, 1, 2)
local yellManaBomb			= mod:NewShortYell(27819)
local specWarnBlast			= mod:NewSpecialWarningTarget(27808, "Healer", nil, nil, 1, 2)
local specWarnFissureYou	= mod:NewSpecialWarningYou(27810, nil, nil, nil, 3, 2)
local specWarnFissureClose	= mod:NewSpecialWarningClose(27810, nil, nil, nil, 2, 8)
local yellFissure			= mod:NewYellMe(27810)
local specWarnKickGroups	= mod:NewSpecialWarningInterrupt(55802, "HasInterrupt", "KickGroups", nil, 1, 2)

local blastTimer			= mod:NewBuffActiveTimer(4, 27808, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)
local timerManaBomb			= mod:NewCDTimer(20, 27819, nil, nil, nil, 3)
local timerFrostBlast		= mod:NewCDTimer(45, 27808, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerFissure			= mod:NewTargetTimer(5, 27810, nil, nil, 2, 3)
local timerFissureCD 		= mod:NewCDTimer(15, 27810, nil, nil, nil, 3) -- sometimes skips one?
local timerMC				= mod:NewBuffActiveTimer(20, 28410, nil, nil, nil, 3)
local timerMCCD				= mod:NewCDTimer(90, 28410, nil, nil, nil, 3)
local timerPhase2			= mod:NewTimer(228, "TimerPhase2", nil, nil, nil, 6)

specWarnKickGroups:SetText("Group %d")
DBM:GetModLocalization("Kel'Thuzad"):SetOptionLocalization({KickGroups="Voice announcement for $spell:55802 interrupt groups"})

mod:AddRangeFrameOption(12, 27819)
mod:AddSetIconOption("SetIconOnMC", 28410, true, false, {1, 2, 3})
mod:AddSetIconOption("SetIconOnManaBomb", 27819, false, false, {8})
mod:AddSetIconOption("SetIconOnFrostTomb", 27808, true, false, {1, 2, 3, 4, 5, 6, 7, 8})
mod:AddDropdownOption("RemoveBuffsOnMC", {"Never", "Gift", "CCFree", "ShortOffensiveProcs", "MostOffensiveBuffs"}, "Never", "misc", nil, 28410)

local RaidWarningFrame = RaidWarningFrame
local GetFramesRegisteredForEvent, RaidNotice_AddMessage = GetFramesRegisteredForEvent, RaidNotice_AddMessage
local function selfWarnMissingSet()
	if mod.Options.EqUneqWeaponsKT and not mod:IsEquipmentSetAvailable("pve") then
		for i = 1, select("#", GetFramesRegisteredForEvent("CHAT_MSG_RAID_WARNING")) do
			local frame = select(i, GetFramesRegisteredForEvent("CHAT_MSG_RAID_WARNING"))
			if frame.AddMessage then
				frame.AddMessage(frame, L.setMissing)
			end
		end
		RaidNotice_AddMessage(RaidWarningFrame, L.setMissing, ChatTypeInfo["RAID_WARNING"])
	end
end

mod:AddMiscLine(L.EqUneqLineDescription)
mod:AddBoolOption("EqUneqWeaponsKT", mod:IsDps(), nil, selfWarnMissingSet)
mod:AddBoolOption("EqUneqWeaponsKT2")

local function selfSchedWarnMissingSet(self)
	if self.Options.EqUneqWeaponsKT and not self:IsEquipmentSetAvailable("pve") then
		for i = 1, select("#", GetFramesRegisteredForEvent("CHAT_MSG_RAID_WARNING")) do
			local frame = select(i, GetFramesRegisteredForEvent("CHAT_MSG_RAID_WARNING"))
			if frame.AddMessage then
				self:Schedule(10, frame.AddMessage, frame, L.setMissing)
			end
		end
		self:Schedule(10, RaidNotice_AddMessage, RaidWarningFrame, L.setMissing, ChatTypeInfo["RAID_WARNING"])
	end
end
mod:Schedule(0.5, selfSchedWarnMissingSet, mod) -- mod options default values were being read before SV ones, so delay this

mod.vb.nextWarnAdds = 0.75
mod.vb.addPeriod = 0.25
mod.vb.MCIcon = 1
local frostBlastTargets = {}
local chainsTargets = {}
local isHunter = select(2, UnitClass("player")) == "HUNTER"
local playerClass = select(2, UnitClass("player"))
local nextGroup = 1

local function UnWKT(self)
	if (self.Options.EqUneqWeaponsKT or self.Options.EqUneqWeaponsKT2) and self:IsEquipmentSetAvailable("pve") then
		PickupInventoryItem(16)
		PutItemInBackpack()
		PickupInventoryItem(17)
		PutItemInBackpack()
		DBM:Debug("MH and OH unequipped",2)
		if isHunter then
			PickupInventoryItem(18)
			PutItemInBackpack()
			DBM:Debug("Ranged unequipped",2)
		end
	end
end

local function EqWKT(self)
	if (self.Options.EqUneqWeaponsKT or self.Options.EqUneqWeaponsKT2) and self:IsEquipmentSetAvailable("pve") then
		DBM:Debug("trying to equip pve",1)
		UseEquipmentSet("pve")
		CancelUnitBuff("player", (GetSpellInfo(25780))) -- Righteous Fury
	end
end

local aurastoRemove = { -- ordered by aggressiveness {degree, classFilter}
	-- 1 (Gift)
	[48469] = {1, nil}, -- Mark of the Wild
	[48470] = {1, nil}, -- Gift of the Wild
	[69381] = {1, nil}, -- Drums of the Wild
	-- 2 (CCFree)
	[48169] = {2, nil}, -- Shadow Protection
	[48170] = {2, nil}, -- Prayer of Shadow Protection
	-- 3 (ShortOffensiveProcs)
	[13877] = {3, "ROGUE"}, -- Blade Flurry (Combat Rogue)
	[70721] = {3, "DRUID"}, -- Omen of Doom (Balance Druid)
	[48393] = {3, "DRUID"}, -- Owlkin Frenzy (Balance Druid)
	[53201] = {3, "DRUID"}, -- Starfall (Balance Druid)
	[50213] = {3, "DRUID"}, -- Tiger's Fury (Feral Druid)
	[31572] = {3, "MAGE"}, -- Arcane Potency (Arcane Mage)
	[54490] = {3, "MAGE"}, -- Missile Barrage (Arcane Mage)
	[48108] = {3, "MAGE"}, -- Hot Streak (Fire Mage)
	[71165] = {3, "WARLOCK"}, -- Molten Core (Warlock)
	[63167] = {3, "WARLOCK"}, -- Decimation (Warlock)
	[70840] = {3, "WARLOCK"}, -- Devious Minds (Warlock)
	[17941] = {3, "WARLOCK"}, -- Shadow Trance (Warlock)
	[47197] = {3, "WARLOCK"}, -- Eradication (Affliction Warlock)
	[34939] = {3, "WARLOCK"}, -- Backlash (Destruction Warlock)
	[47260] = {3, "WARLOCK"}, -- Backdraft (Destruction Warlock)
	[16246] = {3, "SHAMAN"}, -- Clearcasting (Elemental Shaman)
	[64701] = {3, "SHAMAN"}, -- Elemental Mastery (Elemental Shaman)
	[26297] = {3, nil}, -- Berserking (Troll racial)
	[54758] = {3, nil}, -- Hyperspeed Acceleration (Hands engi enchant)
	[59626] = {3, nil}, -- Black Magic (Weapon enchant)
	[72416] = {3, nil}, -- Frostforged Sage (ICC Rep ring)
	[64713] = {3, nil}, -- Flame of the Heavens (Flare of the Heavens)
	[67669] = {3, nil}, -- Elusive Power (Trinket Abyssal Rune)
	[60064] = {3, nil}, -- Now is the Time! (Trinket Sundial of the Exiled/Mithril Pocketwatch)
	-- 4 (MostOffensiveBuffs)
	[48168] = {4, "PRIEST"}, -- Inner Fire (Priest)
	[15258] = {4, "PRIEST"}, -- Shadow Weaving (Shadow Priest)
	[48420] = {4, "DRUID"}, -- Master Shapeshifter (Druid)
	[24932] = {4, "DRUID"}, -- Leader of the Pack (Feral Druid)
	[67355] = {4, "DRUID"}, -- Agile (Feral Druid idol)
	[52610] = {4, "DRUID"}, -- Savage Roar (Feral Druid)
	[24907] = {4, "DRUID"}, -- Moonkin Aura (Balance Druid)
	[71199] = {4, "DRUID"}, -- Furious (Shaman EoF: Bizuri's Totem of Shattered Ice)
	[67360] = {4, "DRUID"}, -- Blessing of the Moon Goddess (Druid EoT: Idol of Lunar Fury)
	[48943] = {4, "PALADIN"}, -- Shadow Resistance Aura (Paladin)
	[43046] = {4, "MAGE"}, -- Molten Armor (Mage)
	[47893] = {4, "WARLOCK"}, -- Fel Armor (Warlock)
	[63321] = {4, "WARLOCK"}, -- Life Tap (Warlock)
	[55637] = {4, nil}, -- Lightweave (Back tailoring enchant)
	[71572] = {4, nil}, -- Cultivated Power (Muradin Spyglass)
	[60235] = {4, nil}, -- Greatness (Darkmoon Card: Greatness)
	[71644] = {4, nil}, -- Surge of Power (Dislodged Foreign Object)
	[75473] = {4, nil}, -- Twilight Flames (Charred Twilight Scale)
	[71636] = {4, nil}, -- Siphoned Power (Phylactery of the Nameless Lich)
}
local optionToDegree = {
	["Gift"] = 1, -- Cyclones resists
	["CCFree"] = 2, -- CC Shadow resists, life Fear from Psychic Scream
	["ShortOffensiveProcs"] = 3, -- Short-term procs that would expire during Mind Control anyway
	["MostOffensiveBuffs"] = 4, -- Most offensive buffs that are easily renewable but would expire after Mind Control ends
}

local function RemoveBuffs(option) -- Spell is removed based on name so no longer need SpellID for each rank
	if not option then return end
	local degreeOption = optionToDegree[option]
	for aura, infoTable in pairs(aurastoRemove) do
		local degree, classFilter = unpack(infoTable)
		if degree <= degreeOption then
			if not classFilter or classFilter == playerClass then
				CancelUnitBuff("player", (GetSpellInfo(aura)))
			end
		end
	end
	DBM:Debug("Buffs removed, using option \"" .. option .. "\" and degree: " .. tostring(degreeOption), 2)
end

local function AnnounceChainsTargets(self)
	warnChainsTargets:Show(table.concat(chainsTargets, "< >"))
	if (not tContains(chainsTargets, UnitName("player")) and self.Options.EqUneqWeaponsKT and self:IsDps()) then
		DBM:Debug("Equipping scheduled",2)
		self:Schedule(1.0, EqWKT, self)
		self:Schedule(2.0, EqWKT, self)
		self:Schedule(3.6, EqWKT, self)
		self:Schedule(5.0, EqWKT, self)
		self:Schedule(6.0, EqWKT, self)
		self:Schedule(8.0, EqWKT, self)
		self:Schedule(10.0, EqWKT, self)
		self:Schedule(12.0, EqWKT, self)
	end
	table.wipe(chainsTargets)
	self.vb.MCIcon = 1
end

local function AnnounceBlastTargets(self)
	if self.Options.SpecWarn27808target then
		specWarnBlast:Show(table.concat(frostBlastTargets, "< >"))
		specWarnBlast:Play("healall")
	else
		warnBlastTargets:Show(table.concat(frostBlastTargets, "< >"))
	end
	blastTimer:Start(3.5)
	if self.Options.SetIconOnFrostTomb then
		for i = #frostBlastTargets, 1, -1 do
			self:SetIcon(frostBlastTargets[i], 8 - i, 4.5)
			frostBlastTargets[i] = nil
		end
	end
end

local function StartPhase2(self)
	if self.vb.phase == 1 then
		self:SetStage(2)
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		timerFissureCD:Start(25)
		timerManaBomb:Start(20)
		timerFrostBlast:Start(45)
		if self:IsDifficulty("normal25") then
			timerMCCD:Start(50)
			warnMindControlSoon:Schedule(45)
			if self.Options.EqUneqWeaponsKT and self:IsDps() then
				self:Schedule(48, UnWKT, self)
				self:Schedule(48.5, UnWKT, self)
			end
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(12)
		end
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	table.wipe(chainsTargets)
	table.wipe(frostBlastTargets)
	if self:IsDifficulty("normal25") then
		self.vb.nextWarnAdds = 0.75
		self.vb.addPeriod = 0.25
	else
		self.vb.nextWarnAdds = 0.4
		self.vb.addPeriod = 0.4
	end
	self.vb.MCIcon = 1
	specwarnP2Soon:Schedule(218-delay)
	timerPhase2:Start()
	self:Schedule(228, StartPhase2, self)
	nextGroup = 1
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 27810 then
		timerFissure:Start(args.destName)
		timerFissureCD:Start()
		if args:IsPlayer() then
			specWarnFissureYou:Show()
			specWarnFissureYou:Play("targetyou")
			yellFissure:Yell()
		elseif self:CheckNearby(8, args.destName) then
			specWarnFissureClose:Show(args.destName)
			specWarnFissureClose:Play("watchfeet")
		else
			warnFissure:Show(args.destName)
			warnFissure:Play("watchstep")
		end
	elseif args.spellId == 28410 then
		DBM:Debug("MC on "..args.destName,2)
		if args.destName == UnitName("player") then
			if self.Options.RemoveBuffsOnMC ~= "Never" then
				RemoveBuffs(self.Options.RemoveBuffsOnMC)
			end
			if self.Options.EqUneqWeaponsKT2 then
				UnWKT(self)
				self:Schedule(0.05, UnWKT, self)
				DBM:Debug("Unequipping",2)
			end
		end
		if self:AntiSpam(2, 2) then
			timerMCCD:Start()
		end
	elseif spellId == 27819 then
		timerManaBomb:Start()
	elseif spellId == 27808 then
		timerFrostBlast:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 27808 then -- Frost Blast
		table.insert(frostBlastTargets, args.destName)
		self:Unschedule(AnnounceBlastTargets)
		self:Schedule(0.5, AnnounceBlastTargets, self)
	elseif spellId == 27819 then -- Detonate Mana
		if self.Options.SetIconOnManaBomb then
			self:SetIcon(args.destName, 8, 5.5)
		end
		if args:IsPlayer() then
			specWarnManaBomb:Show()
			specWarnManaBomb:Play("bombrun")
			yellManaBomb:Yell()
		elseif self:CheckNearby(12, args.destName) then
			specWarnManaBombNear:Show(args.destName)
			specWarnManaBombNear:Play("scatter")
		else
			warnMana:Show(args.destName)
		end
	elseif spellId == 28410 then -- Chains of Kel'Thuzad
		chainsTargets[#chainsTargets + 1] = args.destName
		if self:AntiSpam() then
			timerMC:Start()
			timerMCCD:Start()
			warnMindControlSoon:Schedule(85)
		end
		if self.Options.SetIconOnMC then
			self:SetIcon(args.destName, self.vb.MCIcon)
		end
		self.vb.MCIcon = self.vb.MCIcon + 1
		self:Unschedule(AnnounceChainsTargets)
		if #chainsTargets >= 3 then
			AnnounceChainsTargets(self)
		else
			self:Schedule(1.0, AnnounceChainsTargets, self)
		end
		if self.Options.EqUneqWeaponsKT and self:IsDps() then
			self:Schedule(88.0, UnWKT, self)
			self:Schedule(88.5, UnWKT, self)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 28410 then
		if self.Options.SetIconOnMC then
			self:SetIcon(args.destName, 0)
		end
		if (args.destName == UnitName("player") or args:IsPlayer()) and (self.Options.EqUneqWeaponsKT or self.Options.EqUneqWeaponsKT2) and self:IsDps() then
			DBM:Debug("Equipping scheduled",2)
			self:Schedule(0.1, EqWKT, self)
			self:Schedule(1.7, EqWKT, self)
			self:Schedule(3.7, EqWKT, self)
			self:Schedule(7.0, EqWKT, self)
			self:Schedule(9.0, EqWKT, self)
			self:Schedule(11.0, EqWKT, self)
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 55802 and self.Options.KickGroups then -- Frostbolt
		specWarnKickGroups:Play("count\\"..nextGroup)
		specWarnKickGroups:Show(nextGroup, "")
		nextGroup = nextGroup%2+1
	end
end

function mod:UNIT_HEALTH_UNFILTERED(uId)
	if uId == "boss1" and self.vb.nextWarnAdds > 0 and self:GetUnitCreatureId(uId) == 15990 and UnitHealth(uId) / UnitHealthMax(uId) <= self.vb.nextWarnAdds+0.02 then
		self.vb.nextWarnAdds = self.vb.nextWarnAdds - self.vb.addPeriod
		warnAddsSoon:Show()
	end
end
