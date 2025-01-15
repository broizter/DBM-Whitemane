local L

------------------------
--  Northrend Beasts  --
------------------------
L = DBM:GetModLocalization("NorthrendBeasts")

L:SetGeneralLocalization({
	name = "Northrend Beasts"
})

L:SetTimerLocalization({
	TimerIcehowlSpawn	= "Icehowl spawns",
	TimerWormSpawn		= "Worms spawn",
	TimerPrePot		= "Prepot",
	TimerCombatStart	= "Boss activates",
	TimerNextBoss		= "Next boss",
	TimerEmerge			= "Emerge",
	TimerSubmerge		= "Submerge"
})

L:SetWarningLocalization{
	SpecialWarningAnger3		= "Rising Anger >%d<",
	WarningSnobold				= "Snobold Vassal spawned"
}

L:SetOptionLocalization({
	TimerPrePot				= "Show prepot timer on first pull",
	TimerCombatStart			= "Show a timer for when the next boss becomes active",
	TimerIcehowlSpawn			= "Show timer for when Icehowl spawns",
	TimerWormSpawn				= "Show timer for when worms spawn",
	WarningSnobold				= "Show warning for Snobold Vassal spawns",
	PingCharge			= "Ping the minimap when Icehowl is about to charge you",
	ClearIconsOnIceHowl	= "Clear all icons before charge",
	TimerNextBoss		= "Show timer for next boss spawn",
	TimerEmerge			= "Show timer for emerge",
	TimerSubmerge		= "Show timer for submerge",
	SpecialWarningAnger3		= "Show special warning for Rising Anger (>=3 stacks)",
	YellOnCharge				= "Yell on Icehowl charge",
	SetIconOnChargeTarget		= "Set icons on charge targets (skull)",
	SetIconOnBileTarget			= "Set icons on Burning Bile targets",
	RangeFrame                  = "Show range frame in Phase 2",
	IcehowlArrow		= "Show DBM arrow when Icehowl is about to charge near you"
})

L:SetMiscLocalization({
	PrePot				= "Welcome, champions! You have heard the call of the Argent Crusade and you have boldly answered! It is here, in the Crusaders' Coliseum, that you will face your greatest challenges. Those of you who survive the rigors of the coliseum will join the Argent Crusade on its march to Icecrown Citadel.",
	Charge				= "^%%s glares at (%S+) and lets out",
	CombatStart			= "Hailing from the deepest, darkest caverns of the Storm Peaks, Gormok the Impaler! Battle on, heroes!",
	Phase2				= "Steel yourselves, heroes, for the twin terrors, Acidmaw and Dreadscale, enter the arena!",
	Submerge			= "^%%s buries itself in the earth!",
	Emerge 				= "^%%s getting out of the ground!",
	Phase3				= "The air itself freezes with the introduction of our next combatant, Icehowl! Kill or be killed, champions!",
	Gormok				= "Gormok the Impaler",
	Acidmaw				= "Acidmaw",
	Dreadscale			= "Dreadscale",
	Icehowl				= "Icehowl"
})

---------------------
--  Lord Jaraxxus  --
---------------------
L = DBM:GetModLocalization("Jaraxxus")

L:SetGeneralLocalization{
	name = "Lord Jaraxxus"
}

L:SetWarningLocalization{
	WarnNetherPower				= "Nether Power on Lord Jaraxxus - Dispel now",
	SpecWarnTouch				= "Touch of Jaraxxus on you",
	SpecWarnTouchNear			= "Touch of Jaraxxus on %s near you",
	SpecWarnNetherPower			= "Dispel now",
	SpecWarnFelFireball			= "Fel Fireball - Interrupt now"
}

L:SetTimerLocalization{
	TimerCombatStart		= "Combat starts"
}

L:SetMiscLocalization{
	WhisperFlame		= "Legion Flame on you",
	IncinerateTarget	= "Incinerate Flesh: %s"
}

L:SetOptionLocalization{
	TimerCombatStart			= "Show time for start of combat",
	WarnNetherPower				= "Show warning when Lord Jaraxxus gains Nether Power (to dispel/steal)",
	SpecWarnTouch				= "Show special warning when you are affected by Touch of Jaraxxus",
	SpecWarnTouchNear			= "Show special warning for Touch of Jaraxxus near you",
	SpecWarnNetherPower			= "Show special warning for Nether Power (to dispel/steal)",
	SpecWarnFelFireball			= "Show special warning for Fel Fireball (to interrupt)",
	TouchJaraxxusIcon			= "Set icons on Touch of Jaraxxus targets",
	IncinerateFleshIcon			= "Set icons on Incinerate Flesh targets",
	LegionFlameIcon				= "Set icons on Legion Flame targets",
	LegionFlameWhisper			= "Send whisper to Legion Flame targets",
	YellOnTouch				= "Yell on Touch of Jaraxxus",
	IncinerateShieldFrame		= "Show boss health with a health bar for Incinerate Flesh"
}

L:SetMiscLocalization{
	FirstPull	= "Grand Warlock Wilfred Fizzlebang will summon forth your next challenge. Stand by for his entry.",
	Aggro = "You face Jaraxxus, Eredar Lord of the Burning Legion!",
	PortalSpawn = "Come forth, sister! Your master calls!",
	VolcanoSpawn = "IN-FER-NO!"
}

-------------------------
--  Faction Champions  --
-------------------------
L = DBM:GetModLocalization("Champions")

local champions = "Faction Champions"
if UnitFactionGroup("player") == "Alliance" then
	champions = "Horde Champions"
elseif UnitFactionGroup("player") == "Horde" then
	champions = "Alliance Champions"
end

L:SetWarningLocalization({
	SpecWarnTotem		= "Kill healing stream totem!",
	SpecWarnEyebeamSoon			= "Eyebeam incoming!"
})

L:SetGeneralLocalization({
	name = champions
})

L:SetTimerLocalization({
	TimerSpawnTimer	= "Champions spawn"
})

L:SetOptionLocalization({
	TimerSpawnTimer			= "Show timer until champions spawn",
	SpecWarnTotem			= "Show special warning to kill Healing Stream Totem",
	SpecWarnEyebeamSoon		= "Show special warning when Demon Hunter is about to use Eye Beam"
})

L:SetMiscLocalization({
	FocusedEyebeam			= "Demonic Eyebeam is focusing on you!",
	--Horde NPCs
	Gorgrim				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:64:64:96|t Gorgrim Shadowcleave",		-- 34458
	Birana				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:95:126.5:0:32|t Birana Stormhoof",			-- 34451
	Erin				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:95:126.5:0:32|t Erin Misthoof",			-- 34459
	Rujkah				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:32:64|t Ruj'kah",						-- 34448
	Ginselle			= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:63.5:0:32|t Ginselle Blightslinger",	-- 34449
	Liandra				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:64:96|t Liandra Suncaller",			-- 34445
	Malithas			= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:64:96|t Malithas Brightblade",		-- 34456
	Caiphus				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:63.5:95:32:64|t Caiphus the Stern",		-- 34447
	Vivienne			= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:63.5:95:32:64|t Vivienne Blackwhisper",	-- 34441
	Mazdinah			= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:63.5:95:0:32|t Maz'dinah",					-- 34454
	Thrakgar			= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:63.5:32:64|t Thrakgar",					-- 34444
	Broln				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:63.5:32:64|t Broln Stouthorn",			-- 34455
	Harkzog				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:95:126.5:32:64|t Harkzog",					-- 34450
	Narrhok				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:0:32|t Narrhok Steelbreaker",			-- 34453
	Monroth				= "Monroth the Exiled", -- 110000
	Gorgaz				= "Gor'gaz the Terror", -- 110004
	--Alliance NPCs
	Tyrius				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:64:64:96|t Tyrius Duskblade",			-- 34461
	Kavina				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:95:126.5:0:32|t Kavina Grovesong",			-- 34460
	Melador				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:95:126.5:0:32|t Melador Valestrider",		-- 34469
	Alyssia             = "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:32:64|t Alyssia Moonstalker",			-- 34467
	Noozle				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:63.5:0:32|t Noozle Whizzlestick",		-- 34468
	Baelnor				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:64:96|t Baelnor Lightbearer",			-- 34471
	Velanaa				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:64:96|t Velanaa",						-- 34465
	Anthar				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:63.5:95:32:64|t Anthar Forgemender",		-- 34466
	Brienna				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:63.5:95:32:64|t Brienna Nightfell",		-- 34473
	Irieth				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:63.5:95:0:32|t Irieth Shadowstep",			-- 34472
	Saamul				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:63.5:32:64|t Saamul",					-- 34470
	Shaabad				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:32:63.5:32:64|t Shaabad",					-- 34463
	Serissa				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:95:126.5:32:64|t Serissa Grimdabbler",		-- 34474
	Shocuul				= "|TInterface\\WorldStateFrame\\Icons-Classes.blp:24:24:0:0:128:128:0:32:0:32|t Shocuul",						-- 34475

	SpawnTimer	   = "The next battle will be against the Argent Crusade's most powerful knights! Only by defeating them will you be deemed worthy...",
	AllianceVictory    = "GLORY TO THE ALLIANCE!",
	HordeVictory       = "That was just a taste of what the future brings. FOR THE HORDE!",
	YellKill           = "A shallow and tragic victory. We are weaker as a whole from the losses suffered today. Who but the Lich King could benefit from such foolishness? Great warriors have lost their lives. And for what? The true threat looms ahead - the Lich King awaits us all in death."
})

---------------------
--  Val'kyr Twins  --
---------------------
L = DBM:GetModLocalization("ValkTwins")

L:SetGeneralLocalization({
	name = "Val'kyr Twins"
})

L:SetTimerLocalization({
	TimerSpecialSpell	= "Next special ability",
	TimerAnubRoleplay	= "Floor breaks in"
})

L:SetWarningLocalization({
	WarnSpecialSpellSoon		= "Special ability soon",
	SpecWarnSpecial				= "Change color",
	SpecWarnSwitchTarget		= "Switch target",
	SpecWarnKickNow				= "Interrupt now",
	WarningTouchDebuff			= "Debuff on >%s<",
	WarningPoweroftheTwins2		= "Power of the Twins - More healing on >%s<"
})

L:SetMiscLocalization({
--	YellPull	= "In the name of our dark master. For the Lich King. You. Will. Die.",
--	CombatStart	= "Only by working together will you overcome the final challenge. From the depths of Icecrown come two of the Scourge's most powerful lieutenants: fearsome val'kyr, winged harbingers of the Lich King!",
	Fjola		= "Fjola Lightbane",
	Eydis		= "Eydis Darkbane",
	AnubRP		= "A mighty blow has been dealt to the Lich King! You have proven yourselves as able bodied champions of the Argent Crusade. Together we will strike against Icecrown Citadel and destroy what remains of the Scourge! There is no challenge that we cannot face united!"
})

L:SetOptionLocalization({
	RangeFrame                  = "Show range frame for easier stacking",
	TimerSpecialSpell			= "Show timer for next special ability",
	TimerAnubRoleplay			= "Show roleplay timer for Lich King breaking the floor",
	WarnSpecialSpellSoon		= "Show pre-warning for next special ability",
	SpecWarnSpecial				= "Show special warning when you have to change color",
	SpecWarnSwitchTarget		= "Show special warning when the other Twin is casting",
	SpecWarnKickNow				= "Show special warning when you have to interrupt",
	SpecialWarnOnDebuff			= "Show change color special warning when touch debuffed (to switch debuff)",
	SetIconOnDebuffTarget		= "Set icons on Touch of Light/Darkness debuff targets (heroic)",
	WarningTouchDebuff			= "Announce Touch of Light/Darkness debuff targets",
	WarningPoweroftheTwins2		= "Announce Power of the Twins targets"
})

-----------------
--  Anub'arak  --
-----------------
L = DBM:GetModLocalization("Anub'arak_Coliseum")

L:SetGeneralLocalization({
	name 					= "Anub'arak"
})

L:SetTimerLocalization({
	TimerEmerge				= "Emerge",
	TimerSubmerge			= "Submerge",
	timerAdds				= "New adds"
})

L:SetWarningLocalization({
	WarnEmerge				= "Anub'arak emerges",
	WarnEmergeSoon			= "Emerge in 10 seconds",
	WarnSubmerge			= "Anub'arak submerges",
	WarnSubmergeSoon		= "Submerge in 10 seconds",
	warnAdds				= "New adds"
})

L:SetMiscLocalization({
--	YellPull			= "This place will serve as your tomb!",
	Emerge				= "emerges from the ground!",
	Burrow				= "burrows into the ground!",
	YellBurrow			= "Auum na-l ak-k-k-k, isshhh. Rise, minions. Devour...",
	PcoldIconSet		= "PCold icon {rt%d} set on %s",
	PcoldIconRemoved	= "PCold icon removed from %s"
})

L:SetOptionLocalization({
	WarnEmerge					= "Show warning for emerge",
	WarnEmergeSoon				= "Show pre-warning for emerge",
	WarnSubmerge				= "Show warning for submerge",
	WarnSubmergeSoon			= "Show pre-warning for submerge",
	warnAdds					= "Announce new adds",
	timerAdds					= "Show timer for new adds",
	TimerEmerge					= "Show timer for emerge",
	TimerSubmerge				= "Show timer for submerge",
	AnnouncePColdIcons			= "Announce icons for $spell:66013 targets to raid chat<br/>(requires raid leader)",
	AnnouncePColdIconsRemoved	= "Also announce when icons are removed for $spell:66013<br/>(requires above option)",
	RemoveHealthBuffsInP3		= "Remove HP buffs at start of Phase 3",
	RemoveHotsBuffsInP3			= "Remove Hots after Penetrating Cold ends in Phase 3"
})