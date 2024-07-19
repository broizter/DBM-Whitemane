local AceTimer                      = LibStub("AceTimer-3.0")
local Kal                           = DBM:GetModByName("Kal")
local L                             = Kal:GetLocalizedStrings()
local BossHealth                    = DBM.BossHealth
local PLAYER_NAME                   = UnitName("player")
local CREATURE_IDS                  = {
  DRAGON = 24850,
  DEMON = 24892,
}
local SYNC_PREFIXES                 = {
  HP_SENDER = "KalecgosHealthUpdateSender",
  HP_UPDATE = "KalecgosHealthUpdateUpdate",
}
local ROSTER_UPDATE_DELAY           = 1.5
local HP_SENDER_NAMES_SORT_DELAY    = 1.5
local HEALTH_SYNC_DISPATCH_INTERVAL = 0.5

local function createInitialState()
  Kal.customState = Kal.customState or {}
  local state = Kal.customState

  state.health = {
    [CREATURE_IDS.DRAGON] = -1,
    [CREATURE_IDS.DEMON] = -1,
  }
  state.healthSenderNames = {
    [PLAYER_NAME] = true,
  }
  state.sortedHealthSenderNames = {
    PLAYER_NAME
  }
  state.roster = {}
  state.isSortScheduled = false
  state.isRosterUpdateScheduled = false

  if state.ticker then
    AceTimer:CancelTimer(state.ticker)
    state.ticker = nil
  end
end

createInitialState()

local state = Kal.customState

local function getDragonHealth()
  return state.health[CREATURE_IDS.DRAGON]
end

local function getDemonHealth()
  return state.health[CREATURE_IDS.DEMON]
end

local function compareStrings(a, b)
  return a < b
end

local function sortHealthSenderNames()
  state.isSortScheduled = false
  state.sortedHealthSenderNames = {}

  for unitName, _ in pairs(state.healthSenderNames) do
    table.insert(state.sortedHealthSenderNames, unitName)
  end

  table.sort(
    state.sortedHealthSenderNames,
    compareStrings
  )
end

local function updateRoster()
  state.isRosterUpdateScheduled = false
  state.roster = {}

  for i = 1, GetNumGroupMembers() do
    local unitID = "raid" .. i
    local unitName = UnitName(unitID)

    if unitName then
      state.roster[unitID] = unitName
      state.roster[unitName] = unitID
    end
  end
end

local function pushHealthSync(creatureID)
  Kal:SendSync(
    SYNC_PREFIXES.HP_UPDATE,
    creatureID,
    UnitHealth("target"),
    UnitHealthMax("target")
  )
end

local function pushHealthUpdateSenderSync()
  Kal:SendSync(SYNC_PREFIXES.HP_SENDER, PLAYER_NAME)
end

local function initHealthSync()
  local firstPlayerWithDragonTarget = nil
  local firstPlayerWithDemonTarget = nil

  local sortedHealthSenderNames = state.sortedHealthSenderNames
  local roster = state.roster

  for i = 1, #sortedHealthSenderNames do
    local raidUnitName = sortedHealthSenderNames[i]
    local raidUnitID = roster[raidUnitName]

    if raidUnitID then
      local raidUnitTargetID = raidUnitID .. "target"
      local raidUnitTargetName = UnitName(raidUnitTargetID)

      local isTargetDragon = raidUnitTargetName == L.name
      local isTargetDemon = raidUnitTargetName == L.Demon

      if isTargetDragon and not firstPlayerWithDragonTarget then
        firstPlayerWithDragonTarget = raidUnitName
      end

      if isTargetDemon and not firstPlayerWithDemonTarget then
        firstPlayerWithDemonTarget = raidUnitName
      end

      if firstPlayerWithDragonTarget and firstPlayerWithDemonTarget then
        break
      end
    end
  end

  if firstPlayerWithDragonTarget == PLAYER_NAME then
    pushHealthSync(CREATURE_IDS.DRAGON)
  end

  if firstPlayerWithDemonTarget == PLAYER_NAME then
    pushHealthSync(CREATURE_IDS.DEMON)
  end
end

local onCombatStart = Kal.OnCombatStart
function Kal:OnCombatStart(...)
  onCombatStart(self, ...)

  if not self.Options.HealthFrame then
    return
  end

  BossHealth:Clear()
  BossHealth:AddBoss(getDragonHealth, L.name)
  BossHealth:AddBoss(getDemonHealth, L.Demon)
  updateRoster()
  pushHealthUpdateSenderSync()

  if not state.ticker then
    state.ticker = AceTimer:ScheduleRepeatingTimer(
      initHealthSync,
      HEALTH_SYNC_DISPATCH_INTERVAL
    )
  end
end

local onCombatEnd = Kal.OnCombatEnd
function Kal:OnCombatEnd(...)
  onCombatEnd(self, ...)
  createInitialState()
end

function Kal:RAID_ROSTER_UPDATE()
  if state.isRosterUpdateScheduled then
    return
  end

  state.isRosterUpdateScheduled = true

  DBM:Schedule(ROSTER_UPDATE_DELAY, updateRoster)
end

function Kal:OnSync(prefix, message)
  if prefix == SYNC_PREFIXES.HP_SENDER then
    if state.healthSenderNames[message] then
      return
    end

    state.healthSenderNames[message] = true

    if state.isSortScheduled then
      return
    end

    state.isSortScheduled = true

    DBM:Schedule(HP_SENDER_NAMES_SORT_DELAY, sortHealthSenderNames)
  end

  if prefix == SYNC_PREFIXES.HP_UPDATE then
    local creatureID, currentHealth, maxHealth = strsplit("\t", message)
    local value

    if not creatureID or not currentHealth or not maxHealth then
      return
    end

    currentHealth = tonumber(currentHealth)
    maxHealth = tonumber(maxHealth)
    creatureID = tonumber(creatureID)

    if currentHealth == 0 then
      value = currentHealth
    else
      value = math.ceil(currentHealth / maxHealth * 1000) / 10
    end

    state.health[creatureID] = value
  end
end
