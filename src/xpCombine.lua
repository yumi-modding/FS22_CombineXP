xpCombine = {};

xpCombine.debug = false --true --
xpCombine.myCurrentModDirectory = g_currentModDirectory;
xpCombine.modSettingsDir = g_modSettingsDirectory
xpCombine.modName = g_currentModName

xpCombine.powerBoostArcade = 100;   -- 100% power boost
xpCombine.powerBoostNormal = 20;    -- 20% power boost (default on FS19)
xpCombine.powerBoostRealistic = 0;  -- No power boost

-- @TEST:
-- [x] Start threshing without cutter
-- [x] Start threshing with cutter attached
-- [x] Start threshing with cutter attached & activated
-- [x] Start threshing with combine folded
-- [x] Start threshing with cutter folded
-- [x] Start Worker without cutter
-- [x] Start Worker with cutter attached
-- [x] Start Worker with cutter attached & activated
-- [x] Start Worker with combine folded
-- [x] Start Worker with cutter folded
-- [x] Try harvesting with cutter deactivated
-- [x] Harvesting at 5am
-- [x] Manual attach compatibility
-- [/] Waiting worker compatibility
-- [ ] Try other Combine type vehicles
-- [x]  - sugarBeet
-- [x]  - maize
-- [x]  - potatoe
-- [x]  - cotton
-- [ ]  - vine
-- [ ]  - attachable combine
-- [x] Edit settings

-- [x] Open settings in quickhelp disappear after 1st use
-- [x] In hosted MP, setting not working on client
-- [ ] Update mod preview

-- [x] Move xpCombine.mrCombineLimiter.powerBoost to g_combinexp + impacts
-- [x] Check if Event is needed for MP/Dedi Settings
-- [x] Set all settings in Event if needed
-- [x] Move settings to Game settings instead of General (initGameSettingsGui)
-- [x] Manage load/save settings
-- [x] Client retrieves server settings when joining a game

function xpCombine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Combine, specializations)
end

function xpCombine.registerFunctions(vehicleType)
    if xpCombine.debug then print("xpCombine:registerFunctions") end
    SpecializationUtil.registerFunction(vehicleType, "getTimeDependantSpeed", xpCombine.getTimeDependantSpeed)
end

function xpCombine.registerOverwrittenFunctions(vehicleType)
    if xpCombine.debug then print("xpCombine:registerOverwrittenFunctions") end
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addCutterArea", xpCombine.addCutterArea)
    -- SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", xpCombine.getCanBeTurnedOn)  -- Error if used
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "startThreshing", xpCombine.startThreshing)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "stopThreshing", xpCombine.stopThreshing)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "verifyCombine", xpCombine.verifyCombine)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeActionEvents", xpCombine.removeActionEvents)
end

function xpCombine.registerEventListeners(vehicleType)
    if xpCombine.debug then print("xpCombine:registerEventListeners") end
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", xpCombine)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", xpCombine)
end

-- Load basePerf and initialize data
function xpCombine:onLoad(savegame)
    if xpCombine.debug then print("xpCombine:onLoad") end
    self.spec_xpCombine = self[("spec_%s.xpCombine"):format(xpCombine.modName)]
    local spec = self.spec_xpCombine

    local basePerf = 0.    --basePerf=max Ha per Hour wanted in 100% fertilized Wheat

    -- First load from data xmlFile
    if xpCombine.myCurrentModDirectory then
        local xmlFile = nil

        if xpCombine.myCurrentModDirectory then
            local xmlFilePath = xpCombine.modSettingsDir.."/combineXP.xml"
            if fileExists(xmlFilePath) then
                xmlFile = loadXMLFile("combineXP", xmlFilePath);
            else
                xmlFile = loadXMLFile("combineXP", xpCombine.myCurrentModDirectory .. "data/combineXP.xml");
            end
        end

        local i = 0
        local xmlVehicleName = ""
        local xmlPath = ""
        while hasXMLProperty(xmlFile, "combineXP"..string.format(".vehicles.vehicle(%d)", i)) do
            xmlPath = "combineXP"..string.format(".vehicles.vehicle(%d)", i)
            xmlVehicleName = getXMLString(xmlFile, xmlPath.."#xmlPath")
            --> ==Manage DLC & mods thanks to dural==
            --replace $pdlcdir by the full path
            if string.sub(xmlVehicleName, 1, 8):lower() == "$pdlcdir" then
              --xmlVehicleName = getUserProfileAppPath() .. "pdlc/" .. string.sub(xmlVehicleName, 10)
              --required for steam users
              xmlVehicleName = NetworkUtil.convertFromNetworkFilename(xmlVehicleName)
            elseif string.sub(xmlVehicleName, 1, 7):lower() == "$moddir" then
              xmlVehicleName = NetworkUtil.convertFromNetworkFilename(xmlVehicleName)
            end
            --< ======================================
           if xpCombine.debug then print(self.configFileName.." - "..xmlVehicleName) end
            if self.configFileName == xmlVehicleName then
              basePerf = tonumber(getXMLString(xmlFile, xmlPath.."#basePerf"))
              break
            end
            i = i + 1
        end
    end

    if basePerf <= 0 then
    -- Then motorConfiguration hp
        local vehicleName = self:getFullName()
        local coef = 1 -- It was 1.5 on FS19, but 1 seems OK
        local keyCategory = "vehicle.storeData.category"
        local category = self.xmlFile:getValue(keyCategory)
        if category == "forageHarvesters" or category == "forageHarvesterCutters" then
            coef = 6.
        elseif category == "beetVehicles" or category == "beetHarvesting" then
            coef = 0.6
		elseif category == "potatoVehicles" then
            coef = 0.3
        end
        local key, motorId = ConfigurationUtil.getXMLConfigurationKey(self.xmlFile, self.configurations.motor, "vehicle.motorized.motorConfigurations.motorConfiguration", "vehicle.motorized", "motor")
        local fallbackConfigKey = "vehicle.motorized.motorConfigurations.motorConfiguration(0)"
        local fallbackOldKey = "vehicle"
        local power = nil
        if SpecializationUtil.hasSpecialization(Motorized, self.specializations) then
            power = ConfigurationUtil.getConfigurationValue(self.xmlFile, key, "", "#hp", nil, fallbackConfigKey, fallbackOldKey)
        end
        if power ~= nil and tonumber(power) > 0 then
            -- print("key "..key)
            -- print("motorId "..motorId)
            -- print("power "..power)
            basePerf = tonumber(power) * coef
            print("Combine basePerf computed for "..vehicleName.. " from motorConfiguration hp: "..tostring(power).." => "..tostring(basePerf))
        else
        -- Then specs power
            key = "vehicle.storeData.specs.power"
            local specsPower = self.xmlFile:getValue(key)
            if specsPower ~= nil and tonumber(specsPower) > 0 then
                basePerf = tonumber(specsPower) * coef
                print("Combine basePerf computed for "..vehicleName.. " from specs power declared in store: "..tostring(specsPower).." => "..tostring(basePerf))
            else
            -- Then specs neededPower
                key = "vehicle.storeData.specs.neededPower"
                local specsNeededPower = self.xmlFile:getValue(key)
                if specsNeededPower ~= nil and tonumber(specsNeededPower) > 0 then
                    basePerf = tonumber(specsNeededPower) * coef
                    print("Combine basePerf computed for "..vehicleName.. " from specs needed power declared in store: "..tostring(specsNeededPower).." => "..tostring(basePerf))
                end
            end
        end
    end

    spec.mrCombineLimiter = {};
    spec.mrCombineLimiter.totaldistance = 0;
    spec.mrCombineLimiter.totalArea = 0;
    spec.mrCombineLimiter.avgTime = 1500; --1.5s
    spec.mrCombineLimiter.distanceForMeasuring = 3; -- 3 meters
    spec.mrCombineLimiter.currentTime = 0;
    spec.mrCombineLimiter.basePerfAvgArea = basePerf / 36; -- m2 per second (fully fertilized)
    spec.mrCombineLimiter.currentAvgArea = 0;

    spec.mrCombineLimiter.totalOutputMass = 0.
    spec.mrCombineLimiter.tonPerHour = 0.
    spec.mrCombineLimiter.engineLoad = 0.
    spec.mrCombineLimiter.loadMultiplier = 1.
    spec.mrCombineLimiter.yield = 0.
    spec.mrCombineLimiter.highMoisture = false

    spec.mrCombineLastTotalPower = 0;

    spec.mrIsCombineSpeedLimitActive = false;

    spec.lastRealArea = 0.
    spec.lastMultiplier = 1

    local spec_powerConsumer = self.spec_powerConsumer
    if spec_powerConsumer then
        -- Set default values to powerConsumer to rev up when starting threshing and overloading
        if spec_powerConsumer.neededMaxPtoPower == nil then
            spec_powerConsumer.neededMaxPtoPower =  10
        end
        if spec_powerConsumer.ptoRpm == nil then
            spec_powerConsumer.ptoRpm = 350
        end
    end

    spec.dirtyFlag = self:getNextDirtyFlag()
end

-- NEVER CALLED since no power computation yet
function xpCombine:getConsumedPtoTorque(superfunc)
    if xpCombine.debug then print("xpCombine:getConsumedPtoTorque") end

    local spec = self.spec_xpCombine
    if self.getIsTurnedOn ~= nil and self:getIsTurnedOn() then

        if totalAreaDependantPtoPower>0 and spec.mrCombineLimiter.currentAvgArea>0 then
            local areaValue = spec.mrCombineLimiter.currentAvgArea; --relative m2 per second (relative to fertilizer state and crop type)
            if areaValue>spec.mrCombineLimiter.basePerfAvgArea then
                areaValue = spec.mrCombineLimiter.basePerfAvgArea + (areaValue-spec.mrCombineLimiter.basePerfAvgArea)^0.8; --smooth power requirement above "maxAvgArea" to avoid "stalling" the engine too often when entering the field too fast while combining
            end
            if Vehicle.debugRendering then self.mrDebugCombineLastAreaDependantPtoPower = totalAreaDependantPtoPower * 0.1 * areaValue end
        end
    end
end

---Called on read stream.
function xpCombine:onReadStream(streamId, connection)
    local spec = self.spec_xpCombine
    -- self:setSowingData(allowSound, allowFertilizer, true)
    spec.mrCombineLimiter.tonPerHour = streamReadFloat32(streamId)
    spec.mrCombineLimiter.engineLoad = streamReadFloat32(streamId)
    spec.mrCombineLimiter.loadMultiplier = streamReadFloat32(streamId)
    spec.mrCombineLimiter.yield = streamReadFloat32(streamId)
    spec.mrCombineLimiter.highMoisture = streamReadBool(streamId)
end

---Called on write stream.
function xpCombine:onWriteStream(streamId, connection)
    local spec = self.spec_xpCombine
    streamWriteFloat32(streamId, spec.mrCombineLimiter.tonPerHour)
    streamWriteFloat32(streamId, spec.mrCombineLimiter.engineLoad)
    streamWriteFloat32(streamId, spec.mrCombineLimiter.loadMultiplier)
    streamWriteFloat32(streamId, spec.mrCombineLimiter.yield)
    streamWriteBool(streamId, spec.mrCombineLimiter.highMoisture)
end

---Called on read update stream.
function xpCombine:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        local spec = self.spec_xpCombine

        if streamReadBool(streamId) then
            spec.mrCombineLimiter.tonPerHour = streamReadFloat32(streamId)
            spec.mrCombineLimiter.engineLoad = streamReadFloat32(streamId)
            spec.mrCombineLimiter.loadMultiplier = streamReadFloat32(streamId)
            spec.mrCombineLimiter.yield = streamReadFloat32(streamId)
            spec.mrCombineLimiter.highMoisture = streamReadBool(streamId)
        end
    end
end

---Called on write update stream.
function xpCombine:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_xpCombine

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, spec.mrCombineLimiter.tonPerHour)
            streamWriteFloat32(streamId, spec.mrCombineLimiter.engineLoad)
            streamWriteFloat32(streamId, spec.mrCombineLimiter.loadMultiplier)
            streamWriteFloat32(streamId, spec.mrCombineLimiter.yield)
            streamWriteBool(streamId, spec.mrCombineLimiter.highMoisture)
        end
    end
end

-- Compute totaldistance
function xpCombine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- if xpCombine.debug then print("xpCombine:onUpdate") end
    local spec = self.spec_xpCombine

    if self.isServer and self.getIsTurnedOn ~= nil and self:getIsTurnedOn() then
        --update total move distance
        spec.mrCombineLimiter.totaldistance = spec.mrCombineLimiter.totaldistance + self.lastMovedDistance;

        if spec.mrCombineLimiter.currentAvgArea > 0 then
            local areaValue = spec.mrCombineLimiter.currentAvgArea; --relative m2 per second (relative to fertilizer state and crop type)
            if areaValue > spec.mrCombineLimiter.basePerfAvgArea then
                areaValue = spec.mrCombineLimiter.basePerfAvgArea + (areaValue-spec.mrCombineLimiter.basePerfAvgArea)^0.8; --smooth power requirement above "maxAvgArea" to avoid "stalling" the engine too often when entering the field too fast while combining
            end
            if Vehicle.debugRendering then self.mrDebugCombineLastAreaDependantPtoPower = totalAreaDependantPtoPower * 0.1 * areaValue end
        end

    end
    if xpCombine.debug then
        local turnedOnPtoPower = 0.
        local speedDependantPtoPowerWhenFilling = 0.
        local chopperPtoPower = 0.
        local areaDependantPtoPower = 0.
        local tonPerHour = Utils.getNoNil(spec.mrCombineLimiter.tonPerHour, 0.)
        -- spec.speedLimit = Utils.getNoNil(spec.speedLimit, spec.mrGenuineSpeedLimit)

        local str = string.format(" turnedOnPtoPower=%.1f\n speedDependantPtoPowerWhenFilling=%.1f\n chopperPtoPower=%.1f\n areaDependantPtoPower=%.1f\n lastTotalPower=%.1f\n Current Speed Limit=%.1f\n Base Perf=%.0f/Current perf= %.0f\n Ton per Hour=%.1f", turnedOnPtoPower, speedDependantPtoPowerWhenFilling, chopperPtoPower, areaDependantPtoPower, spec.mrCombineLastTotalPower, spec.speedLimit, spec.mrCombineLimiter.basePerfAvgArea*36,spec.mrCombineLimiter.currentAvgArea*36, tonPerHour);
        -- renderText(0.74, 0.75, getCorrectTextSize(0.02), str);
        -- print("totalDistance "..tostring(spec.mrCombineLimiter.totaldistance))
    end
end

-- Compute speedLimit, yield and engine load based on materialQty
function xpCombine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- if xpCombine.debug then print("xpCombine:onUpdateTick") end
    local spec = self.spec_xpCombine
    local spec_combine = self.spec_combine

    if self.isServer then
        spec.mrIsCombineSpeedLimitActive = false;
        -- if self:getIsTurnedOn() and self.movingDirection~=-1 then -- and (self:isLowered(true) or self.cutterAllowCuttingWhileRaised) then    --20170427 - check lower/raise state too (especially useful for combine with cutter embedded
        local cutterIsTurnedOn = false
        for cutter,_ in pairs(spec_combine.attachedCutters) do
            if cutter.spec_cutter then
                local spec_cutter = cutter.spec_cutter
                cutterIsTurnedOn = self.movingDirection == spec_cutter.movingDirection and self:getLastSpeed() > 0.5 and (spec_cutter.allowCuttingWhileRaised or cutter:getIsLowered(true))
            end
        end

        if self:getIsTurnedOn() and self.movingDirection~=-1 and cutterIsTurnedOn then
            --monitor avg every Xs
            -- print("lastArea: "..tostring(spec_combine.lastArea))
            spec.mrCombineLimiter.totalArea = spec.mrCombineLimiter.totalArea + spec.lastRealArea;
            spec.mrCombineLimiter.currentTime = spec.mrCombineLimiter.currentTime + dt; --ms
            spec.mrIsCombineSpeedLimitActive = true;

            --20170606 - measure once a given distance has been driven/harvested
            --we want to avoid the combine to reach "high" speed before the limiter has a chance to measure the current AvgArea
            --if we rely only on the time (1.5s between each sample in our case), and we assume the combine actually start harvesting something when the 1st measure is done, the avgarea would be very low and so = no limit, then, during the next 1.5s, the combine can reach "high speed" greater than 10kph, and at 10kph, the combine drive more than 4m between each sample
            --if spec.mrCombineLimiter.currentTime>spec.mrCombineLimiter.avgTime then
            if spec.mrCombineLimiter.currentTime>spec.mrCombineLimiter.avgTime or spec.mrCombineLimiter.totaldistance>spec.mrCombineLimiter.distanceForMeasuring then
                local materialFx = 1;
                if spec_combine.lastValidInputFruitType ~= FruitType.UNKNOWN then
                    local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(spec_combine.lastValidInputFruitType)
                    -- DebugUtil.printTableRecursively(fruitDesc, " ", 1, 2);
                    if fruitDesc.mrMaterialQtyFx then materialFx = fruitDesc.mrMaterialQtyFx end
                    -- print("fruit " .. tostring(spec_combine.lastValidInputFruitType) .. " - " .. tostring(fruitDesc.mrMaterialQtyFx))

                    -- yield: field 30 15834 m²
                    -- - wheat:    0%     50%    100%   100%+Plow  100%+Plow+Lime
                    ---------------------------------------------------------------------
                    --             16910  20433  23956  26070      28184             L
                    --             13.18  15.94  18.69  20.33      21.98             T
                    --              8.32  10.06  11.80  12.83      13.88             T/ha
                    -- - barley
                    ---------------------------------------------------------------------
                    --             18240                           30401             L
                    --             12.40                           20.67             T
                    --              7.83                          13.05             T/ha
                    -- - corn
                    ---------------------------------------------------------------------
                    --             17480                           29134             L
                    --             13.98                           23.31             T
                    --              8.83                           14.72             T/ha

        -- if Vehicle.debugRendering then
                    local equivalentSqmPerHour = 3600000 * spec.mrCombineLimiter.totalArea * g_currentMission:getFruitPixelsToSqm() / spec.mrCombineLimiter.currentTime --actually, this is not the real hectare because it is scaled by the fruit converter or fertilizer factor
                    --take into account "self.threshingScale" ???
                    local fillType = spec_combine.lastCuttersOutputFillType
                    local desc = g_fillTypeManager:getFillTypeByIndex(fillType)
                    local massPerLiter = desc.massPerLiter
                    spec.mrCombineLimiter.tonPerHour = equivalentSqmPerHour * fruitDesc.literPerSqm * massPerLiter
                    local yield = spec.lastMultiplier * spec.mrCombineLimiter.totalOutputMass / MathUtil.areaToHa(spec.mrCombineLimiter.totalArea, g_currentMission:getFruitPixelsToSqm())
                    spec.mrCombineLimiter.yield = yield + (0.02 * yield * math.random(-1, 1))
                    spec.mrCombineLimiter.engineLoad = spec.mrCombineLimiter.currentAvgArea / spec.mrCombineLimiter.basePerfAvgArea
        -- end

                end

                -- str = tostring(spec.lastMultiplier).." - "..tostring(spec.mrCombineLimiter.totalArea).." - "..tostring(g_currentMission:getFruitPixelsToSqm()).." - "..tostring(spec.mrCombineLimiter.currentTime)
                -- print(str)
                -- 588 = 1000 / 1.7 since max yield = 1.7 base yield when fertilized
                local avgArea = 500 * spec.mrCombineLimiter.totalArea * materialFx * g_currentMission:getFruitPixelsToSqm() / spec.mrCombineLimiter.currentTime; -- m2 per second (takes into account fertilizer state and so, since our reference capacity is with full yield, we have to multiply by 0.5
                local avgSpeed = 1000 * spec.mrCombineLimiter.totaldistance / spec.mrCombineLimiter.currentTime; --m/s
                -- print("avgArea: "..tostring(avgArea).." - ".."avgSpeed: "..tostring(avgSpeed))
                --20170606 - check the current increase "acceleration" for the avgArea
                local areaAcc = (avgArea - spec.mrCombineLimiter.currentAvgArea)/spec.mrCombineLimiter.currentTime

                -- local str = string.format(" currentAvgArea=%.1f\n basePerfAvgArea=%.1f\n avgArea=%.1f\n avgSpeed=%.1f\n areaAcc=%.3f", spec.mrCombineLimiter.currentAvgArea, spec.mrCombineLimiter.basePerfAvgArea, avgArea, avgSpeed, areaAcc);
                -- print(str)

                if spec.mrCombineLimiter.currentAvgArea>(0.75*spec.mrCombineLimiter.basePerfAvgArea) then
                    avgArea = 0.5 * spec.mrCombineLimiter.currentAvgArea + 0.5 * avgArea; --small smooth
                end

                spec.mrCombineLimiter.currentAvgArea = avgArea;

                if avgArea==0 then
                    spec.speedLimit = spec.mrGenuineSpeedLimit;
                else

                    --local maxAvgArea = spec.mrCombineLimiter.powerBoost * spec.mrCombineLimiter.basePerfAvgArea;
                    local maxAvgArea = (1 + 0.01 * g_combinexp.powerBoost) * spec.mrCombineLimiter.basePerfAvgArea;
                    local predictLimitSet = false
                    --take into account the areaAcc
                    if areaAcc>0 then
                        --predict in 3s
                        local predictAvgArea = avgArea + areaAcc*3000
                        if xpCombine.debug then print("predictAvgArea="..tostring(predictAvgArea) .. " - new speedLimit="..tostring(spec.speedLimit)) end
                        if predictAvgArea>1.5*maxAvgArea then
                            spec.speedLimit = math.max(2, math.min(0.95*spec.speedLimit, 0.9*avgSpeed*3.6))
                            predictLimitSet = true
                            if xpCombine.debug then print("set speedLimit "..tostring(spec.speedLimit)) end
                            --print("predictAvgArea="..tostring(predictAvgArea) .. " - new speedLimit="..tostring(spec.speedLimit))
                        end
                    end

                    if not predictLimitSet then
                        if avgArea>(1.05*maxAvgArea) then
                            --reduce speedlimit
                            spec.speedLimit = math.max(2, math.min(spec.speedLimit, avgSpeed*3.6) - 10 * (1 - avgArea/maxAvgArea)^2); --0.1kph step --allow 5% margin to avoid "yo-yo" effect
                            if xpCombine.debug then print("reduce speedlimit "..tostring(spec.speedLimit)) end
                        -- elseif (3.6*avgSpeed)>spec.speedLimit and avgArea<maxAvgArea then -- not limited by the engine, nor by the combine capacity
                        elseif avgArea<maxAvgArea then -- not limited by the engine, nor by the combine capacity
                            --increase speedlimit
                            spec.speedLimit = math.min(spec.mrGenuineSpeedLimit, spec.speedLimit + 0.1 * (maxAvgArea / avgArea)^3);
                            if xpCombine.debug then print("increase speedlimit "..tostring(spec.speedLimit)) end
                        end
                    end
                end

                --reset for next avg
                spec.mrCombineLimiter.currentTime = 0;
                spec.mrCombineLimiter.totalArea = 0;
                spec.mrCombineLimiter.totaldistance = 0;
                spec.mrCombineLimiter.totalOutputMass = 0;
                spec.lastRealArea = 0;
                spec.lastMultiplier = 1;
            end

        else
            spec.speedLimit = spec.mrGenuineSpeedLimit;
            spec.mrCombineLimiter.currentAvgArea = 0;   
            --self.mrAvgCombineCuttersArea = 0;
            spec.mrCombineLimiter.tonPerHour = 0
        end
        self:raiseDirtyFlags(spec.dirtyFlag)
    end

end

-- Adjust harvesting speedLimit based on several criterias
function xpCombine:getSpeedLimit(superfunc, onlyIfWorking)
    -- if xpCombine.debug then print("xpCombine:getSpeedLimit: "..tostring(g_combinexp.powerBoost).." - "..tostring(g_combinexp.powerDependantSpeed.isActive).." - "..tostring(g_combinexp.timeDependantSpeed.isActive)) end
    local spec_combine = self.spec_combine
    local spec_aiVehicle = self.spec_aiVehicle
    local spec_xpCombine = self.spec_xpCombine
    local limit, doCheckSpeedLimit = superfunc(self, onlyIfWorking)
    -- print(self:getFullName().." "..tostring(limit))
    if spec_xpCombine then
        local isTurnedOn = self:getIsTurnedOn()
        if isTurnedOn then
            if g_combinexp.powerDependantSpeed.isActive then
                spec_xpCombine.mrGenuineSpeedLimit = 1.5 * limit
                if spec_xpCombine.speedLimit and spec_xpCombine.speedLimit > 0 then
                    limit = spec_xpCombine.speedLimit
                    -- if xpCombine.debug then print("speedLimit from materialQty: "..tostring(limit)) end
                end
            else
                spec_xpCombine.mrGenuineSpeedLimit = limit
            end
            spec_xpCombine.mrCombineLimiter.highMoisture = false
            local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(self:getFillUnitFillType(spec_combine.fillUnitIndex))
            if limit < math.huge and fruitType ~= nil and fruitType ~= FruitType.UNKNOWN and not spec_combine.allowThreshingDuringRain then
                local loadLimit = limit
                -- print("speedLimit                 : "..tostring(limit))
                if g_seasons and g_seasons.weather.cropMoistureContent and g_combinexp.moistureDependantSpeed.isActive then
                    limit = xpCombine:getMoistureDependantSpeed(fruitType, loadLimit)
                    spec_xpCombine.mrCombineLimiter.loadMultiplier = loadLimit / limit
                    -- print("speedLimit from Moisture   : "..tostring(limit))
                    -- print("loadLimit / limit          : "..tostring(loadLimit / limit))
                else
                    if g_combinexp.timeDependantSpeed.isActive then
                        limit = xpCombine:getTimeDependantSpeed(fruitType, loadLimit)
                        spec_xpCombine.mrCombineLimiter.loadMultiplier = loadLimit / limit
                        -- Add warning msg if moisture is high to harvest (depending on time of the day)
                        spec_xpCombine.mrCombineLimiter.highMoisture = (loadLimit / limit) > 4
                        -- print("speedLimit from Time       : "..tostring(limit))
                        -- print("loadLimit / limit          : "..tostring(loadLimit / limit))
                    end
                end
            end
        end
    end
    return limit, doCheckSpeedLimit
end
Vehicle.getSpeedLimit = Utils.overwrittenFunction(Vehicle.getSpeedLimit, xpCombine.getSpeedLimit)

-- Reduce speedLimit based on moisture given by Seasons and fruitType
function xpCombine:getMoistureDependantSpeed(fruitType, defaultSpeedLimit)
    -- if xpCombine.debug then print("xpCombine:getTimeDependantSpeed") end
    local speed = defaultSpeedLimit
    if fruitType == FruitType.WHEAT or
        fruitType == FruitType.BARLEY or
        fruitType == FruitType.OAT or
        fruitType == FruitType.CANOLA or
        fruitType == FruitType.SOYBEAN or
        fruitType == FruitType.SUNFLOWER or
        fruitType == FruitType.MAIZE then
        local time = g_seasons.weather.cropMoistureContent
        speed = g_combinexp.moistureDependantSpeed.default:get(time)
    else
        speed = 10
    end
    return defaultSpeedLimit * 0.1 * speed
end

-- Reduce speedLimit based on time of the day and fruitType
function xpCombine:getTimeDependantSpeed(fruitType, defaultSpeedLimit)
    -- if xpCombine.debug then print("xpCombine:getTimeDependantSpeed") end
    local speed = defaultSpeedLimit
    local time = g_currentMission.environment.currentHour + g_currentMission.environment.currentMinute / 60

    if fruitType == FruitType.WHEAT or
        fruitType == FruitType.BARLEY or
        fruitType == FruitType.OAT or
        fruitType == FruitType.CANOLA or
        fruitType == FruitType.SOYBEAN or
        fruitType == FruitType.SUNFLOWER then
        speed = g_combinexp.timeDependantSpeed.cereal:get(time)
    elseif fruitType == FruitType.MAIZE then
        speed = g_combinexp.timeDependantSpeed.maize:get(time)
    else
        speed = 10
    end
    return defaultSpeedLimit * 0.1 * speed
end

-- Compute totalOutputMass needed for yield computation
function xpCombine:addCutterArea(superfunc, area, realArea, inputFruitType, outputFillType, strawRatio, strawGroundType, farmId, cutterLoad)
    local spec = self.spec_xpCombine

    local ret = superfunc(self, area, realArea, inputFruitType, outputFillType, strawRatio, strawGroundType, farmId, cutterLoad)

    spec.lastRealArea = realArea
    -- if xpCombine.debug then print("area: "..tostring(area).." - realArea: "..tostring(realArea)) end
    if outputFillType ~= FillType.UNKNOWN then
        local desc = g_fillTypeManager:getFillTypeByIndex(outputFillType)
        spec.mrCombineLimiter.totalOutputMass = spec.mrCombineLimiter.totalOutputMass + ret * desc.massPerLiter
    end
    return ret
end

-- Enable to turn on Combine without cutter attached
function xpCombine:getCanBeTurnedOn(superfunc, superFunc)
    -- if xpCombine.debug then print("xpCombine:getCanBeTurnedOn") end
    local spec_combine = self.spec_combine

    if spec_combine.numAttachedCutters <= 0 then
        return superFunc(self)
    end

    for cutter, _ in pairs(spec_combine.attachedCutters) do
        if cutter ~= self and cutter.getCanBeTurnedOn ~= nil and not cutter:getCanBeTurnedOn() then
            return false
        end
    end

    return superFunc(self)
end
Combine.getCanBeTurnedOn = Utils.overwrittenFunction(Combine.getCanBeTurnedOn, xpCombine.getCanBeTurnedOn)

-- Prevent cutter to start and move down when starting the combine threshing
function xpCombine:startThreshing(superfunc)
    if xpCombine.debug then print("xpCombine:startThreshing") end
    local spec_combine = self.spec_combine

    local isAIActive = self:getIsAIActive()
    if spec_combine.numAttachedCutters > 0 and isAIActive then
        -- Only start cutter if threshing started by AI
        local allowLowering = not self:getIsAIActive() or not self.rootVehicle:getAIFieldWorkerIsTurning()

        for _, cutter in pairs(spec_combine.attachedCutters) do
            if allowLowering and cutter ~= self then
                local jointDescIndex = self:getAttacherJointIndexFromObject(cutter)

                self:setJointMoveDown(jointDescIndex, true, true)
            end

            cutter:setIsTurnedOn(true, true)
        end
    end

    if spec_combine.threshingStartAnimation ~= nil and self.playAnimation ~= nil then
        self:playAnimation(spec_combine.threshingStartAnimation, spec_combine.threshingStartAnimationSpeedScale, self:getAnimationTime(spec_combine.threshingStartAnimation), true)
    end

    if self.isClient then
        g_soundManager:stopSample(spec_combine.samples.stop)
        g_soundManager:stopSample(spec_combine.samples.work)
        g_soundManager:playSample(spec_combine.samples.start)
        g_soundManager:playSample(spec_combine.samples.work, 0, spec_combine.samples.start)
    end

    SpecializationUtil.raiseEvent(self, "onStartThreshing")
end

-- Prevent cutter to stop and move up when stoping the combine threshing
function xpCombine:stopThreshing(superfunc)
    if xpCombine.debug then print("xpCombine:stopThreshing") end
    local spec_combine = self.spec_combine

    if self.isClient then
        g_soundManager:stopSample(spec_combine.samples.start)
        g_soundManager:stopSample(spec_combine.samples.work)
        g_soundManager:playSample(spec_combine.samples.stop)
    end

    self:setCombineIsFilling(false, false, true)

    -- for cutter, _ in pairs(spec_combine.attachedCutters) do
    --     if cutter ~= self then
    --         local jointDescIndex = self:getAttacherJointIndexFromObject(cutter)

    --         self:setJointMoveDown(jointDescIndex, false, true)
    --     end

    --     cutter:setIsTurnedOn(false, true)
    -- end

    if spec_combine.threshingStartAnimation ~= nil and spec_combine.playAnimation ~= nil then
        self:playAnimation(spec_combine.threshingStartAnimation, -spec_combine.threshingStartAnimationSpeedScale, self:getAnimationTime(spec_combine.threshingStartAnimation), true)
    end

    SpecializationUtil.raiseEvent(self, "onStopThreshing")
end

-- Display warning when trying to harvest with threshing off + HUD values
function xpCombine:onDraw(superFunc, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- if xpCombine.debug then print("xpCombine:onDraw") end
    local spec = self.spec_xpCombine
    local spec_combine = self.spec_combine
    local spec_aiVehicle = self.spec_aiVehicle
    -- if spec_aiVehicle and spec_aiVehicle.getIsAIActive and spec_aiVehicle:getIsAIActive() then
    --     return
    -- end
    if spec and self:getIsTurnedOn() then
        local hud = g_combinexp.hud
        hud:setVehicle(self)
        hud:drawText()
        if g_combinexp.timeDependantSpeed.isActive and spec.mrCombineLimiter.highMoisture then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_highMoistureAtThisTime"), 2000)
        end
    else
        if spec_combine.numAttachedCutters > 0 then
            local cutterIsTurnedOn = false
            for _, cutter in pairs(spec_combine.attachedCutters) do
                if cutter.getIsTurnedOn ~= nil and cutter:getIsTurnedOn() then
                    local spec_cutter = cutter.spec_cutter
                    local isEffectActive = self.movingDirection == spec_cutter.movingDirection and self:getLastSpeed() > 0.5 and (spec_cutter.allowCuttingWhileRaised or cutter:getIsLowered(true))
                    cutterIsTurnedOn = isEffectActive
                    break
                end
            end
            if cutterIsTurnedOn then
                g_currentMission:showBlinkingWarning(g_i18n:getText("warning_firstStartThreshing"), 2000)
            end
        end
    end
end

-- Disable harvesting if combine threshing is off
function xpCombine:verifyCombine(superFunc, fruitType, outputFillType)
    -- if xpCombine.debug then print("xpCombine:verifyCombine") end
    local isAIActive = self:getIsAIActive()
    if not self:getIsTurnedOn() and not isAIActive then
        return nil
    end
    return superFunc(self, fruitType, outputFillType)
end

-- Combine with at least <powerConsumer ptoRpm="350" neededMaxPtoPower="10"/> will consume power when unloading
function xpCombine:getConsumingLoad(superFunc)
    if xpCombine.debug then print("xpCombine:getConsumingLoad") end
    local value, count = superFunc(self)
    local totalPower = 0
    if self.spec_dischargeable ~= nil and self.spec_dischargeable.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
        totalPower = totalPower + 10 --self.xpCombineUnloadingAugerPtoPower;
    end
    totalPower = totalPower / 56.5487;        --540*math.pi/30 = 56.5487

    return value + totalPower, count + 1
end
-- Combine.getConsumingLoad = Utils.overwrittenFunction(Combine.getConsumingLoad, xpCombine.getConsumingLoad)

function xpCombine:removeActionEvents(superFunc, ...)
    if xpCombine.debug then print("xpCombine:removeActionEvents") end
    local hud = g_combinexp.hud
    -- TODO: Will hide hud also for a worker
    -- print("isAIActive "..tostring(self:getIsAIActive()))
    if hud:isVehicleActive(self) then
        hud:setVehicle(nil)
    end

    return superFunc(self, ...)
end

function xpCombine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if xpCombine.debug then print("xpCombine:onRegisterActionEvents") end
    if self.isClient then
        if isActiveForInputIgnoreSelection then
            --TODO: add if active ?
            local hud = g_combinexp.hud
            hud:setVehicle(self)
        end
    end
end
