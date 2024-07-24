local mod	= DBM:NewMod("Razuvious", "DBM-Naxx", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221016184543")
mod:SetCreatureID(16061)

mod:RegisterCombat("combat_yell", L.Yell1, L.Yell2, L.Yell3, L.Yell4)

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 55543 29107 29060 29061",
	"SPELL_AURA_APPLIED 605",
	"UNIT_DIED"
)

local warnShoutNow		= mod:NewSpellAnnounce(29107, 1)
local warnShoutSoon		= mod:NewSoonAnnounce(29107, 3)
local warnShieldWall	= mod:NewAnnounce("WarningShieldWallSoon", 3, 29061, nil, nil, nil, 29061)

local timerShout		= mod:NewNextTimer(15, 29107, nil, nil, nil, 2) -- Whitemane PTR buff notes say it should be 12, but was consistently 15s in the vod
local timerTaunt		= mod:NewCDTimer(20, 29060, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerShieldWall	= mod:NewCDTimer(20, 29061, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerMindControl	= mod:NewBuffActiveTimer(60, 605, nil, nil, nil, 6)

function mod:OnCombatStart(delay)
	if self:IsDifficulty("normal25") then
		timerShout:Start(15 - delay)
		warnShoutSoon:Schedule(10 - delay)
	else
		timerShout:Start(25 - delay)
		warnShoutSoon:Schedule(20 - delay)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(55543, 29107) then  -- Disrupting Shout
		warnShoutNow:Show()
		if self:IsDifficulty("normal25") then
			timerShout:Start()
			warnShoutSoon:Schedule(10)
		else
			timerShout:Start(25)
			warnShoutSoon:Schedule(20)
		end
	elseif spellId == 29060 then -- Taunt
		timerTaunt:Start(20, args.sourceGUID)
	elseif spellId == 29061 and self:AntiSpam(2, 1) then -- ShieldWall
		timerShieldWall:Start(20, args.sourceGUID)
		warnShieldWall:Schedule(15)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 605 and args:IsSrcTypePlayer() then -- Mind Control
		timerMindControl:Start(nil, args.sourceName)
	end
end

function mod:UNIT_DIED(args)
	local guid = args.destGUID
	local cid = self:GetCIDFromGUID(guid)
	if cid == 16803 then--Deathknight Understudy
		timerTaunt:Stop(args.destGUID)
		timerShieldWall:Stop(args.destGUID)
	end
end
