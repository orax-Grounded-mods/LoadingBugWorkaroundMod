local UEHelpers = require("UEHelpers")

local modInfo = (function()
  local info = debug.getinfo(2, "S")
  local source = info.source:gsub("\\", "/")
  return {
    name = source:match("@?.+/Mods/([^/]+)"),
    file = source:sub(2),
    currentDirectory = source:match("@?(.+)/"),
    currentModDirectory = source:match("@?(.+/Mods/[^/]+)"),
    modsDirectory = source:match("@?(.+/Mods)/")
  }
end)()

---@type LoadingBugWorkaroundMod_Options
local Options = dofile(string.format("%s/options.lua", modInfo.currentModDirectory))

local IsLoadingSave = false

local function load()
  print("[LoadingBugWorkaroundMod] Loading save...")

  local SurvivalGameplayStatics = StaticFindObject("/Script/Maine.Default__SurvivalGameplayStatics")
  if not SurvivalGameplayStatics:IsValid() then
    return
  end ---@cast SurvivalGameplayStatics USurvivalGameplayStatics

  local SaveLoadManager = SurvivalGameplayStatics:GetSaveLoadManager(UEHelpers.GetWorldContextObject())
  local QuickLoadSaveData = SaveLoadManager.QuickLoadSaveData

  if QuickLoadSaveData:IsValid() then
    SaveLoadManager:Load(QuickLoadSaveData)
  end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, ...)
  IsLoadingSave = false
end)

NotifyOnNewObject("/Script/Engine.PlayerController", function()
  local SurvivalGameplayStatics = StaticFindObject("/Script/Maine.Default__SurvivalGameplayStatics")
  if not SurvivalGameplayStatics:IsValid() then
    return
  end ---@cast SurvivalGameplayStatics USurvivalGameplayStatics

  local SaveLoadManager = SurvivalGameplayStatics:GetSaveLoadManager(UEHelpers.GetWorldContextObject())
  local loadFromSave = SaveLoadManager:DidLoadFromSaveGame()

  if loadFromSave then
    IsLoadingSave = true
  else
    IsLoadingSave = false
  end

  ExecuteWithDelay(Options.wait, function()
    if IsLoadingSave then
      IsLoadingSave = false
      load()
    end
  end)
end)
