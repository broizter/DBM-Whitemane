local mod	= DBM:NewMod("Horsemen", "DBM-Naxx", 4)
local L		= mod:GetLocalizedStrings()

local ml = DBM:GetModLocalization("Horsemen")
ml:SetOptionLocalization({SpecialWarningMarkOnPlayerTotal="Show warning when you have 4 TOTAL marks on you"})
ml:SetWarningLocalization({SpecialWarningMarkOnPlayerTotal="|TInterface\\Icons\\ability_rogue_feigndeath:12:12|t %d MARKS TOTAL |TInterface\\Icons\\ability_rogue_feigndeath:12:12|t"})


mod:SetRevision("20221016185606")
mod:SetCreatureID(16063, 16064, 16065, 30549)

mod:RegisterCombat("combat", 16063, 16064, 16065, 30549)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 28884 57467",
	"SPELL_CAST_SUCCESS 28832 28833 28834 28835 28883 53638 57466 32455",
	"SPELL_AURA_APPLIED 29061",
	"SPELL_AURA_REMOVED 29061",
	"SPELL_AURA_APPLIED_DOSE 28832 28833 28834 28835",
	"UNIT_DIED"
)

--TODO, first marks
--TODO, verify stuff migrated from naxx 40
local warnMarkSoon				= mod:NewAnnounce("WarningMarkSoon", 1, 28835, false, nil, nil, 28835)
local warnMeteor				= mod:NewSpellAnnounce(57467, 4)
local warnVoidZone				= mod:NewTargetNoFilterAnnounce(28863, 3)--Only warns for nearby targets, to reduce spam
local warnHolyWrath				= mod:NewTargetNoFilterAnnounce(28883, 3, nil, false)
local warnBoneBarrier			= mod:NewTargetNoFilterAnnounce(29061, 2)

local specWarnMarkOnPlayer		= mod:NewSpecialWarning("SpecialWarningMarkOnPlayer", nil, nil, nil, 1, 6, nil, nil, 28835)
local specWarnMarkOnPlayerTotal	= mod:NewSpecialWarning("SpecialWarningMarkOnPlayerTotal", nil, nil, nil, 1, 2)
local specWarnVoidZone			= mod:NewSpecialWarningYou(28863, nil, nil, nil, 1, 2)
local yellVoidZone				= mod:NewYell(28863)

local timerLadyMark				= mod:NewNextTimer(15, 28833, nil, nil, nil, 3)
local timerZeliekMark			= mod:NewNextTimer(15, 28835, nil, nil, nil, 3)
local timerBaronMark			= mod:NewNextTimer(12, 28834, nil, nil, nil, 3)
local timerThaneMark			= mod:NewNextTimer(12, 28832, nil, nil, nil, 3)
local timerMeteorCD				= mod:NewCDTimer(15, 57467, nil, nil, nil, 3, nil, nil, true)
--local timerVoidZoneCD			= mod:NewCDTimer(12.9, 28863, nil, nil, nil, 3)-- 12.9-16
local timerHolyWrathCD			= mod:NewCDTimer(16, 28883, nil, nil, nil, 3)
local timerBoneBarrier			= mod:NewTargetTimer(20, 29061, nil, nil, nil, 5)

mod:AddRangeFrameOption("12")

mod:SetBossHealthInfo(
	16064, L.Korthazz,	-- Thane
	30549, L.Rivendare,	-- Baron
	16065, L.Blaumeux,	-- Lady
	16063, L.Zeliek		-- Zeliek
)

mod.vb.markCount = 0

local markNames = {
	GetSpellInfo(28832),
	GetSpellInfo(28833),
	GetSpellInfo(28834),
	GetSpellInfo(28835)
}

-- REVIEW-Have two logs where this is NOT verified! Still 15s timer on next meteor when he skips one (usually on tank swaps)
--[[local function MeteorCast(self)
	self:Unschedule(MeteorCast)
	timerMeteorCD:Restart()
	self:Schedule(15, MeteorCast, self)
end]]

function mod:OnCombatStart()
	self.vb.markCount = 0
	timerLadyMark:Start(32)
	timerZeliekMark:Start(32)
	timerBaronMark:Start(32)
	timerThaneMark:Start(32)
	warnMarkSoon:Schedule(27)
	timerMeteorCD:Start(22.3)
	timerHolyWrathCD:Start(10.1) -- REVIEW! ~2s variance? (25man Lordaeron 2022/10/16 wipe || 25man Lordaeron 2022/10/16 kill) - 12.3 || 10.1
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(12)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(28884, 57467) then
		warnMeteor:Show()
		timerMeteorCD:Start()
--		MeteorCast(self)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(28832, 28833, 28834, 28835) and self:AntiSpam(5, spellId) then
		self.vb.markCount = self.vb.markCount + 1
		if spellId == 28833 then -- Lady Mark
			timerLadyMark:Start(15)
		elseif spellId == 28835 then -- Zeliek Mark
			timerZeliekMark:Start(15)
		elseif spellId == 28834 then -- Baron Mark
			timerBaronMark:Start()
		elseif spellId == 28832 then -- Thane Mark
			timerThaneMark:Start()
		end
		warnMarkSoon:Schedule(9)
	elseif args.spellId == 28863 then
--		timerVoidZoneCD:Start()
		if args:IsPlayer() then
			specWarnVoidZone:Show()
			specWarnVoidZone:Play("targetyou")
			yellVoidZone:Yell()
		elseif self:CheckNearby(12, args.destName) then
			warnVoidZone:Show(args.destName)
		end
	elseif args:IsSpellID(28883, 53638, 57466, 32455) then
		warnHolyWrath:Show(args.destName)
		timerHolyWrathCD:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 29061 then
		timerBoneBarrier:Stop(args.destName)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 29061 then
		warnBoneBarrier:Show(args.destName)
		timerBoneBarrier:Start(20, args.destName)
	elseif args:IsSpellID(28832, 28833, 28834, 28835) and args:IsPlayer() then
		local minAmount = self:IsDifficulty("normal25") and 3 or 5
		local amount = args.amount or 1
		if amount >= minAmount then
			specWarnMarkOnPlayer:Show(args.spellName, amount)
			specWarnMarkOnPlayer:Play("stackhigh")
		end
		
		if (amount < minAmount or not self.Options.specWarnMarkOnPlayer) and self.Options.SpecialWarningMarkOnPlayerTotal and self:IsDifficulty("normal25") then -- Whitemane 100 raidwide stack buff
			local total = 0
			for i=1,4 do
				local _,_,_,stacks = UnitAura("player", markNames[i], nil, "HARMFUL")
				if stacks then
					total = total + (stacks ~= 0 and stacks or 1)
				end
			end
			
			if total >= 4 then
				specWarnMarkOnPlayerTotal:Show(total)
				specWarnMarkOnPlayerTotal:Play("stackhigh")
			end
		end
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 16064 then
		timerThaneMark:Cancel()
		timerMeteorCD:Cancel()
--		self:Unschedule(MeteorCast)
	elseif cid == 30549 then
		timerBaronMark:Cancel()
	elseif cid == 16065 then
		timerLadyMark:Cancel()
	elseif cid == 16063 then
		timerZeliekMark:Cancel()
	end
end
