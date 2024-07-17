local mod	= DBM:NewMod("Maexxna", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220627034419")
mod:SetCreatureID(15952)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 28622 29484 54125",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

--TODO, verify nax40 web wrap timer
local warnWebWrap		= mod:NewTargetNoFilterAnnounce(28622, 2)
local warnWebSpraySoon	= mod:NewSoonAnnounce(29484, 1)
local warnWebSprayNow	= mod:NewSpellAnnounce(29484, 3)
local warnSpidersSoon	= mod:NewAnnounce("WarningSpidersSoon", 2, 17332)
local warnSpidersNow	= mod:NewAnnounce("WarningSpidersNow", 4, 17332)

local specWarnWebWrap	= mod:NewSpecialWarningSwitch(28622, "RangedDps", nil, nil, 1, 2)
local yellWebWrap		= mod:NewYellMe(28622)

local timerWebSpray		= mod:NewNextTimer(30.5, 29484, nil, nil, nil, 2)
local timerWebWrap		= mod:NewNextTimer(30, 28622, nil, "RangedDps|Healer", nil, 3)
local timerSpider		= mod:NewTimer(30.2, "TimerSpider", 17332, nil, nil, 1)

local emoteSpiderlings = "Spiderlings appear on the web!"

function mod:OnCombatStart(delay)
	warnWebSpraySoon:Schedule(30.5 - delay)
	timerWebSpray:Start(35.5 - delay)
	timerWebWrap:Start(15 - delay)
	warnSpidersSoon:Schedule(20.2 - delay)
	timerSpider:Start(25.2 - delay)
end

function mod:OnCombatEnd(wipe)
	if not wipe then
		if DBT:GetBar(L.ArachnophobiaTimer) then
			DBT:CancelBar(L.ArachnophobiaTimer)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 28622 then -- Web Wrap
		warnWebWrap:CombinedShow(0.5, args.destName)
		if self:AntiSpam(3, 1) then
			specWarnWebWrap:Show()
			if self:IsDifficulty("normal25") then
				timerWebWrap:Start()
			else
				timerWebWrap:Start(25)
			end
		end
		
		if args.destName == UnitName("player") then
			yellWebWrap:Yell()
		elseif not DBM:UnitDebuff("player", args.spellName) and self:AntiSpam(3, 2) then
			specWarnWebWrap:Play("targetchange")
		end
	elseif args:IsSpellID(29484, 54125) and self:AntiSpam(3, 3) then -- Web Spray
		warnWebSprayNow:Show()
		warnWebSpraySoon:Schedule(30.5)
		timerWebSpray:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == emoteSpiderlings then
		self:SendSync("Spiderlings")
	end
end

function mod:OnSync(event)
	if event == "Spiderlings" then
		warnSpidersNow:Show()
		warnSpidersSoon:Schedule(25.2)
		timerSpider:Start()
	end
end
