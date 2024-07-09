local mod	= DBM:NewMod("Shadron", "DBM-ChamberOfAspects", 1)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,normal25"

mod:SetRevision("20221012211527")
mod:SetCreatureID(30451)
mod:SetHotfixNoticeRev(20221012000000)
mod:SetMinSyncRevision(20221012000000)
mod:DisableMultiBossPulls()

mod:RegisterCombat("combat")
--mod:RegisterCombat("yell", L.YellShadronPull) -- DisableMultiBossPulls() is bugged and I don't want to modify core. have to use the other method

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 57579 59127"
)

local timerFissure			= mod:NewTargetTimer(5, 59128, nil, nil, 2, 3)--Cast timer until Void Blast. it's what happens when shadow fissure explodes.
local specWarnFissureYou	= mod:NewSpecialWarningYou(59127, nil, nil, nil, 3, 2)
local specWarnFissureClose	= mod:NewSpecialWarningClose(59127, nil, nil, nil, 2, 8)
local yellFissure			= mod:NewYellMe(59127)
local warnFissure			= mod:NewTargetNoFilterAnnounce(59127, 4)

mod:GroupSpells(59127, 59128)--Shadow fissure with void blast

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(57579, 59127) then
		timerFissure:Start(args.destName)
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
	end
end
