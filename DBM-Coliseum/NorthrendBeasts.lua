local mod	= DBM:NewMod("NorthrendBeasts", "DBM-Coliseum")
local L		= mod:GetLocalizedStrings()

local GetPlayerMapPosition, SetMapToCurrentZone = GetPlayerMapPosition, SetMapToCurrentZone

mod:SetRevision(("$Revision: 7007 $"):sub(12, -3))
mod:SetMinSyncRevision(7007)
mod:SetCreatureID(34797)
mod:SetMinCombatTime(30)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)

mod:RegisterCombat("yell", L.CombatStart)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED 67477 66331 67478 67479 66636 68335 66823 67618 67619 67620 66869 67657 66759 67658 67659 66758 66689 67650 67651 67652",
	"SPELL_AURA_APPLIED_DOSE 67477 66331 67478 67479 66636",
	"SPELL_CAST_START 66313 66330 67647 67648 67649 66794 67644 67645 67646 66821 66818 66901 67615 67616 67617 66902 67627 67628 67629",
	"SPELL_CAST_SUCCESS 67641 66883 67642 67643 66824 67612 67613 67614 66879 67624 67625 67626 67664 67345 67663 67665",
	"SPELL_DAMAGE 66320 67472 67473 67475 66881 67638 67639 67640",
	"SPELL_MISSED 66320 67472 67473 67475 66881 67638 67639 67640",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED"
)

-- Gormok the Impaler
local warnImpaleOn		= mod:NewStackAnnounce(66331, 2, nil, "Tank|Healer")
local warnFireBomb		= mod:NewSpellAnnounce(66317, 3, nil, false)
local WarningSnobold		= mod:NewAnnounce("WarningSnobold", 4)
local specWarnImpale5		= mod:NewSpecialWarningStack(66331, nil, 5, nil, nil, 1, 6)
local specWarnSilence		= mod:NewSpecialWarningSpell(66330, "SpellCaster", nil, nil, 1, 2)
local timerNextStompCD		= mod:NewCDTimer(20.4, 66330, nil, nil, nil, 2, nil, DBM_CORE_L.INTERRUPT_ICON)
local timerNextImpale		= mod:NewNextTimer(9.5, 66331, nil, "Tank|Healer", nil, 5, nil, DBM_CORE_L.TANK_ICON)
local timerRisingAngerCD    	= mod:NewCDTimer(21.4, 66636, nil, nil, nil, 1)
-- Acidmaw & Dreadscale
local warnSlimePool		= mod:NewSpellAnnounce(66883, 2, nil, "Melee")
local warnToxin			= mod:NewTargetAnnounce(66823, nil, nil, nil, 1, 2)
local warnBile			= mod:NewTargetAnnounce(66869, 3)
local warnEnrageWorm		= mod:NewSpellAnnounce(68335, 3)
local specWarnToxin		= mod:NewSpecialWarningMoveTo(66823, nil, nil, nil, 1, 2)
local specWarnBile		= mod:NewSpecialWarningYou(66869, nil, nil, nil, 1, 2)
local timerSubmergeCD		= mod:NewTimer(45, "TimerSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6) -- 45-50 sec.
local timerEmerge		= mod:NewTimer(8.5, "TimerEmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 6)
local timerSweepCD		= mod:NewCDTimer(24.8, 66794, nil, "Melee", nil, 3)
local timerSlimePoolCD		= mod:NewCDTimer(30, 66883, nil, "Melee", nil, 3)
local timerAcidicSpewCD		= mod:NewCDTimer(15, 66819, nil, "Tank", 2, 5, nil, DBM_CORE_L.TANK_ICON)
local timerMoltenSpewCD		= mod:NewCDTimer(15, 66820) -- 15-30 sec. CD
local timerParalyticSpray	= mod:NewCDTimer(20, 66901, nil, nil, nil, 3)
local timerBurningSpray		= mod:NewCDTimer(20, 66902, nil, nil, nil, 3)
local timerParalyticBite	= mod:NewCDTimer(20, 66824, nil, "Melee", nil, 3)
local timerBurningBite		= mod:NewCDTimer(20, 66879, nil, "Melee", nil, 3)
-- Icehowl
local warnCharge		= mod:NewTargetNoFilterAnnounce(52311, 4)
local warnBreath		= mod:NewSpellAnnounce(66689, 2)
local warnRage			= mod:NewSpellAnnounce(67657, 3)
local specWarnCharge		= mod:NewSpecialWarningRun(52311, nil, nil, nil, 4, 2)
local specWarnChargeNear	= mod:NewSpecialWarningClose(52311, nil, nil, nil, 3, 2)
local specWarnTranq		= mod:NewSpecialWarningDispel(66759, "RemoveEnrage", nil, nil, 1, 2)
local enrageTimer		= mod:NewBerserkTimer(150)
local timerBreath		= mod:NewCastTimer(4, 66689, nil, nil, nil, 3)--3 or 5? is it random target or tank?
local timerStaggeredDaze	= mod:NewBuffActiveTimer(15, 66758, nil, nil, nil, 5, nil, DBM_CORE_L.DAMAGE_ICON)
local timerNextCrashCD		= mod:NewCDTimer(57, 66683, nil, nil, nil, 2, nil, DBM_CORE_L.MYTHIC_ICON)
local timerArcticBreathCD	= mod:NewCDTimer(20, 66689) -- 14 sec. after pull, 20-30 sec. every next
local timerWhirlCD		= mod:NewCDTimer(18.2, 67665) -- 10-12 sec. after pull, 15-20 sec. every next
local timerIcehowlSpawn		= mod:NewTimer(329, "TimerIcehowlSpawn", 3130, nil, nil, 1)

-- Global
local timerPrePot		= mod:NewTimer(36.4, "TimerPrePot", 53909, nil, nil, 1)
local timerCombatStart		= mod:NewTimer(11, "TimerCombatStart", 11578, nil, nil, 1)
local timerWormSpawn		= mod:NewTimer(139, "TimerWormSpawn", 35387, nil, nil, 1)
local specWarnGTFO		= mod:NewSpecialWarningGTFO(66317, nil, nil, nil, 1, 2)

mod:AddBoolOption("PingCharge")
mod:AddBoolOption("SetIconOnChargeTarget", true)
mod:AddBoolOption("SetIconOnBileTarget", true)
mod:AddBoolOption("ClearIconsOnIceHowl", true)
mod:AddBoolOption("RangeFrame")
mod:AddBoolOption("IcehowlArrow")
mod:AddBoolOption("YellOnCharge", true, "announce")

local bileTargets	= {}
local bileName 		= DBM:GetSpellInfo(66869)
local toxinTargets	= {}
local burnIcon		= 8
local phases		= {}
local DreadscaleActive	= true
local DreadscaleDead	= false
local AcidmawDead	= false
local messageCounter 	= 0

local function countDown(self)
	DBM:PlaySoundFile("Interface\\AddOns\\DBM-Core\\sounds\\5.mp3")
	self:Schedule(1, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Core\\sounds\\4.mp3")
	self:Schedule(2, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Core\\sounds\\3.mp3")
	self:Schedule(3, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Core\\sounds\\2.mp3")
	self:Schedule(4, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Core\\sounds\\1.mp3")
end

local function updateHealthFrame(phase)
	if phases[phase] then
		return
	end
	phases[phase] = true
	if phase == 1 then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(34796, L.Gormok)
	elseif phase == 2 then
		DBM.BossHealth:AddBoss(35144, L.Acidmaw)
		DBM.BossHealth:AddBoss(34799, L.Dreadscale)
	elseif phase == 3 then
		DBM.BossHealth:AddBoss(34797, L.Icehowl)
	end
end

function mod:OnCombatStart()
	table.wipe(bileTargets)
	table.wipe(toxinTargets)
	table.wipe(phases)
	messageCounter = 0	-- help variable to register Submerge and Emerge
	burnIcon = 8
	DreadscaleActive = true
	DreadscaleDead = false
	AcidmawDead = false
	self:Schedule(6, countDown, self)
	mod:ScheduleMethod(11, "GromokStartTimers")
	timerCombatStart:Start(11)
	updateHealthFrame(1)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:warnToxin()
	warnToxin:Show(table.concat(toxinTargets, "<, >"))
	table.wipe(toxinTargets)
end

function mod:warnBile()
	warnBile:Show(table.concat(bileTargets, "<, >"))
	table.wipe(bileTargets)
	burnIcon = 8
end

function mod:GromokStartTimers()
	if self:IsDifficulty("heroic10", "heroic25") then
		timerWormSpawn:Start()
		timerIcehowlSpawn:Start()
		timerRisingAngerCD:Start(12.2)
	else
		timerRisingAngerCD:Start(16.7)
	end
	timerNextStompCD:Start(5)
	timerNextImpale:Start(8.7)
	specWarnSilence:Schedule(2) 
	specWarnSilence:ScheduleVoice(2, "silencesoon")	
end

function mod:WormsEmerge()
	if not AcidmawDead then
		timerSubmergeCD:Start()
		if DreadscaleActive then	-- Dreadscale active & Acidmaw stationary
			timerSweepCD:Start(24.8)
			timerParalyticSpray:Start(20)			
		else 						-- Dreadscale stationary & Acidmaw active
			timerSlimePoolCD:Start(14)
			timerParalyticBite:Start(20)			
			timerAcidicSpewCD:Start(15)
		end
	end
	if not DreadscaleDead then
		timerSubmergeCD:Start()
		if DreadscaleActive then	-- Dreadscale active & Acidmaw stationary
			timerSlimePoolCD:Start(15)
			timerMoltenSpewCD:Start(18.2)
			timerBurningBite:Start(15)
		else 						-- Dreadscale stationary & Acidmaw active
			timerSweepCD:Start(17.1)
			timerBurningSpray:Start(15)
		end
	end	
end

function mod:WormsSubmerge()
	timerEmerge:Start()
	timerSweepCD:Cancel()
	timerSlimePoolCD:Cancel()
	timerMoltenSpewCD:Cancel()
	timerParalyticSpray:Cancel()
	timerBurningBite:Cancel()
	timerAcidicSpewCD:Cancel()
	timerBurningSpray:Cancel()
	timerParalyticBite:Cancel()
	DreadscaleActive = not DreadscaleActive
end

function mod:IcehowlStartTimers()
	timerNextCrashCD:Start(30.2)
	timerArcticBreathCD:Start(14.5)
	timerWhirlCD:Start(12)
	if self:IsDifficulty("heroic25") then
		enrageTimer:Start()
	end
	if self:IsDifficulty("heroic10") then
		enrageTimer:Start(210)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	-- Gormok the Impaler
	if args:IsSpellID(67477, 66331, 67478, 67479) then		-- Impale
		timerNextImpale:Start()
		warnImpaleOn:Show(args.destName, 1)
	elseif args:IsSpellID(66636) then						-- Rising Anger
		WarningSnobold:Show()
		timerRisingAngerCD:Start()
	-- Acidmaw & Dreadscale
	elseif args:IsSpellID(68335) then						-- Worm Enrage
		warnEnrageWorm:Show()
	elseif args:IsSpellID(66823, 67618, 67619, 67620) then	-- Paralytic Toxin
		self:UnscheduleMethod("warnToxin")
		toxinTargets[#toxinTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnToxin:Show(bileName)
			specWarnToxin:Play("targetyou")
		end
		mod:ScheduleMethod(0.2, "warnToxin")
	elseif args:IsSpellID(66869) then						-- Burning Bile
		self:UnscheduleMethod("warnBile")
		bileTargets[#bileTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnBile:Show()
			specWarnBile:Play("targetyou")
		end
		if self.Options.SetIconOnBileTarget and burnIcon > 0 then
			self:SetIcon(args.destName, burnIcon, 15)
			burnIcon = burnIcon - 1
		end
		mod:ScheduleMethod(0.2, "warnBile")
	-- Icehowl
	elseif args:IsSpellID(67657, 66759, 67658, 67659) then	-- Frothing Rage
		warnRage:Show()
		timerWhirlCD:Start(22)
		timerArcticBreathCD:Start(5)
		if self:IsDifficulty("normal10", "normal25") then
			specWarnTranq:Show()
			specWarnTranq:Play("trannow")
		end
	elseif args:IsSpellID(66758) then						-- Staggered Daze
		timerStaggeredDaze:Start()
		timerWhirlCD:Start(17.8)--todo 17
		timerArcticBreathCD:Start(21.4) --todo  20
	elseif args:IsSpellID(66689, 67650, 67651, 67652) and self:AntiSpam(2, 1) then	-- Arctic Breath
		timerArcticBreathCD:Start()
		timerBreath:Start()
		warnBreath:Show()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(67477, 66331, 67478, 67479) then		-- Impale
		timerNextImpale:Start()
		warnImpaleOn:Show(args.destName, args.amount)
		if (args.amount >= 5 and not self:IsDifficulty("heroic10", "heroic25") ) or ( args.amount >= 4 and self:IsDifficulty("heroic10", "heroic25") ) then 
			if args:IsPlayer() then
				specWarnImpale5:Show(args.amount)
				specWarnImpale5:Play("stackhigh")
			end
		end
	elseif args:IsSpellID(66636) then						-- Rising Anger
		WarningSnobold:Show()
		timerRisingAngerCD:Start()
	end
end

function mod:SPELL_CAST_START(args)
	-- Gormok the Impaler
	if args:IsSpellID(66313) then							-- Fire Bomb (Impaler)
		warnFireBomb:Show()
	elseif args:IsSpellID(66330, 67647, 67648, 67649) then	-- Staggering Stomp - Can be as little as 20 seconds, but its rare
		timerNextStompCD:Start()
		specWarnSilence:Schedule(19)
		specWarnSilence:ScheduleVoice(19, "silencesoon")
	-- Acidmaw & Dreadscale
	elseif args:IsSpellID(66794, 67644, 67645, 67646) then	-- Sweep stationary worm
		timerSweepCD:Start()
	elseif args:IsSpellID(66821) then						-- Molten spew
		timerMoltenSpewCD:Start()
	elseif args:IsSpellID(66818) then						-- Acidic Spew
		timerAcidicSpewCD:Start()
	elseif args:IsSpellID(66901, 67615, 67616, 67617) then	-- Paralytic Spray
		timerParalyticSpray:Start()
	elseif args:IsSpellID(66902, 67627, 67628, 67629) then	-- Burning Spray
		timerBurningSpray:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	-- Acidmaw & Dreadscale
	if args:IsSpellID(67641, 66883, 67642, 67643) then -- Slime Pool Cloud Spawn
		warnSlimePool:Show()
		timerSlimePoolCD:Start()
	elseif args:IsSpellID(66824, 67612, 67613, 67614) then	-- Paralytic Bite
		timerParalyticBite:Start()
	elseif args:IsSpellID(66879, 67624, 67625, 67626) then	-- Burning Bite
		timerBurningBite:Start()
	-- Icehowl
	elseif args:IsSpellID(67664, 67345, 67663, 67665) then	-- Whirl
		timerWhirlCD:Start()
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
	if (spellId == 66320 or spellId == 67472 or spellId == 67473 or spellId == 67475) and destGUID == UnitGUID("player") then  -- Fire Bomb
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("runaway")
	elseif (spellId == 66881 or spellId == 67638 or spellId == 67639 or spellId == 67640) and destGUID == UnitGUID("player") then	-- Slime Pool
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("runaway")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if (msg:match(L.Charge) or msg:find(L.Charge)) and target then
		timerNextCrashCD:Start()
		target = DBM:GetUnitFullName(target)
		warnCharge:Show(target)
		if self.Options.ClearIconsOnIceHowl then
			self:ClearIcons()
		end
		if target == UnitName("player") then
			specWarnCharge:Show()
			specWarnCharge:Play("justrun")
			if self.Options.YellOnCharge then
				SendChatMessage("Charge on me!","SAY")
			end
			if self.Options.PingCharge then
				Minimap:PingLocation()
			end
		elseif self:CheckNearby(11, target) then
			specWarnChargeNear:Show(target)
			specWarnChargeNear:Play("runaway")
		end
		if self.Options.IcehowlArrow then
			local uId = DBM:GetRaidUnitId(target)
			local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
			DBM.Arrow:ShowRunAway(x, y, 12, 5)
		end
		if self.Options.SetIconOnChargeTarget then
			self:SetIcon(target, 8, 5)
		end
	elseif msg:match(L.Submerge) or msg:find(L.Submerge) then
		messageCounter = messageCounter + 1
		if messageCounter == 2 then
			self:ScheduleMethod(0.1, "WormsSubmerge")
			messageCounter = 0
		end
	elseif msg:match(L.Emerge) or msg:find(L.Emerge) then
		messageCounter = messageCounter + 1
		if messageCounter == 2 then
		self:ScheduleMethod(0.1, "WormsEmerge")
			messageCounter = 0
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.PrePot or msg:find(L.PrePot) then -- Prepot
		timerPrePot:Start()
	elseif msg == L.Phase2 or msg:find(L.Phase2) then -- Acidmaw & Dreadscale
		timerCombatStart:Start(15.3)
		self:Schedule(10.3, countDown, self)
		timerWormSpawn:Stop()
		updateHealthFrame(2)
		self:ScheduleMethod(15.3, "WormsEmerge")
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(10)
		end
	elseif msg == L.Phase3 or msg:find(L.Phase3) then --Icehowl
		timerIcehowlSpawn:Cancel()
		timerSubmergeCD:Cancel()
		timerCombatStart:Start(13)
		self:Schedule(8, countDown, self)
		mod:ScheduleMethod(13, "IcehowlStartTimers")
		updateHealthFrame(3)
		self:UnscheduleMethod("WormsSubmerge")
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 34796 then
		specWarnSilence:Cancel()
		specWarnSilence:CancelVoice()
		timerRisingAngerCD:Stop()
		timerNextStompCD:Stop()
		timerNextImpale:Stop()
		DBM.BossHealth:RemoveBoss(cid) 		-- remove Gormok from the health frame
	elseif cid == 35144 then
		AcidmawDead = true
		timerSubmergeCD:Stop()
		timerParalyticSpray:Cancel()
		timerParalyticBite:Cancel()
		timerAcidicSpewCD:Cancel()
		if DreadscaleActive then
			timerSweepCD:Cancel()
		else
			timerSlimePoolCD:Cancel()
		end
		if DreadscaleDead then
			DBM.BossHealth:RemoveBoss(35144) -- remove Acidmaw from the health frame
			DBM.BossHealth:RemoveBoss(34799) -- remove Dreadscale from the health frame
			timerSlimePoolCD:Stop()
		end
	elseif cid == 34799 then
		DreadscaleDead = true
		timerSubmergeCD:Stop()
		timerBurningSpray:Cancel()
		timerBurningBite:Cancel()
		timerMoltenSpewCD:Cancel()
		if DreadscaleActive then
			timerSlimePoolCD:Cancel()
		else
			timerSweepCD:Cancel()
		end
		if AcidmawDead then
			DBM.BossHealth:RemoveBoss(35144) -- remove Acidmaw from the health frame
			DBM.BossHealth:RemoveBoss(34799) -- remove Dreadscale from the health frame
			timerSlimePoolCD:Stop()
		end
	end
end
