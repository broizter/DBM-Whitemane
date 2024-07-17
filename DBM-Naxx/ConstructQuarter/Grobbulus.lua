local mod	= DBM:NewMod("Grobbulus", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

local ml = DBM:GetModLocalization("Grobbulus")
ml:SetOptionLocalization({SpecWarnManySlimes="Show special warning when 3 or more Fallout Slimes are alive"})
ml:SetWarningLocalization({SpecWarnManySlimes="|TInterface\\Icons\\spell_nature_abolishmagic:12:12|t %d Slimes! %s |TInterface\\Icons\\spell_nature_abolishmagic:12:12|t"})

mod:SetRevision("20221016191326")
mod:SetCreatureID(15931)
mod:SetUsedIcons(1, 2, 3, 4)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 28169",
	"SPELL_AURA_REMOVED 28169",
	"SPELL_SUMMON 28240",
	"SPELL_DAMAGE 54363 28241",
	"SPELL_CAST_SUCCESS 54367 28156",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_DIED"
)

local emote_Spray = "Grobbulus sprays slime across the room!"

local warnInjection			= mod:NewTargetNoFilterAnnounce(28169, 2)
local warnCloud				= mod:NewSpellAnnounce(28240, 2)
local warnSlimeSprayNow		= mod:NewSpellAnnounce(54364, 2)
local warnSlimeSpraySoon	= mod:NewSoonAnnounce(54364, 1)

local specWarnInjection		= mod:NewSpecialWarningYou(28169, nil, nil, nil, 1, 2)
local specWarnCloud			= mod:NewSpecialWarningKeepMove(28240, "Tank", nil, nil, 1, 2)
local specWarnCloudGTFO		= mod:NewSpecialWarningGTFO(28240, "-Tank", nil, nil, 1, 2)
local specWarnManySlimes	= mod:NewSpecialWarning("SpecWarnManySlimes", nil, nil, nil, 1, 2)
local yellInjection			= mod:NewYellMe(28169, nil, false)

local timerInjection		= mod:NewTargetTimer(10, 28169, nil, nil, nil, 3)
local timerCloud			= mod:NewNextTimer(15, 28240, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerSlimeSprayCD		= mod:NewCDTimer(15, 54364, nil, nil, nil, 2)
local enrageTimer			= mod:NewBerserkTimer(480)

mod:AddSetIconOption("SetIconOnInjectionTarget", 28169, false, false, {1, 2, 3, 4})

local mutateIcons = {}
local slimesAlive = 0

local function addIcon(self)
	for i,j in ipairs(mutateIcons) do
		local icon = 0 + i
		self:SetIcon(j, icon)
	end
end

local function removeIcon(self, target)
	for i,j in ipairs(mutateIcons) do
		if j == target then
			table.remove(mutateIcons, i)
			self:SetIcon(target, 0)
		end
	end
	addIcon(self)
end

function mod:ManySlimes()
	if self:IsHealer() then
		specWarnManySlimes:Show(slimesAlive, "Heal hard!")
		specWarnManySlimes:Play("healall")
	else
		specWarnManySlimes:Show(slimesAlive, "Focus Slimes!")
		specWarnManySlimes:Play("killmob")
	end
end

function mod:OnCombatStart(delay)
	slimesAlive = 0
	table.wipe(mutateIcons)
	enrageTimer:Start(-delay)
	warnSlimeSpraySoon:Schedule(5)
	timerSlimeSprayCD:Start(10)
	timerCloud:Start(15)
end

function mod:OnCombatEnd()
	for _, j in ipairs(mutateIcons) do
		self:SetIcon(j, 0)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 28169 then
		warnInjection:Show(args.destName)
		timerInjection:Start(args.destName)
		if args:IsPlayer() then
			specWarnInjection:Show()
			specWarnInjection:Play("runout")
			yellInjection:Yell()
		end
		if self.Options.SetIconOnInjectionTarget then
			table.insert(mutateIcons, args.destName)
			addIcon(self)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 28169 then
		timerInjection:Cancel(args.destName)--Cancel timer if someone is dumb and dispels it.
		if self.Options.SetIconOnInjectionTarget then
			removeIcon(self, args.destName)
		end
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 28240 and args:GetSrcCreatureID() == 15931 then -- Poison Cloud. injecion being removed casts the same spell
		warnCloud:Show()
		timerCloud:Start()
		if self.Options.SpecWarn28240keepmove and self:IsTanking("player", "boss1", nil, true) then
			specWarnCloud:Show()
			specWarnCloud:Play("moveboss")
		end
	end
end

function mod:SPELL_DAMAGE(_,_,_, destGUID, _,_,spellId)
	if (spellId == 54363 or spellId == 28241) and self.Options.SpecWarn28240gtfo and destGUID == UnitGUID("player") and self:AntiSpam(1, "Cloud") then -- Poison Cloud damage
		specWarnCloudGTFO:Show("Cloud")
		specWarnCloudGTFO:Play("watchfeet")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(54367, 28156) then -- Fallout Slime casts Disease Cloud when it spawns
		slimesAlive = slimesAlive + 1
		if slimesAlive >= 3 and self.Options.SpecWarnManySlimes and self:AntiSpam(1, "Slime")then
			self:ScheduleMethod(0.2, "ManySlimes")
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == emote_Spray or msg:find(emote_Spray) then -- Slime Spray
		self:SendSync("Spray") -- Syncing to help unlocalized clients
	end
end

function mod:UNIT_DIED(args)
	if self:GetCIDFromGUID(args.destGUID) == 16290 then -- Fallout Slime
		slimesAlive = slimesAlive > 1 and slimesAlive - 1 or 0
		if slimesAlive < 3 then
			self:UnscheduleMethod("ManySlimes") -- in case a slime died right after new one spawned
		end
	end
end

function mod:OnSync(msg)
	if msg == "Spray" then
		warnSlimeSprayNow:Show()
		
		if self:IsDifficulty("normal25") then
			warnSlimeSpraySoon:Schedule(10)
			timerSlimeSprayCD:Start(15)
		else
			warnSlimeSpraySoon:Schedule(15)
			timerSlimeSprayCD:Start(20)
		end
	end
end
