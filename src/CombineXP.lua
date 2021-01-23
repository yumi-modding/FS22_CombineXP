
CombineXP = {};

modDirectory = g_currentModDirectory
local CombineXP_mt = Class(CombineXP)

function CombineXP:new(mission, i18n, inputBinding, gui, soundManager, modDirectory, modName)
    --print("CombineXP:new")
    local self = setmetatable({}, CombineXP_mt)

    self.isServer = mission:getIsServer()
    self.isClient = mission:getIsClient()
    self.modDirectory = modDirectory
    self.modName = modName

    self.mission = mission

    local uiFilename = Utils.getFilename("resources/combineXP.dds", modDirectory)
    self.hud = CombineHUD:new(mission, i18n, inputBinding, gui, modDirectory, uiFilename)

    self.powerDependantSpeed = {}
    self.timeDependantSpeed = {}
    self.moistureDependantSpeed = {}

    return self
end

function CombineXP:delete()
    --print("CombineXP:delete")
    self.hud:delete()
end


function CombineXP:loadMaterialQtyFx()
    --print("CombineXP:loadMaterialQtyFx")
    local xmlFile = nil

    if modDirectory then
        xmlFile = loadXMLFile("realFruitTypesXML", modDirectory .. "data/fruitTypes.xml");
    end

    local i = 0;
    while xmlFile do
        local fruitTypeName = string.format("fruitTypes.fruitType(%d)", i);
        if not hasXMLProperty(xmlFile, fruitTypeName) then break; end;

        local realFruitType = {};
        realFruitType.name = getXMLString(xmlFile, fruitTypeName .. "#name");
        if realFruitType.name == nil then
            print("RealisticUtilsGP.loadRealFruitTypesData " .. "realFruitType.name is nil, i="..tostring(i));
            break;
        end;
        realFruitType.literPerSqm = getXMLFloat(xmlFile, fruitTypeName .. "#literPerSqm");
        --if realFruitType.literPerSqm == nil then
        --  RealisticUtilsGP.printWarning("RealisticUtilsGP.loadRealFruitTypesData", "realFruitType.literPerSqm is nil, i="..tostring(i), true);
        --  break;
        --end;
        realFruitType.seedUsagePerSqm = getXMLFloat(xmlFile, fruitTypeName .. "#seedUsagePerSqm");
        --if realFruitType.seedUsagePerSqm == nil then
        --  RealisticUtilsGP.printWarning("RealisticUtilsGP.loadRealFruitTypesData", "realFruitType.seedUsagePerSqm is nil, i="..tostring(i), true);
        --  break;
        --end;
        realFruitType.windrowLiterPerSqm = getXMLFloat(xmlFile, fruitTypeName .. "#windrowLiterPerSqm");

        realFruitType.mrMaterialQtyFx = Utils.getNoNil(getXMLFloat(xmlFile, fruitTypeName .. "#mrMaterialQtyFx"), 1);

        for _, v in pairs(g_currentMission.fruitTypeManager.fruitTypes) do
            if realFruitType.name:lower() == v.name:lower() then
                v.mrMaterialQtyFx = realFruitType.mrMaterialQtyFx
            end
        end

        i = i + 1;
    end

    if xmlFile then
        delete(xmlFile);
    end

end

function CombineXP:loadDependantSpeed()
    --print("CombineXP:loadDependantSpeed")
    local xmlFile = nil

    if modDirectory then
        local modSettingsDir = modDirectory .. "../../modsSettings"
        local xmlFilePath = modSettingsDir.."/combineXP.xml"
        if fileExists(xmlFilePath) then
            xmlFile = loadXMLFile("combineXP", xmlFilePath);
        else
            xmlFile = loadXMLFile("combineXP", modDirectory .. "data/combineXP.xml");
        end
    end
    if xmlFile then
        g_combinexp.powerDependantSpeed.isActive = Utils.getNoNil(getXMLBool(xmlFile, "combineXP.powerDependantSpeed" .. string.format("#isActive")), true)
        g_combinexp.timeDependantSpeed.isActive = Utils.getNoNil(getXMLBool(xmlFile, "combineXP.timeDependantSpeed" .. string.format("#isActive")), true)
        g_combinexp.timeDependantSpeed.cereal = AnimCurve:new(linearInterpolator1)
        g_combinexp.timeDependantSpeed.cereal:loadCurveFromXML(xmlFile, "combineXP.timeDependantSpeed.cereal", loadInterpolator1Curve)
        g_combinexp.timeDependantSpeed.maize = AnimCurve:new(linearInterpolator1)
        g_combinexp.timeDependantSpeed.maize:loadCurveFromXML(xmlFile, "combineXP.timeDependantSpeed.maize", loadInterpolator1Curve)
        g_combinexp.moistureDependantSpeed.isActive = Utils.getNoNil(getXMLBool(xmlFile, "combineXP.moistureDependantSpeed" .. string.format("#isActive")), true)
        g_combinexp.moistureDependantSpeed.default = AnimCurve:new(linearInterpolator1)
        g_combinexp.moistureDependantSpeed.default:loadCurveFromXML(xmlFile, "combineXP.moistureDependantSpeed.default", loadInterpolator1Curve)
        delete(xmlFile);
    end

end

-- @doc Copy default parameters from mod zip file to modsSettings directory so end-user can edit it
function CombineXP:copyCombineXPXML()
    if modDirectory then
        local modSettingsDir = modDirectory .. "../../modsSettings"
        local xmlFilePath = modSettingsDir.."/combineXP.xml"
        local xmlFile;
        if not fileExists(xmlFilePath) then
            local xmlSourceFilePath = modDirectory .. "/data/combineXP.xml"
            local xmlSourceFile;
            if fileExists(xmlSourceFilePath) then
            xmlSourceFile = loadXMLFile('combineXP', xmlSourceFilePath);
            createFolder(modSettingsDir)
            saveXMLFileTo(xmlSourceFile, xmlFilePath);
            end
        end
    end
end

---Called when the player clicks the Start button
function CombineXP:onMissionStart(mission)
    -- print("CombineXP:onMissionStart")

    CombineXP.copyCombineXPXML()
    CombineXP.loadMaterialQtyFx()
    CombineXP.loadDependantSpeed()

end

------------------------------------------------
--- Events from mission
------------------------------------------------
-- Mission is loading
function CombineXP:onMissionLoading()
    -- print("CombineXP:onMissionLoading")

end

---Mission was loaded (without vehicles and items)
function CombineXP:onMissionLoaded(mission)
    -- print("CombineXP:onMissionLoaded")
    self.hud:load()
end

function CombineXP:update(dt)
    self.hud:update(dt)
end

function CombineXP.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
    specializationManager:addSpecialization("xpCombine", "xpCombine", Utils.getFilename("src/xpCombine.lua", modDirectory), nil)

    for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
        if SpecializationUtil.hasSpecialization(Combine, typeEntry.specializations) then
            vehicleTypeManager:addSpecialization(typeName, modName .. ".xpCombine")
        end
    end
end
