local mod	= DBM:NewMod("FlameLeviathan", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221031101217")

mod:SetCreatureID(33113)

mod:RegisterCombat("yell", L.YellPull)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 62396 62475 62374 62297",
	"SPELL_AURA_REMOVED 62396 62374",
	"SPELL_SUMMON 62907"
)

local warnHodirsFury		= mod:NewTargetAnnounce(62297, 3)
local pursueTargetWarn		= mod:NewAnnounce("PursueWarn", 2, 62374)
local warnNextPursueSoon	= mod:NewAnnounce("warnNextPursueSoon", 3, 62374)

local warnSystemOverload	= mod:NewSpecialWarningSpell(62475)
local pursueSpecWarn		= mod:NewSpecialWarning("SpecialPursueWarnYou", nil, nil, 2, 4)
local warnWardofLife		= mod:NewSpecialWarning("warnWardofLife")

local timerSystemOverload	= mod:NewBuffActiveTimer(20, 62475, nil, nil, nil, 6)
local timerPursued			= mod:NewNextTimer(30, 62374)
local timerFlameVents		= mod:NewCastTimer(10, 62396, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON)
local timerFlameVentsCD		= mod:NewCDTimer(20, 62396, nil, nil, nil, 2)
local timerNextWardOfLife	= mod:NewNextTimer(29, 62907, nil, nil, nil, 1)

local guids = {}
local function buildGuidTable(self)
	table.wipe(guids)
	for uId in DBM:GetGroupMembers() do
		local name, server = GetUnitName(uId, true)
		local fullName = name .. (server and server ~= "" and ("-" .. server) or "")
		guids[UnitGUID(uId.."pet") or "none"] = fullName
	end
end

function mod:OnCombatStart(delay)
	buildGuidTable(self)
	timerFlameVentsCD:Start(20-delay)
end

function mod:OnTimerRecovery()
	buildGuidTable(self)
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 62396 then		-- Flame Vents
		timerFlameVents:Start()
		timerFlameVentsCD:Start()
	elseif spellId == 62475 then	-- Systems Shutdown / Overload
		timerSystemOverload:Start()
		timerFlameVentsCD:Stop()
		timerFlameVentsCD:Start(40)
		timerPursued:Cancel()
		warnNextPursueSoon:Cancel()
		timerPursued:Start(20)
		warnNextPursueSoon:Schedule(15)
		warnSystemOverload:Show()
	elseif spellId == 62374 then	-- Pursued
		local target = guids[args.destGUID]
		warnNextPursueSoon:Schedule(25)
		timerPursued:Start()
		if target then
			pursueTargetWarn:Show(target)
			if target == UnitName("player") then
				pursueSpecWarn:Show()
			end
		end
	elseif spellId == 62297 then	-- Hodir's Fury (Person is frozen)
		local target = guids[args.destGUID]
		if target then
			warnHodirsFury:Show(target)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 62396 then
		timerFlameVents:Stop()
	elseif spellId == 62374 then	-- Pursued
		local target = guids[args.destGUID]
		timerPursued:Stop(target)
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 62907 and self:AntiSpam(3, 1) then		-- Ward of Life spawned (Creature id: 34275)
		warnWardofLife:Show()
		timerNextWardOfLife:Start()
	end
end