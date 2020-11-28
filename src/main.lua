local modDirectory = g_currentModDirectory
local modName = g_currentModName

source(modDirectory .. "src/CombineXP.lua")
source(modDirectory .. "src/xpCombine.lua")
source(modDirectory .. "src/xpCutter.lua")
source(modDirectory .. "src/CombineHUD.lua")


local combinexp = nil -- localize

function isActive()
    -- Normally this code never runs if CombineXP was not active. However, in development mode
    -- this might not always hold true.
    return g_modIsLoaded["FS19_CombineXP"]
end

function init()
    -- print("init()")
    FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)
    FSBaseMission.loadMapFinished = Utils.prependedFunction(FSBaseMission.loadMapFinished, loadedMap)

    Mission00.load = Utils.prependedFunction(Mission00.load, load)
    Mission00.loadMission00Finished = Utils.overwrittenFunction(Mission00.loadMission00Finished, loadedMission)
    Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, startMission)

    VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
end

function load(mission)
    -- print("load(mission)")
    if not isActive() then return end
    assert(g_combinexp == nil)

    combinexp = CombineXP:new(mission, g_i18n, g_inputBinding, g_gui, g_soundManager, modDirectory, modName)

    getfenv(0).g_combinexp = combinexp

    addModEventListener(combinexp)

end

function validateVehicleTypes(vehicleTypeManager)
    -- print("validateVehicleTypes()")
    CombineXP.installSpecializations(g_vehicleTypeManager, g_specializationManager, modDirectory, modName)
end

-- Map object is loaded but not configured into the game
function loadedMap(mission, node)
    if not isActive() then return end
end

-- called after the map is async loaded from :load. has :loadMapData calls. NOTE: self.xmlFile is also deleted here. (Is map.xml)
function loadedMission(mission, superFunc, node)
    -- print("loadedMission(mission, superFunc, node)")
    if not isActive() then
        return superFunc(mission, node)
    end

    local function callCombineXP()
        combinexp:onMissionLoading(mission)

    end

    -- The function called for loading vehicles and items depends on the map setup and savegame setup
    -- We want to get a call out before they are called so we need to overwrite the correct one.
    if mission.missionInfo.vehiclesXMLLoad ~= nil then
        local old = mission.loadVehicles
        mission.loadVehicles = function (...)
            callCombineXP()
            old(...)
        end
    elseif mission.missionInfo.itemsXMLLoad ~= nil then
        local old = mission.loadItems
        mission.loadItems = function (...)
            callCombineXP()
            old(...)
        end
    else
        local old = mission.loadItemsFinished
        mission.loadItemsFinished = function (...)
            callCombineXP()
            old(...)
        end
    end

    superFunc(mission, node)

    if mission.cancelLoading then
        return
    end

    g_deferredLoadingManager:addTask(function()
        combinexp:onMissionLoaded(mission)
    end)
end

-- Player clicked on start
function startMission(mission)
    if not isActive() then return end

    combinexp:onMissionStart(mission)
end

function unload()
    if not isActive() then return end

    removeModEventListener(combinexp)

    if combinexp ~= nil then
        combinexp:delete()
        combinexp = nil -- Allows garbage collecting
        getfenv(0).g_combinexp = nil
    end
end

init()

function Vehicle:combinexp_getSpecTable(name)
    -- print("Vehicle:combinexp_getSpecTable("..name..")")
    local spec = self["spec_" .. modName .. "." .. name]
    if spec ~= nil then
        return spec
    end

    return self["spec_" .. name]
end

function Vehicle:combinexp_getModName()
    return modName
end
