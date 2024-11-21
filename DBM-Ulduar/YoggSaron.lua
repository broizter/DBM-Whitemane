local mod	= DBM:NewMod("YoggSaron", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4338 $"):sub(12, -3))
mod:SetCreatureID(33288)
mod:RegisterCombat("yell", L.YellPull)
mod:SetUsedIcons(8, 7, 6, 5, 4, 2, 1)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 64059 64189 63138 63830 63881",
	"SPELL_CAST_SUCCESS 64144 64465 64167 64163",
	"SPELL_SUMMON 62979",
	"SPELL_AURA_APPLIED 63802 63830 63881 64126 64125 63138 63894 64167 64163 64465",
	"SPELL_AURA_REMOVED 63802 63894 64167 64163 63830 63138 63881 64465",
	"SPELL_AURA_REMOVED_DOSE 63050",
	"UNIT_HEALTH"
)

local warnMadness 					= mod:NewCastAnnounce(64059, 2)
local warnSqueeze					= mod:NewTargetAnnounce(64125, 3)
local warnFervor					= mod:NewTargetAnnounce(63138, 4)
local warnDeafeningRoarSoon			= mod:NewPreWarnAnnounce(64189, 5, 3)
local warnGuardianSpawned 			= mod:NewAnnounce("WarningGuardianSpawned", 3, 62979)
local warnCrusherTentacleSpawned	= mod:NewAnnounce("WarningCrusherTentacleSpawned", 2, "Interface\\Icons\\achievement_boss_yoggsaron_01")
local warnP2 						= mod:NewPhaseAnnounce(2, 2)
local warnP3 						= mod:NewPhaseAnnounce(3, 2)
local warnSanity 					= mod:NewAnnounce("WarningSanity", 3, 63050)
local warnBrainLink 				= mod:NewTargetAnnounce(63802, 3)
local warnBrainPortalSoon			= mod:NewAnnounce("WarnBrainPortalSoon", 2, 57687)
local warnEmpowerSoon				= mod:NewSoonAnnounce(64486, 4)

local specWarnGuardianLow 			= mod:NewSpecialWarning("SpecWarnGuardianLow", false)
local specWarnBrainLink 			= mod:NewSpecialWarningYou(63802, nil, nil, nil, 1, 2)
local specWarnSanity 				= mod:NewSpecialWarning("SpecWarnSanity")
local specWarnMadnessOutNow			= mod:NewSpecialWarning("SpecWarnMadnessOutNow")
local specWarnBrainPortalSoon		= mod:NewSpecialWarning("SpecWarnBrainPortalSoon", false)
local specWarnDeafeningRoar			= mod:NewSpecialWarningSpell(64189, nil, nil, nil, 1, 2)
local specWarnFervor				= mod:NewSpecialWarningYou(63138, nil, nil, nil, 1, 2)
local specWarnMalady				= mod:NewSpecialWarningYou(63830, nil, nil, nil, 1, 2)
local specWarnMaladyNear			= mod:NewSpecialWarningClose(63830, nil, nil, nil, 1, 2)
local yellSqueeze					= mod:NewYell(64125)

local enrageTimer					= mod:NewBerserkTimer(900)
local timerFervor					= mod:NewTargetTimer(15, 63138, nil, false, 2)
local timerMaladyCD					= mod:NewCDTimer(20, 63830, nil, nil, nil, 3)
local timerBrainLinkCD				= mod:NewCDTimer(32, 63802, nil, nil, nil, 3)
local timerBrainPortal				= mod:NewTimer(22, "NextPortal", 57687, nil, nil, 5)
local timerLunaricGaze				= mod:NewCastTimer(4, 64163, nil, nil, nil, 2)
local timerNextLunaricGaze			= mod:NewCDTimer(8, 64163, nil, nil, nil, 2)
local timerEmpower					= mod:NewCDTimer(45, 64486, nil, nil, nil, 3)
local timerMadness 					= mod:NewCastTimer(60, 64059, nil, nil, nil, 5, nil, DBM_CORE_L.DEADLY_ICON, nil, 3)
local timerCastDeafeningRoar		= mod:NewCastTimer(2.3, 64189, nil, nil, nil, 2)
local timerNextDeafeningRoar		= mod:NewNextTimer(50, 64189, nil, nil, nil, 2)
local timerAchieve					= mod:NewAchievementTimer(420, 3012)

mod:AddBoolOption("ShowSaraHealth", false)
mod:AddBoolOption("MaladyArrow")
mod:AddSetIconOption("SetIconOnFearTarget", 63802, true, false, {6})
mod:AddSetIconOption("SetIconOnFervorTarget", 63802, false, false, {7})
mod:AddSetIconOption("SetIconOnBrainLinkTarget", 63802, true, false, {1, 2})
mod:AddSetIconOption("SetIconOnBeacon", 64465, true, true, {4, 5, 6, 7, 8})
mod:AddInfoFrameOption(63050)

local targetWarningsShown = {}
local brainLinkTargets = {}
local SanityBuff = DBM:GetSpellInfoNew(63050)
mod.vb.brainLinkIcon = 2
mod.vb.beaconIcon = 8
mod.vb.Guardians = 0

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.brainLinkIcon = 2
	self.vb.beaconIcon = 8
	self.vb.Guardians = 0
	enrageTimer:Start()
	timerAchieve:Start()
	table.wipe(targetWarningsShown)
	table.wipe(brainLinkTargets)
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(SanityBuff)
		DBM.InfoFrame:Show(30, "playerdebuffstacks", SanityBuff, 2)--Sorted lowest first (highest first is default of arg not given)
	end
	if self.Options.ShowSaraHealth then
		if not self.Options.HealthFrame then
			DBM.BossHealth:Show(L.name)
		else
			DBM.BossHealth:AddBoss(33134, L.Sara)
		end
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:FervorTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") and self:AntiSpam(4, 1) then
		specWarnFervor:Show()
		specWarnFervor:Play("targetyou")
	end
end

local function warnBrainLinkWarning(self)
	warnBrainLink:Show(table.concat(brainLinkTargets, "<, >"))
	timerBrainLinkCD:Start()--VERIFY ME
	table.wipe(brainLinkTargets)
	self.vb.brainLinkIcon = 2
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 64059 then	-- Induce Madness
		timerMadness:Start()
		warnMadness:Show()
		timerBrainPortal:Start(82)
		warnBrainPortalSoon:Schedule(72)
		specWarnBrainPortalSoon:Schedule(79)
		specWarnMadnessOutNow:Schedule(55)
	elseif spellId == 64189 then		--Deafening Roar
		timerNextDeafeningRoar:Start()
		warnDeafeningRoarSoon:Schedule(55)
		timerCastDeafeningRoar:Start()
		specWarnDeafeningRoar:Show()
		specWarnDeafeningRoar:Play("silencesoon")
	elseif spellId == 63138 then		--Sara's Fervor
		self:BossTargetScanner(args.sourceGUID, "FervorTarget", 0.1, 12, true, nil, nil, nil, true)
	elseif args:IsSpellID(63830, 63881) then
		timerMaladyCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 64144 and self:GetUnitCreatureId(args.sourceGUID) == 33966 then
		warnCrusherTentacleSpawned:Show()
	elseif spellId == 64465 then -- Shadow Beacon
		timerEmpower:Start()
		warnEmpowerSoon:Schedule(40)
	elseif args:IsSpellID(64167, 64163) and self:AntiSpam(3, 3) then	-- Lunatic Gaze
		timerLunaricGaze:Start()
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 62979 then
		self.vb.Guardians = self.vb.Guardians + 1
		warnGuardianSpawned:Show(self.vb.Guardians)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 63802 then		-- Brain Link
		self:Unschedule(warnBrainLinkWarning)
		brainLinkTargets[#brainLinkTargets + 1] = args.destName
		if self.Options.SetIconOnBrainLinkTarget then
			self:SetIcon(args.destName, self.vb.brainLinkIcon)
		end
		self.vb.brainLinkIcon = self.vb.brainLinkIcon - 1
		if args:IsPlayer() then
			specWarnBrainLink:Show()
			specWarnBrainLink:Play("linegather")
		end
		if #brainLinkTargets == 2 then
			warnBrainLinkWarning(self)
		else
			self:Schedule(0.5, warnBrainLinkWarning, self)
		end
	elseif args:IsSpellID(63830, 63881) then   -- Malady of the Mind (Death Coil)
		--timerMaladyCD:Start()
		if self.Options.SetIconOnFearTarget then
			self:SetIcon(args.destName, 6, 30)
		end
		if args:IsPlayer() then
			specWarnMalady:Show()
			specWarnMalady:Play("targetyou")
		else
			local uId = DBM:GetRaidUnitId(args.destName)
			if uId then
				local inRange = CheckInteractDistance(uId, 2)
				if inRange then
					specWarnMaladyNear:Show(args.destName)
					specWarnMaladyNear:Play("runaway")
					if self.Options.MaladyArrow then
						local x, y = GetPlayerMapPosition(uId)
						if x == 0 and y == 0 then
							SetMapToCurrentZone()
							x, y = GetPlayerMapPosition(uId)
						end
						DBM.Arrow:ShowRunAway(x, y, 12, 5)
					end
				end
			end
		end
	elseif args:IsSpellID(64126, 64125) then	-- Squeeze
		warnSqueeze:Show(args.destName)
		if args:IsPlayer() then
			yellSqueeze:Yell()
		end
	elseif spellId == 63138 then	-- Sara's Fervor
		warnFervor:Show(args.destName)
		timerFervor:Start(args.destName)
		if self.Options.SetIconOnFervorTarget then
			self:SetIcon(args.destName, 7, 15)
		end
		if args:IsPlayer() and self:AntiSpam(4, 1) then
			specWarnFervor:Show()
			specWarnFervor:Play("targetyou")
		end
	elseif spellId == 63894 and self.vb.phase < 2 then	-- Shadowy Barrier of Yogg-Saron (this is happens when p2 starts)
		self:SetStage(2)
		timerMaladyCD:Start(8)--VERIFY ME
		timerBrainLinkCD:Start(3)--VERIFY ME
		timerBrainPortal:Start(61)
		warnBrainPortalSoon:Schedule(51)
		specWarnBrainPortalSoon:Schedule(58)
		warnP2:Show()
		if self.Options.ShowSaraHealth then
			DBM.BossHealth:RemoveBoss(33134)
			if not self.Options.HealthFrame then
				DBM.BossHealth:Hide()
			end
		end
	elseif args:IsSpellID(64167, 64163) then	-- Lunatic Gaze (reduces sanity)
		timerLunaricGaze:Start()
	elseif spellId == 64465 then -- Shadow Beacon
		if self.Options.SetIconOnBeacon then
			self:ScanForMobs(args.destGUID, 2, self.vb.beaconIcon, 1, nil, 6, "SetIconOnBeacon", true, nil, nil, true)
		end
		self.vb.beaconIcon = self.vb.beaconIcon - 1
		if self:IsHeroic() then
			if self.vb.beaconIcon == 3 then
				self.vb.beaconIcon = 8
			end
		else
			if self.vb.beaconIcon == 5 then
				self.vb.beaconIcon = 8
			end
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 63802 and self.Options.SetIconOnBrainLinkTarget then		-- Brain Link
		self:SetIcon(args.destName, 0)
	elseif spellId == 63138 and self.Options.SetIconOnFervorTarget then	-- Sara's Fervor
		self:SetIcon(args.destName, 0)
	elseif spellId == 63894 then		-- Shadowy Barrier removed from Yogg-Saron (start p3)
		self:SendSync("Phase3")			-- Sync this because you don't get it in your combat log if you are in brain room.
	elseif args:IsSpellID(64167, 64163) and self:AntiSpam(3, 2) then	-- Lunatic Gaze
		timerNextLunaricGaze:Start()
	elseif args:IsSpellID(63830, 63881) and self.Options.SetIconOnFearTarget then   -- Malady of the Mind (Death Coil)
		self:SetIcon(args.destName, 0)
	elseif spellId == 64465 then -- Shadow Beacon
		if self.Options.SetIconOnBeacon then
			self:ScanForMobs(args.destGUID, 2, 0, 1, nil, 6, "SetIconOnBeacon", true, nil, nil, true)
		end
	end
end

function mod:SPELL_AURA_REMOVED_DOSE(args)
	if args.spellId == 63050 and args.destGUID == UnitGUID("player") then
		local amount = args.amount or 1
		if amount == 50 then
			warnSanity:Show(args.amount)
		elseif amount == 35 or amount == 25 or amount == 15 then
			specWarnSanity:Show(amount)
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if self.vb.phase == 1 and uId == "target" and self:GetUnitCreatureId(uId) == 33136 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.3 and not targetWarningsShown[UnitGUID(uId)] then
		targetWarningsShown[UnitGUID(uId)] = true
		specWarnGuardianLow:Show()
	end
end

function mod:OnSync(msg)
	if msg == "Phase3" then
		self:SetStage(3)
		timerBrainPortal:Stop()
		warnBrainPortalSoon:Cancel()
		specWarnBrainPortalSoon:Cancel()
		specWarnMadnessOutNow:Cancel()
		timerMaladyCD:Stop()
		timerBrainLinkCD:Stop()
		timerMadness:Stop()
		timerEmpower:Start(52.5)
		warnP3:Show()
		warnEmpowerSoon:Schedule(47.5)
		if self:IsDifficulty("normal25", "heroic25") then
			timerNextDeafeningRoar:Start(50)
			warnDeafeningRoarSoon:Schedule(25)
		end
	end
end