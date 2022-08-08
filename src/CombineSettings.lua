
---@class CombineSettings
CombineSettings = {}

CombineSettings.debug = false --true --
local xpCombineSettings_mt = Class(CombineSettings)

---Creates a new instance of the CombineSettings.
---@return CombineSettings
function CombineSettings:new(modTitle)
    if CombineSettings.debug then print("CombineSettings:new") end
    local instance = setmetatable({}, xpCombineSettings_mt)

    CombineSettings.modTitle = modTitle

    return instance
end

function CombineSettings:delete()
    if CombineSettings.debug then print("CombineSettings:delete") end
    if self.main ~= nil then
        self.main:delete()
    end
end

function CombineSettings:load()
    if CombineSettings.debug then print("CombineSettings:load") end

    -- SaveSettings
    FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, CombineSettings.saveSettings)

    -- Game Settings Menu
    InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, CombineSettings.initGameSettingsGui)

    -- General Settings Menu
    -- InGameMenuGeneralSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.onFrameOpen, CombineSettings.initGeneralSettingsGui)
    -- if g_server == nil then
    --     InGameMenuGeneralSettingsFrame.onFrameClose = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.onFrameClose, CombineSettings.saveCfg)
    -- end
end

function CombineSettings:initGameSettingsGui()
    if CombineSettings.debug then print("CombineSettings:initGameSettingsGui") end
    if self.combineGameplay == nil then
        --- Create Gameplay Element
        self.combineGameplay = self.checkTraffic:clone()

        self.combineGameplay.target = false
        self.combineGameplay.id = "combineGameplay"
        self.combineGameplay.onClickCallback = CombineSettings.onSettingsStateChanged
        self.combineGameplay.texts[1] = g_i18n:getText("gameplayArcade")
        self.combineGameplay.texts[2] = g_i18n:getText("gameplayNormal")
        self.combineGameplay.texts[3] = g_i18n:getText("gameplayRealistic")

        local settingTitle = self.combineGameplay.elements[4]
        local toolTip = self.combineGameplay.elements[6]

        settingTitle:setText(g_i18n:getText('combineGameplaySetting'))
        toolTip:setText(g_i18n:getText('combineGameplayTooltip'))
        
        local gameplay = 1
        if g_combinexp.powerBoost == xpCombine.powerBoostNormal then
            gameplay = 2
        elseif g_combinexp.powerBoost == xpCombine.powerBoostRealistic then
            gameplay = 3
        end
        self.combineGameplay:setState(gameplay)

        --- Create PowerSetting Element
        self.combinePower = self.combineGameplay:clone()
        self.combinePower.target = false
        self.combinePower.id = "combinePower"
        self.combinePower.onClickCallback = CombineSettings.onSettingsStateChanged
        self.combinePower.texts[1] = g_i18n:getText("ui_off")
        self.combinePower.texts[2] = g_i18n:getText("ui_on")

        settingTitle = self.combinePower.elements[4]
        toolTip = self.combinePower.elements[6]

        settingTitle:setText(g_i18n:getText('combinePowerSetting'))
        toolTip:setText(g_i18n:getText('combinePowerTooltip'))

        self.combinePower:setIsChecked(g_combinexp.powerDependantSpeed.isActive)

        --- Create Daytime Setting Element
        self.combineDaytime = self.combinePower:clone()
        self.combineDaytime.target = false
        self.combineDaytime.id = "combineDaytime"
        self.combineDaytime.onClickCallback = CombineSettings.onSettingsStateChanged
        self.combineDaytime.texts[1] = g_i18n:getText("ui_off")
        self.combineDaytime.texts[2] = g_i18n:getText("ui_on")

        settingTitle = self.combineDaytime.elements[4]
        toolTip = self.combineDaytime.elements[6]

        settingTitle:setText(g_i18n:getText('combineDaytimeSetting'))
        toolTip:setText(g_i18n:getText('combineDaytimeTooltip'))

        self.combineDaytime:setIsChecked(g_combinexp.timeDependantSpeed.isActive)

        --- Create Menu Elements
        local title = TextElement.new()
        title:applyProfile("settingsMenuSubtitle", true)
        title:setText(CombineSettings.modTitle)

        self.boxLayout:addElement(title)
        self.boxLayout:addElement(self.combineGameplay)
        self.boxLayout:addElement(self.combinePower)
        self.boxLayout:addElement(self.combineDaytime)
        self.boxLayout:invalidateLayout()
    end
end

function CombineSettings:saveSettings()
    if CombineSettings.debug then print("CombineSettings:saveSettings") end
    -- First load from data xmlFile
    if xpCombine.myCurrentModDirectory then
        local xmlFile = nil
        if xpCombine.myCurrentModDirectory then
            local modSettingsDir = getUserProfileAppPath().."modSettings"
            local xmlFilePath = modSettingsDir.."/combineXP.xml"
            if fileExists(xmlFilePath) then
                xmlFile = XMLFile.load("combineXP", xmlFilePath);
            else
                xmlFile = XMLFile.load("combineXP", xpCombine.myCurrentModDirectory .. "data/combineXP.xml");
            end
            xmlFile:setInt("combineXP.vehicles"..string.format("#powerBoost"), g_combinexp.powerBoost)
            xmlFile:setBool("combineXP.powerDependantSpeed" .. string.format("#isActive"), g_combinexp.powerDependantSpeed.isActive)
            xmlFile:setBool("combineXP.timeDependantSpeed" .. string.format("#isActive"), g_combinexp.timeDependantSpeed.isActive)
            xmlFile:save()
        end
    end
end

function CombineSettings:onSettingsStateChanged(state, element, isChangedUp)
    if CombineSettings.debug then print("CombineSettings:onSettingsStateChanged") end

    if element.id == "combineGameplay" then
        if CombineSettings.debug then print("Gameplay state: " .. tostring(state)) end
        if state == 1 then
            g_combinexp.powerBoost = xpCombine.powerBoostArcade
        elseif state == 2 then
            g_combinexp.powerBoost = xpCombine.powerBoostNormal
        elseif state == 3 then
            g_combinexp.powerBoost = xpCombine.powerBoostRealistic
        end
    end
    if element.id == "combinePower" then
        if CombineSettings.debug then print("Power state: " .. tostring(state)) end
        g_combinexp.powerDependantSpeed.isActive = element:getIsChecked()
    end
    if element.id == "combineDaytime" then
        if CombineSettings.debug then print("Daytime state: " .. tostring(state)) end
        g_combinexp.timeDependantSpeed.isActive = element:getIsChecked()
    end
    g_client:getServerConnection():sendEvent(xpCombineEvent.new(g_combinexp.powerBoost, g_combinexp.powerDependantSpeed.isActive, g_combinexp.timeDependantSpeed.isActive))
end
