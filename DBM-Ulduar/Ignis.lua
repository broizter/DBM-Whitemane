local mod	= DBM:NewMod("Ignis", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221011211626")
mod:SetCreatureID(33118)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 62680 63472 62488",
	"SPELL_CAST_SUCCESS 62548 63474",
	"SPELL_AURA_APPLIED 62717 63477 62382",
	"SPELL_AURA_REMOVED 62717 63477"
)

local warnSlagPot				= mod:NewTargetNoFilterAnnounce(63477, 3)
local warnConstruct				= mod:NewCountAnnounce(62488, 2)

local specWarnFlameJetsCast		= mod:NewSpecialWarningCast(63472, "SpellCaster", nil, nil, 2, 2)
local specWarnFlameBrittle		= mod:NewSpecialWarningSwitch(62382, "Dps", nil, nil, 1, 2)

local timerFlameJetsCast		= mod:NewCastTimer(2.7, 63472, nil, nil, nil, 5, nil, DBM_COMMON_L.IMPORTANT_ICON)
local timerFlameJetsCooldown	= mod:NewCDTimer(25, 63472, nil, nil, nil, 2, nil, DBM_COMMON_L.IMPORTANT_ICON, true) -- 10/25 diff. ~3s variance. Transcriptor snippet below. Added "keep" arg
local timerActivateConstruct	= mod:NewCDCountTimer(40, 62488, nil, nil, nil, 1, nil, nil, true) -- 10/25 diff. ~6s variance. Transcriptor snippet below. Added "keep" arg
--[[ local timerScorchCast			= mod:NewCastTimer(3, 63473) ]]
local timerScorchCooldown		= mod:NewCDTimer(17, 63473, nil, nil, nil, 5)
local timerSlagPot				= mod:NewTargetTimer(10, 63477, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerAchieve				= mod:NewAchievementTimer(240, 2930)

local soundAuraMastery			= mod:NewSound(63472, "soundConcAuraMastery")

mod:AddSetIconOption("SlagPotIcon", 63477, false, false, {8})

mod.vb.ConstructCount = 0

local function isBuffOwner(uId, spellId)
	if not uId and not spellId then return end
	local _, _, _, _, _, _, _, unitCaster = DBM:UnitBuff(uId, spellId)
	if unitCaster == uId then
		return true
	else
		return false
	end
end

function mod:OnCombatStart(delay)
	self.vb.ConstructCount = 0
	timerAchieve:Start()
	if self:IsDifficulty("normal10", "heroic10") then
		timerActivateConstruct:Start(39.9-delay, 1)
	else
		timerActivateConstruct:Start(29.9-delay, 1)
	end
	timerScorchCooldown:Start(12-delay) -- (10m Frostmourne 2022/07/17 || 25m Lordaeron 2022/10/05 || 25m Lordaeron 2022/10/09) - 25.0 || 25.0 || 25.0
	timerFlameJetsCooldown:Start(31.8-delay) -- 25 man log review (2022/07/10)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(62680, 63472) then		-- Flame Jets
		timerFlameJetsCast:Start()
		specWarnFlameJetsCast:Show()
		if self.Options.soundConcAuraMastery and isBuffOwner("player", 19746) then -- Concentration Aura Mastery by a Paladin will negate the interrupt effect of Flame Jets
			soundAuraMastery:Play("Interface\\AddOns\\DBM-Core\\sounds\\PlayerAbilities\\AuraMastery.ogg")
		else
			specWarnFlameJetsCast:Play("stopcast")
		end
		timerFlameJetsCooldown:Start()
	elseif args.spellId == 62488 then		-- Activate Construct
		self.vb.ConstructCount = self.vb.ConstructCount + 1
		warnConstruct:Show(self.vb.ConstructCount)
		if self.vb.ConstructCount < 20 then
			timerActivateConstruct:Start(40) -- 10/25 different. ~6s variance (25 man log review 2022/07/10 || 10m Frostmourne 2022/07/17 || 25m Lordaeron 2022/10/05 || 25m Lordaeron 2022/10/09) - 33.5, 38.5, 37.8 || 43.1, 46.0, 43.0, 46.0, 43.0 || 33.0, 39.1, 38.7, 39.0 || 33.0, 39.0, 36.0, 39.0
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(62548, 63474) then	-- Scorch
		timerScorchCooldown:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(62717, 63477) then		-- Slag Pot
		warnSlagPot:Show(args.destName)
		timerSlagPot:Start(args.destName)
		if self.Options.SlagPotIcon then
			self:SetIcon(args.destName, 8, 10)
		end
	elseif args.spellId == 62382 and self:AntiSpam(5, 1) then
		specWarnFlameBrittle:Show()
		specWarnFlameBrittle:Play("killmob")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(62717, 63477) then		-- Slag Pot
		if self.Options.SlagPotIcon then
			self:SetIcon(args.destName, 0)
		end
	end
end
