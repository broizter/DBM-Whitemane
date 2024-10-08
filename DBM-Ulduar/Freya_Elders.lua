local mod	= DBM:NewMod("Freya_Elders", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")

-- passive mod to provide information for multiple fight (trash respawn)
-- mod:SetCreatureID(32914, 32915, 32913)
-- mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START 62344 62325 62932",
	"SPELL_AURA_APPLIED 62310 62928",
	"SPELL_AURA_REMOVED 62310 62928",
	"SPELL_CAST_SUCCESS 62451 62865",
	"UNIT_DIED",
	"CHAT_MSG_MONSTER_YELL"
)

local specWarnImpale			= mod:NewSpecialWarningTaunt(62928, nil, nil, nil, 1, 2)
local specWarnFistofStone		= mod:NewSpecialWarningRun(62344, "Tank", nil, nil, 4, 2)
local specWarnGroundTremor		= mod:NewSpecialWarningCast(62932, "SpellCaster", nil, nil, 1, 2)

local warnUnstableBeamSoon		= mod:NewSoonAnnounce(62865, 3)

local timerImpale				= mod:NewTargetTimer(5, 62928, nil, "Healer|Tank", nil, 5)
local timerUnstableBeamCD		= mod:NewCDTimer(30, 62865, nil, nil, nil, 2, nil, nil, true)

mod:AddBoolOption("TrashRespawnTimer", true, "timer")

-- Trash: 33430 Guardian Lasher (flower)
-- 33355 (nymph)
-- 33354 (tree)
--
-- Elder Stonebark (ground tremor / fist of stone)
-- Elder Brightleaf (unstable sunbeam)
--
--Mob IDs:
-- Elder Ironbranch: 32913
-- Elder Brightleaf: 32915
-- Elder Stonebark: 32914

function mod:SPELL_CAST_START(args)
	if args.spellId == 62344 then					-- Fists of Stone
		specWarnFistofStone:Show()
		specWarnFistofStone:Play("justrun")
	elseif args:IsSpellID(62325, 62932) then		-- Ground Tremor
		specWarnGroundTremor:Show()
		specWarnGroundTremor:Play("stopcast")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(62310, 62928) then			-- Impale
		if not args:IsPlayer() then
			specWarnImpale:Show(args.destName)
			specWarnImpale:Play("tauntboss")
		end
		timerImpale:Start(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(62310, 62928) then			-- Impale
		timerImpale:Stop(args.destName)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(62451, 62865) and self:AntiSpam(5, 2) then -- Unstable Energy (Sun Beam)
		timerUnstableBeamCD:Start(20)
		warnUnstableBeamSoon:Schedule(17)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellBrightleafPull or msg:find(L.YellBrightleafPull) then
		timerUnstableBeamCD:Start(8)
		warnUnstableBeamSoon:Schedule(5)
	elseif msg == L.YellBrightleafKill or msg:find(L.YellBrightleafKill) then
		timerUnstableBeamCD:Stop()
		warnUnstableBeamSoon:Cancel()
	end
end

function mod:UNIT_DIED(args)
	if self.Options.TrashRespawnTimer and not DBT:GetBar(L.TrashRespawnTimer) then
		local guid = tonumber(args.destGUID:sub(9, 12), 16)
		if guid == 33430 or guid == 33355 or guid == 33354 then		-- guardian lasher / nymph / tree
			DBT:CreateBar(7200, L.TrashRespawnTimer)
		end
	end
end
