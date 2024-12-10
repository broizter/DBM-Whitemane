local mod	= DBM:NewMod("Jaraxxus", "DBM-Coliseum")
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 7007 $"):sub(12, -3))
mod:SetMinSyncRevision(7007)
mod:SetCreatureID(34780)
mod:SetMinCombatTime(30)
mod:SetUsedIcons(7, 8)

--mod:RegisterCombat("combat")
mod:RegisterCombat("yell", L.Aggro)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED 67051 67050 67049 66237 66197 68123 68124 68125 66334 67905 67906 67907 66532 66963 66964 66965 66209 66228 67107 67106 67108",
	"SPELL_AURA_APPLIED_DOSE 66228 67107 67106 67108",
	"SPELL_AURA_REMOVED 67051 67050 67049 66237 66197 68123 68124 68125",
	"SPELL_CAST_START 66532 66963 66964 66965",
	"SPELL_CAST_SUCCESS 66197 68123 68124 68125 66528 67029 67030 67031 66209",
	"SPELL_DAMAGE 66877 67070 67071 67072 66496 68716 68717 68718",
	"SPELL_MISSED 66877 67070 67071 67072 66496 68716 68717 68718",
	"CHAT_MSG_MONSTER_YELL"
)

local warnPortalSoon			= mod:NewSoonAnnounce(66269, 3)
local warnVolcanoSoon			= mod:NewSoonAnnounce(66258, 3)
local warnFlame				= mod:NewTargetAnnounce(66197, 4)
local warnFlesh				= mod:NewTargetAnnounce(66237, 4, nil, "Healer")

local specWarnFlame			= mod:NewSpecialWarningRun(66877, nil, nil, 2, 4, 2)
local specWarnFlameGTFO			= mod:NewSpecialWarningMove(66877, nil, nil, 2, 4, 2)
local specWarnFlesh			= mod:NewSpecialWarningYou(66237, nil, nil, nil, 1, 2)
local specWarnTouch			= mod:NewSpecialWarningYou(66209, nil, nil, nil, 1, 2)
local specWarnKiss			= mod:NewSpecialWarningCast(66334, "SpellCaster", nil, 2, 1, 2)
local specWarnNetherPower		= mod:NewSpecialWarningDispel(67009, "MagicDispeller", nil, nil, 1, 2)
local specWarnFelInferno		= mod:NewSpecialWarningMove(66496, nil, nil, nil, 1, 2)
local SpecWarnFelFireball		= mod:NewSpecialWarningInterrupt(66532, "HasInterrupt", nil, 2, 1, 2)
local SpecWarnFelFireballDispel		= mod:NewSpecialWarningDispel(66532, "RemoveMagic", nil, 2, 1, 2)

local timerCombatStart			= mod:NewCombatTimer(71.2)
local timerFlame 			= mod:NewTargetTimer(8, 66197, nil, nil, nil, 3) -- There are 8 debuff Ids. Since we detect first to warn, use an 8sec timer to cover duration of trigger spell and damage debuff.
local timerFlameCD			= mod:NewCDTimer(30, 66197, nil, nil, nil, 3) 		-- Every 30 sec
local timerTouchCD			= mod:NewCDTimer(10.2, 66209, nil, nil, nil, 3)
local timerNetherPowerCD		= mod:NewCDTimer(26, 67009, nil, "MagicDispeller", nil, 5, nil, DBM_CORE_L.MAGIC_ICON) 		-- Every 25-45 sec
local timerFlesh			= mod:NewTargetTimer(14, 66237, nil, "Healer", 2, 5, nil, DBM_CORE_L.HEALER_ICON)
local timerFleshCD			= mod:NewCDTimer(23, 66237, nil, "Healer", 2, 5, nil, DBM_CORE_L.HEALER_ICON) 		-- Every 20-25 sec
local timerPortalCD			= mod:NewCDTimer(120, 66269, nil, nil, nil, 1) 	-- Every 120 sec
local timerVolcanoCD			= mod:NewCDTimer(120, 66258, nil, nil, nil, 1)	-- Every 120 sec
local timerFelFireballCD		= mod:NewCDTimer(10, 66532, nil, nil, nil, 1) 	-- Every 10-15 sec
local timerFelLightningCD		= mod:NewCDTimer(11, 66528, nil, nil, nil, 1) 	-- Every 10-15 sec


mod:AddBoolOption("LegionFlameWhisper", false, "announce")
mod:AddBoolOption("LegionFlameIcon", true)
mod:AddBoolOption("IncinerateFleshIcon", true)
mod:AddBoolOption("YellOnTouch", true, "announce")

mod:RemoveOption("HealthFrame")

function mod:OnCombatStart(delay)
	if self.Options.IncinerateShieldFrame then
		DBM.BossHealth:Show(L.name)
		DBM.BossHealth:AddBoss(34780, L.name)
	end
	warnPortalSoon:Schedule(15-delay)	
	timerPortalCD:Start(20-delay)		-- Nether Portal 20 sec. after pull, next every 120 sec.
	warnVolcanoSoon:Schedule(75-delay)	-- 5 sec. longer (hack-fix for delay caused by Nether Power)
	timerVolcanoCD:Start(80-delay)		-- Volcano 80 seconds after pull, next every 120 sec.
	timerFleshCD:Start(25-delay) 		-- Incinerate Flesh 24-26 sec. after pull, next every 20-25 sec.
	timerFlameCD:Start(-delay)
	timerNetherPowerCD:Start(34-delay)
	timerFelFireballCD:Start(5.1-delay)
	timerFelLightningCD:Start(11.9-delay)
	if self:IsDifficulty("heroic10", "heroic25") then
		timerTouchCD:Start()
	end
end

function mod:OnCombatEnd()
	DBM.BossHealth:Clear()
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId)
	if (spellId == 66877 or spellId == 67070 or spellId == 67071 or spellId == 67072) and destGUID == UnitGUID("player") and self:AntiSpam(3, 1) then		-- Legion Flame
		specWarnFlameGTFO:Show()
		specWarnFlameGTFO:Play("runaway")
	elseif (spellId == 66496 or spellId == 68716 or spellId == 68717 or spellId == 68718) and destGUID == UnitGUID("player") and self:AntiSpam(3, 2) then	-- Fel Inferno
		specWarnFelInferno:Show()
		specWarnFelInferno:Play("runaway")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(67051, 67050, 67049, 66237) then	-- Incinerate Flesh
		warnFlesh:Show(args.destName)
		timerFlesh:Start(args.destName)
		timerFleshCD:Start()
		if self.Options.IncinerateFleshIcon then
			self:SetIcon(args.destName, 8, 15)
		end
		if args:IsPlayer() then
			specWarnFlesh:Show()
		end
	elseif args:IsSpellID(66197, 68123, 68124, 68125) then	-- Legion Flame ids 66199, 68126, 68127, 68128 (second debuff) do the actual damage. First 2 seconds are trigger debuff only.
		local targetname = args.destName
		timerFlame:Start(args.destName)
		timerFlameCD:Start()		
		if args:IsPlayer() then
			specWarnFlame:Show()
			specWarnFlame:Play("firerun")
		end		
		if self.Options.LegionFlameIcon then
			self:SetIcon(args.destName, 7, 8)
		end
		if DBM:GetRaidRank() >= 1 and self.Options.LegionFlameWhisper then
			self:SendWhisper(L.WhisperFlame, targetname)
		end
	elseif args:IsSpellID(66334, 67905, 67906, 67907) and args:IsPlayer() then
		specWarnKiss:Show()
		specWarnKiss:Play("stopcast")
	elseif args:IsSpellID(66532, 66963, 66964, 66965) then	-- Fel Fireball (announce if tank gets debuff for dispel)
		SpecWarnFelFireballDispel:Show(args.destName)
		SpecWarnFelFireballDispel:Play("helpdispel")
	elseif args:IsSpellID(66209) and args:IsPlayer() then
		specWarnTouch:Show()
		specWarnTouch:Play("runout")
		if self.Options.YellOnTouch then
			SendChatMessage("Touch on me!","SAY")
		end
	elseif args:IsSpellID(66228, 67107, 67106, 67108) and not args:IsDestTypePlayer() then	-- Nether Power
		timerNetherPowerCD:Start()
		specWarnNetherPower:Show(args.sourceName)
		specWarnNetherPower:Play("dispelboss")
		if timerFlameCD:GetRemaining() > 0 then
			timerFlameCD:AddTime(5)
		end
		if timerFleshCD:GetRemaining() > 0 then
			timerFleshCD:AddTime(5)
		end
		if timerFelFireballCD:GetRemaining() > 0 then
			timerFelFireballCD:AddTime(5)
		end
		if timerFelLightningCD:GetRemaining() > 0 then
			timerFelLightningCD:AddTime(5)
		end
		if timerTouchCD:GetRemaining() > 0 then
			timerTouchCD:AddTime(5)
		end
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(66228, 67107, 67106, 67108) and not args:IsDestTypePlayer() then	-- Nether Power
		timerNetherPowerCD:Start()
		specWarnNetherPower:Show(args.sourceName)
		specWarnNetherPower:Play("dispelboss")
		if timerFlameCD:GetRemaining() > 0 then
			timerFlameCD:AddTime(5)
		end
		if timerFleshCD:GetRemaining() > 0 then
			timerFleshCD:AddTime(5)
		end
		if timerFelFireballCD:GetRemaining() > 0 then
			timerFelFireballCD:AddTime(5)
		end
		if timerFelLightningCD:GetRemaining() > 0 then
			timerFelLightningCD:AddTime(5)
		end
		if timerTouchCD:GetRemaining() > 0 then
			timerTouchCD:AddTime(5)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(67051, 67050, 67049, 66237) then	-- Incinerate Flesh
		timerFlesh:Stop()
		self:RemoveIcon(args.destName)
	elseif args:IsSpellID(66197, 68123, 68124, 68125) then	-- Legion Flame
		self:SetIcon(args.destName, 0)
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(66532, 66963, 66964, 66965) then	-- Fel Fireball (track cast for interupt, only when targeted)
		if UnitName("target") == L.name then
			SpecWarnFelFireball:Show(args.sourceName)
			SpecWarnFelFireball:Play("kickcast")
		end
		timerFelFireballCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(66197, 68123, 68124, 68125) then	-- Legion Flame
		warnFlame:Show(args.destName)
	elseif args:IsSpellID(66528, 67029, 67030, 67031) then 	-- Fel Lightning
		timerFelLightningCD:Start()
	elseif args:IsSpellID(66209) and self:AntiSpam(2, 3) then -- Touch of Jaraxxus
		timerTouchCD:Start()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.FirstPull or msg:find(L.FirstPull) then
		timerCombatStart:Start()
	elseif msg == L.PortalSpawn or msg:find(L.PortalSpawn) then 	-- Nether Portal
		timerPortalCD:Start()
		warnPortalSoon:Schedule(115) -- 20 sec. longer (hack-fix for delay caused by Nether Power)
	elseif msg == L.VolcanoSpawn or msg:find(L.VolcanoSpawn) then 	-- Infernal Volcano
		timerVolcanoCD:Start()
		warnVolcanoSoon:Schedule(115) -- 20 sec. longer (hack-fix for delay caused by Nether Power)
	end
end