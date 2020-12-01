local modDirectory = g_currentModDirectory
local modName = g_currentModName

source(modDirectory .. "src/CombineXP.lua")
source(modDirectory .. "src/xpCombine.lua")
source(modDirectory .. "src/xpCutter.lua")
source(modDirectory .. "src/CombineHUD.lua")


local combinexp

local function isEnabled()
    -- Normally this code never runs if CombineXP was not active. However, in development mode
    -- this might not always hold true.
    return combinexp ~= nil
end

-- called after the map is async loaded from :load. has :loadMapData calls. NOTE: self.xmlFile is also deleted here. (Is map.xml)
local function loadedMission(mission, node)
    -- print("loadedMission(mission, superFunc, node)")
    if not isEnabled() then
        return
    end

    if mission.cancelLoading then
        return
    end

    combinexp:onMissionLoaded(mission)
end

local function load(mission)
    -- print("load(mission)")
    assert(combinexp == nil)

    combinexp = CombineXP:new(mission, g_i18n, g_inputBinding, g_gui, g_soundManager, modDirectory, modName)

    getfenv(0).g_combinexp = combinexp

    addModEventListener(combinexp)

end

local function validateVehicleTypes(vehicleTypeManager)
    -- print("validateVehicleTypes()")
    CombineXP.installSpecializations(g_vehicleTypeManager, g_specializationManager, modDirectory, modName)
end

-- Player clicked on start
local function startMission(mission)
    if not isEnabled() then return end

    combinexp:onMissionStart(mission)
end

local function unload()
    if not isEnabled() then return end

    removeModEventListener(combinexp)

    if combinexp ~= nil then
        combinexp:delete()
        combinexp = nil -- Allows garbage collecting
        getfenv(0).g_combinexp = nil
    end
end

local function init()
    -- print("init()")
    FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)
    -- FSBaseMission.loadMapFinished = Utils.prependedFunction(FSBaseMission.loadMapFinished, loadedMap)

    Mission00.load = Utils.prependedFunction(Mission00.load, load)
    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
    Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, startMission)

    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
end

init()
