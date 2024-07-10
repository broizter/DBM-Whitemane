local mod	= DBM:NewMod("Noth", "DBM-Naxx", 3)
local L		= mod:GetLocalizedStrings()

local GetSpellInfo = GetSpellInfo

mod:SetRevision("20221027184343")
mod:SetCreatureID(15954)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS 29213 54835",
	"SPELL_AURA_APPLIED 29208 29209 29210 29211",
	"SPELL_CAST_START 54890 54891",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local emote_Teleport = "%s teleports to the balcony above!"
local emote_Return = "%s teleports back into the battle!"

local warnTeleportNow	= mod:NewAnnounce("WarningTeleportNow", 3, 46573)
local warnTeleportSoon	= mod:NewAnnounce("WarningTeleportSoon", 1, 46573)
local warnCurse			= mod:NewSpellAnnounce(29213, 2)
local warnBlinkSoon		= mod:NewSoonAnnounce(29208, 1)
local warnBlink			= mod:NewSpellAnnounce(29208, 3)

local specWarnAdds		= mod:NewSpecialWarningAdds(29212, "-Healer", nil, nil, 1, 2)
local specWarnExplosion	= mod:NewSpecialWarningInterrupt(54891)
local specWarnDecurse	= mod:NewSpecialWarningDispel(29213, "RemoveCurse", nil, nil, 1, 2)

local timerTeleport		= mod:NewTimer(80, "TimerTeleport", 46573, nil, nil, 6)
local timerTeleportBack	= mod:NewTimer(70, "TimerTeleportBack", 46573, nil, nil, 6)
local timerCurseCD		= mod:NewCDTimer(25, 29213, nil, nil, nil, 5, nil, DBM_COMMON_L.CURSE_ICON) -- Whitemane PTR - buff notes say 15s, vod says consistent 25s
local timerAddsCD		= mod:NewAddsTimer(25, 29212, nil, "-Healer")
local timerBlink		= mod:NewNextTimer(30, 29208)


function mod:OnCombatStart(delay)
	timerAddsCD:Start(-delay)
	timerCurseCD:Start(15-delay)
	if self:IsDifficulty("normal25") then
		timerBlink:Start(26-delay)
		warnBlinkSoon:Schedule(23-delay)
	end
	timerTeleport:Start(-delay)
	warnTeleportSoon:Schedule(70-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(29213, 54835) then -- Curse of the Plaguebringer
		warnCurse:Show()
		timerCurseCD:Start()
		if self.Options.SpecWarn29213dispel and UnitPowerType("player") == 0 then -- crudely filter out feral druids
			specWarnDecurse:Show("raid")
			specWarnDecurse:Play("helpdispel")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if self:IsDifficulty("normal25") and args:IsSpellID(29208, 29209, 29210, 29211) then -- Blink
		warnBlink:Show()
		timerBlink:Start()
		warnBlinkSoon:Schedule(27)
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(54890, 54891) and self:AntiSpam(1, "ArcaneExplosion") then -- Arcane Explosion
		specWarnExplosion:Show(args.sourceName)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg) -- Syncing to help unlocalized clients
	if msg == emote_Teleport or msg:find(emote_Teleport) then
		self:SendSync("Teleport")
	elseif msg == emote_Return or msg:find(emote_Return) then
		self:SendSync("Return")
	elseif msg == L.Adds or msg:find(L.Adds) then
		self:SendSync("Adds")
	elseif msg == L.AddsTwo or msg:find(L.AddsTwo) then
		self:SendSync("AddsTwo")
	end
end

function mod:OnSync(msg)
	if not self:IsInCombat() then return end
	if msg == "Teleport" then -- Teleport away
		timerCurseCD:Stop()
		timerAddsCD:Start(4)
		timerBlink:Stop()
		warnBlinkSoon:Cancel()
		timerTeleportBack:Start()
		warnTeleportSoon:Schedule(70 - 10)
		warnTeleportNow:Show()
	elseif msg == "Return" then -- Return to ground
		warnTeleportNow:Show()
		timerAddsCD:Start()
		timerCurseCD:Start(15)
		if self:IsDifficulty("normal25") then
			timerBlink:Start(26)
			warnBlinkSoon:Schedule(23)
		end
		timerTeleport:Start()
		warnTeleportSoon:Schedule(70)
	elseif msg == "Adds" then -- Boss Grounded
		specWarnAdds:Show()
		specWarnAdds:Play("killmob")		
		timerAddsCD:Start()
	elseif msg == "AddsTwo" then -- Boss away
		specWarnAdds:Show()
		specWarnAdds:Play("killmob")
		timerAddsCD:Start()
	end
end
