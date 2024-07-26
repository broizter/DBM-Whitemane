local mod	= DBM:NewMod("Gluth", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220806123502")
mod:SetCreatureID(15932)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 28371 54427",
	"SPELL_AURA_REMOVED 28371 54427",
	"SPELL_CAST_SUCCESS 28375"
)

local warnEnrage		= mod:NewTargetNoFilterAnnounce(54427, 3, nil , "Healer|Tank|RemoveEnrage", 2)
local warnDecimateSoon	= mod:NewSoonAnnounce(28374, 2)
local warnDecimateNow	= mod:NewSpellAnnounce(28374, 3)

local specWarnEnrage	= mod:NewSpecialWarningDispel(54427, "RemoveEnrage", nil, nil, 1, 6)

local timerEnrage		= mod:NewBuffActiveTimer(8, 54427, nil, nil, nil, 5, nil, DBM_COMMON_L.ENRAGE_ICON)
local timerEnrageCD		= mod:NewCDTimer(30, 54427, nil, nil, nil, 5)
local timerDecimate		= mod:NewCDTimer(90, 28374, nil, nil, nil, 2)
local enrageTimer		= mod:NewBerserkTimer(360)

function mod:OnCombatStart(delay)
	enrageTimer:Start(360 - delay)
	timerEnrageCD:Start(30 - delay)
	if self:IsDifficulty("normal25") then
		timerDecimate:Start(90 - delay)
		warnDecimateSoon:Schedule(80 - delay)
	else
		timerDecimate:Start(105 - delay)
		warnDecimateSoon:Schedule(95 - delay)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28371, 54427) then
		if self.Options.SpecWarn54427dispel then
			local class = self:UnitClass()
			if class == "HUNTER" or class == "ROGUE" then
				specWarnEnrage:Play("dispelboss")
			else
				specWarnEnrage:Play("enrage")
			end
			specWarnEnrage:Show(args.destName)
		else
			warnEnrage:Show(args.destName)
		end
		timerEnrage:Start()
		timerEnrageCD:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(28371, 54427) then
		timerEnrage:Stop()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 28375 and self:AntiSpam(20) then
		if self:IsDifficulty("normal25") then
			warnDecimateNow:Show()
			timerDecimate:Start()
			warnDecimateSoon:Schedule(80)
		else
			warnDecimateNow:Show()
			timerDecimate:Start(105)
			warnDecimateSoon:Schedule(95)
		end
	end
end
