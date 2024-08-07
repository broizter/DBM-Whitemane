local mod	= DBM:NewMod("Anub'Rekhan", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221106133531")
mod:SetCreatureID(15956)

mod:RegisterCombat("combat_yell", L.Pull1, L.Pull2)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 28783 56090 28785 54021",
	"SPELL_CAST_SUCCESS 56090",
	"SPELL_AURA_REMOVED 28785 54021"
)

local warningLocustSoon		= mod:NewSoonAnnounce(28785, 2)
local warningLocustFaded	= mod:NewFadesAnnounce(28785, 1)
local warnImpale			= mod:NewTargetNoFilterAnnounce(28783, 3, nil, false)

local specialWarningLocust	= mod:NewSpecialWarningSpell(28785, nil, nil, nil, 2, 2)
local yellImpale			= mod:NewYell(28783, nil, false)

local timerLocustIn			= mod:NewCDTimer(60, 28785, nil, nil, nil, 6)
local timerLocustFade		= mod:NewBuffActiveTimer(23, 28785, nil, nil, nil, 6)
local timerImpale			= mod:NewCDTimer(20, 56090, nil, nil, nil, 3)

mod:AddBoolOption("ArachnophobiaTimer", true, "timer", nil, nil, nil, "at1859")--Sad caveat that 10 and 25 man have own achievements and we have to show only 1 in GUI

function mod:OnCombatStart(delay)
	timerLocustIn:Start(60 - delay)
	warningLocustSoon:Schedule(50 - delay)
	timerImpale:Start(11-delay)
end

function mod:OnCombatEnd(wipe)
	if not wipe and self.Options.ArachnophobiaTimer then
		DBT:CreateBar(1200, L.ArachnophobiaTimer, "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01")
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(28783, 56090) then  -- Impale
		timerImpale:Start()
		warnImpale:Show(args.destName)
		if args:IsPlayer() then
			yellImpale:Yell()
		end
	elseif args:IsSpellID(28785, 54021) then  -- Locust Swarm
		specialWarningLocust:Show()
		specialWarningLocust:Play("aesoon")
		timerLocustIn:Stop()
		if self:IsDifficulty("normal25") then
			timerLocustFade:Start(23)
		else
			timerLocustFade:Start(19)
		end
	end
end

mod.SPELL_CAST_SUCCESS = mod.SPELL_CAST_START

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(28785, 54021)
	and args.auraType == "BUFF" then
		warningLocustFaded:Show()
		timerLocustIn:Start()
		warningLocustSoon:Schedule(57)
	end
end
