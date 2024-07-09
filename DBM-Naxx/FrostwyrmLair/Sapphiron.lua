local mod	= DBM:NewMod("Sapphiron", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

local ml = DBM:GetModLocalization("Sapphiron")
ml:SetOptionLocalization({SpecWarnRaidCD="Show warning and timer when $spell:64205 and $spell:31821 should be used in air phase (|cfff58cbaPaladin|r only)"})
ml:SetWarningLocalization({SpecWarnRaidCD="|TInterface\\Icons\\spell_holy_powerwordbarrier:12:12|t Dsac/AM soon |TInterface\\Icons\\Spell_Holy_AuraMastery:12:12|t"})
ml:SetTimerLocalization({TimerWarnRaidCD="Dsac/AM"})

mod:SetRevision("20221016192235")
mod:SetCreatureID(15989)
mod:SetMinSyncRevision(20220904000000)

mod:RegisterCombat("combat")
mod:SetModelScale(0.1)

mod:RegisterEventsInCombat(
--	"SPELL_CAST_START 28524",
	"SPELL_CAST_SUCCESS 28542 55665 28560 55696 55697",
	"SPELL_AURA_APPLIED 28522 28547 55699 45185",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH_UNFILTERED" -- have to do unfiltered because Zidras doesn't feel like fixing his stuff
)

-- General
local specWarnLowHP		= mod:NewSpecialWarning("SpecWarnSapphLow")

local berserkTimer		= mod:NewBerserkTimer(600)

-- Stage One (Ground Phase)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1))
local warnDrainLifeNow	= mod:NewSpellAnnounce(28542, 2)
local warnDrainLifeSoon	= mod:NewSoonAnnounce(28542, 1)
local warnAirPhaseSoon	= mod:NewAnnounce("WarningAirPhaseSoon", 3, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnLanded		= mod:NewAnnounce("WarningLanded", 4, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
--local warnBlizzard		= mod:NewSpellAnnounce(28560, 4)

local specWarnBlizzard	= mod:NewSpecialWarningGTFO(28547, nil, nil, nil, 1, 8)
local specWarnDecurse	= mod:NewSpecialWarningDispel(28542, "RemoveCurse", nil, nil, 1, 2)
local specWarnStomp		= mod:NewSpecialWarningTaunt(45185, nil, nil, nil, 1, 2)

local timerDrainLife	= mod:NewCDTimer(24, 28542, nil, nil, nil, 3, nil, DBM_COMMON_L.CURSE_ICON)
local timerAirPhase		= mod:NewTimer(80, "TimerAir", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 6)
--local timerBlizzard		= mod:NewNextTimer(7, 28560, nil, nil, nil, 3)
local timerTailSweep	= mod:NewNextTimer(10, 55696, nil, nil, nil, 2)

-- Stage Two (Air Phase)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2))
local warnAirPhaseNow	= mod:NewAnnounce("WarningAirPhaseNow", 4, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnIceBlock		= mod:NewTargetAnnounce(28522, 2)

local specWarnDeepBreath= mod:NewSpecialWarningSpell(28524, nil, nil, nil, 1, 2)
local specWarnRaidCD	= mod:NewSpecialWarning("SpecWarnRaidCD", nil, nil, nil, 1, 2, nil, nil, 28522)
local yellIceBlock		= mod:NewYell(28522)

local timerLanding		= mod:NewTimer(28, "TimerLanding", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6) -- inconsistent, 25-30 seen on Whitemane PTR
local timerIceBlast		= mod:NewCastTimer(8.55, 28524, nil, nil, nil, 2, DBM_COMMON_L.DEADLY_ICON)
local timerWarnRaidCD	= mod:NewTimer(2.2, "TimerWarnRaidCD", 64205, nil, false, 2)


mod:AddRangeFrameOption("12")

local warned_lowhp = false
local oldTarget

function mod:OnCombatStart(delay)
	warned_lowhp = false
	self:SetStage(1)
	warnDrainLifeSoon:Schedule(12-delay)
	timerDrainLife:Start(17-delay)
	--timerBlizzard:Start(21-delay)
	timerTailSweep:Start(-delay)
	warnAirPhaseSoon:Schedule(35-delay)
	timerAirPhase:Start(45-delay)
	self:ScheduleMethod(45-delay, "AirPhaseStart")
	berserkTimer:Start(-delay)
	if self.Options.RangeFrame then
		self:Schedule(43-delay, DBM.RangeCheck.Show, DBM.RangeCheck, 12)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		self:Unschedule(DBM.RangeCheck.Show, DBM.RangeCheck)
		DBM.RangeCheck:Hide()
	end
end

function mod:AirPhaseStart()
	self:SetStage(2)
	timerDrainLife:Cancel()
	timerAirPhase:Cancel()
	--timerBlizzard:Cancel()
	timerTailSweep:Cancel()
	warnAirPhaseNow:Show()
	timerLanding:Start()
	self:ScheduleMethod(28, "GroundPhaseStart")

	if self.Options.SpecWarnRaidCD and self:UnitClass() == "PALADIN" then
		oldTarget = UnitExists("boss1target")
		self:RegisterShortTermEvents(
			"UNIT_TARGET boss1"
		)
	end
end

function mod:GroundPhaseStart()
	self:SetStage(1)
	warnLanded:Show()
	warnDrainLifeSoon:Schedule(5)
	timerDrainLife:Start(10) -- (very inconsistent, seen 10 and also 30??)
	timerTailSweep:Start(7)
	--timerBlizzard:Start(7)
	if not warned_lowhp then
		warnAirPhaseSoon:Schedule(70-28)
		timerAirPhase:Start(80-28)
		self:ScheduleMethod(80-28, "AirPhaseStart")
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
			self:Schedule(80-28-1, DBM.RangeCheck.Show, DBM.RangeCheck, 12)
		end
	end
	
	self:UnregisterShortTermEvents() -- just in case something went wrong with target detection
end

function mod:UseCD()
	specWarnRaidCD:Show()
	specWarnRaidCD:Play("defensive")
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 28522 then
		warnIceBlock:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			yellIceBlock:Yell()
		end
	elseif args.spellId == 45185 then
		if not args:IsPlayer() then
			specWarnStomp:Show(args.destName)
			specWarnStomp:Play("tauntboss")
		end
	elseif args:IsSpellID(28547, 55699) and args:IsPlayer() and self:AntiSpam(1) then
		specWarnBlizzard:Show(args.spellName)
		specWarnBlizzard:Play("watchfeet")
	end	
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(28542, 55665) then -- Life Drain
		warnDrainLifeNow:Show()
		warnDrainLifeSoon:Schedule(19)
		timerDrainLife:Start()
		if self.Options.SpecWarn28542dispel and UnitPowerType("player") == 0 then -- crudely filter out feral druids
			specWarnDecurse:Show("raid")
			specWarnDecurse:Play("helpdispel")
		end
	elseif spellId == 28560 then -- doesn't work on Whitemane PTR. not fixing right now because unimportant
		--warnBlizzard:Show()
		--timerBlizzard:Start()
	elseif args:IsSpellID(55696, 55697) then -- Tail Sweep
		timerTailSweep:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.EmoteBreath or msg:find(L.EmoteBreath) then
		timerIceBlast:Start()
		specWarnDeepBreath:Show()
		specWarnDeepBreath:Play("findshelter")
	end
end

function mod:UNIT_HEALTH_UNFILTERED(uId)
	if uId == "boss1" and not warned_lowhp and self:GetUnitCreatureId(uId) == 15989 and UnitHealth(uId) / UnitHealthMax(uId) < 0.1 then
		warned_lowhp = true
		specWarnLowHP:Show()
		timerAirPhase:Cancel()
		warnAirPhaseSoon:Cancel()
		self:UnscheduleMethod("AirPhaseStart")
		if self.Options.RangeFrame then
			self:Unschedule(DBM.RangeCheck.Show, DBM.RangeCheck)
		end
	end
end

function mod:UNIT_TARGET(uId)
	if self:GetUnitCreatureId(uId) == 15989 then
		if oldTarget and not UnitExists("boss1target") then
			oldTarget = nil
		elseif not oldTarget and UnitExists("boss1target") then
			--self:ScheduleMethod(2.3-1, "UseCD")
			self:UseCD()
			timerWarnRaidCD:Start()
			self:UnregisterShortTermEvents()
		end
	end
end
