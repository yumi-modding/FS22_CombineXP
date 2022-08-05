
---@class CombineHUD
CombineHUD = {}
CombineHUD.INPUT_CONTEXT_NAME = "COMBINE_HUD"

local xpCombineHUD_mt = Class(CombineHUD)

---Creates a new instance of the CombineHUD.
---@return CombineHUD
function CombineHUD:new(mission, i18n, inputBinding, gui, modDirectory, uiFilename)
    --print("CombineHUD:new")
    local instance = setmetatable({}, xpCombineHUD_mt)

    instance.mission = mission
    instance.gui = gui
    instance.inputBinding = inputBinding
    instance.i18n = i18n
    instance.modDirectory = modDirectory
    instance.uiFilename = uiFilename
    instance.atlasRefSize = { 256, 128 }

    instance.speedMeterDisplay = mission.hud.speedMeter

    instance.tonPerHour = 0.
    instance.engineLoad = 0.
    instance.yield = 0.
    instance.gameplay = 0.

    return instance
end

function CombineHUD:delete()
    --print("CombineHUD:delete")
    if self.main ~= nil then
        self.main:delete()
    end
end

function CombineHUD:load()
    --print("CombineHUD:load")
    self.uiScale = g_gameSettings:getValue("uiScale")

    if g_languageShort == "fr" then
        self.l10nHour = "h"
    else
        self.l10nHour = string.gsub(string.gsub(g_i18n:getText("ui_hours_none"), "--:--", ""), "%s", "")
    end

    if g_seasons then
        CombineHUD.SIZE.BOX = { 190, 146 } -- 4px border correction
    else
        CombineHUD.SIZE.BOX = { 190, 110 } -- 4px border correction
    end

    self:createElements()
    self:setVehicle(nil)
end

function CombineHUD:getNormalizedUVs(uvs)
    --print("CombineHUD:getNormalizedUVs")
    return getNormalizedUVs(uvs, self.atlasRefSize)
end

function CombineHUD:scalePixelToScreenVector(vector2D)
    --print("CombineHUD:scalePixelToScreenVector")
    return self.speedMeterDisplay:scalePixelToScreenVector(vector2D)
end

function CombineHUD:scalePixelToScreenHeight(pixel)
    --print("CombineHUD:scalePixelToScreenHeight")
    return self.speedMeterDisplay:scalePixelToScreenHeight(pixel)
end

function CombineHUD:getCorrectedTextSize(size)
    --print("CombineHUD:getCorrectedTextSize")
    return size * self.uiScale
end

function CombineHUD:createElements()
    --print("CombineHUD:createElements")
    local rightX = 1 - g_safeFrameOffsetX -- right of screen.
    local bottomY = g_safeFrameOffsetY

    local boxWidth, boxHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX)
    local marginWidth, marginHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX_MARGIN)
    local paddingWidth, paddingHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX_PADDING)

    local iconWidth, iconHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.ICON)
    local iconMarginWidth, _ = self:scalePixelToScreenVector(CombineHUD.SIZE.ICON_MARGIN)
    local iconSmallWidth, iconSmallHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.ICON_SMALL)
    iconSmallWidth = iconSmallWidth * 0.6
    iconSmallHeight = iconSmallHeight * 0.6
    local iconSmallMarginWidth, _ = self:scalePixelToScreenVector(CombineHUD.SIZE.ICON_SMALL_MARGIN)

    self.main = self:createMainBox(nil, rightX - marginWidth, bottomY + marginHeight)
    self.speedMeterDisplay:addChild(self.main)

    self.base = self:createBaseBox(self.uiFilename, rightX - marginWidth, bottomY + marginHeight)
    self.main:addChild(self.base)

    local posX, posY = self.base:getPosition()
    posX = posX + paddingWidth
    posY = posY + paddingHeight

    self.iconMass = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.MASS)
    self.Mass = HUDElement.new(self.iconMass)

    self.iconSlash = self:createIcon(self.uiFilename, posX + iconMarginWidth, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.SLASH)
    self.Slash = HUDElement.new(self.iconSlash)

    posX = posX + iconSmallWidth + iconMarginWidth
    self.iconArea = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.AREA)
    self.Area = HUDElement.new(self.iconArea)

    posX = posX - iconSmallWidth - iconMarginWidth
    posY = posY + iconSmallHeight + iconMarginWidth
    self.iconEngineLoad = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.ENGINE_LOAD)
    self.EngineLoad = HUDElement.new(self.iconEngineLoad)

    posY = posY + iconSmallHeight + iconMarginWidth
    self.iconMass2 = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.MASS)
    self.Mass2 = HUDElement.new(self.iconMass2)

    self.iconSlash2 = self:createIcon(self.uiFilename, posX + iconMarginWidth, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.SLASH)
    self.Slash2 = HUDElement.new(self.iconSlash2)

    posX = posX + iconSmallWidth + iconMarginWidth
    local operatingTimeWidth, operatingTimeHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.OPERATING_TIME))
    local operatingTimeOffsetX, operatingTimeOffsetY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.OPERATING_TIME))
    self.iconHour = Overlay.new(g_baseHUDFilename, posX, posY, operatingTimeWidth, operatingTimeHeight)
    self.iconHour:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.OPERATING_TIME))
    self.Hour = HUDElement.new(self.iconHour)

    if g_seasons then
        local seasonsModDirectory = g_seasons.modDirectory
        posX = posX - iconSmallWidth - iconMarginWidth
        posY = posY + iconSmallHeight + iconMarginWidth
        self.iconMoisture = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.MOISTURE)
        self.Moisture = HUDElement.new(self.iconMoisture)
    end

    self.base:addChild(self.Mass)
    self.base:addChild(self.Slash)
    self.base:addChild(self.Area)
    self.base:addChild(self.EngineLoad)
    self.base:addChild(self.Mass2)
    self.base:addChild(self.Slash2)
    self.base:addChild(self.Hour)
    if g_seasons then
        self.base:addChild(self.Moisture)
    end
end

---Create main movable box.
function CombineHUD:createMainBox(hudAtlasPath, x, y)
    --print("CombineHUD:createMainBox")
    local boxWidth, boxHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX)
    local posX = x - boxWidth
    local boxOverlay = Overlay.new(hudAtlasPath, posX, y, boxWidth, boxHeight)
    local boxElement = HUDElement.new(boxOverlay)

    boxElement:setVisible(true)

    return boxElement
end

---Create the box with the HUD icons.
function CombineHUD:createBaseBox(hudAtlasPath, x, y)
    --print("CombineHUD:createBaseBox")
    local boxWidth, boxHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX)
    local posX = x - boxWidth
    local boxOverlay = Overlay.new(hudAtlasPath, posX, y, boxWidth, boxHeight)
    local boxElement = HUDElement.new(boxOverlay)

    boxElement:setColor(unpack(CombineHUD.COLOR.MEDIUM_GLASS))
    boxElement:setUVs(GuiUtils.getUVs(CombineHUD.UV.FILL, self.atlasRefSize))
    boxElement:setVisible(true)
    -- boxElement:setBorders("1dp 0dp 1dp 4dp", CombineHUD.COLOR.BORDER)

    return boxElement
end

function CombineHUD:createIcon(imagePath, baseX, baseY, width, height, uvs)
    --print("CombineHUD:createIcon")
    local iconOverlay = Overlay.new(imagePath, baseX, baseY, width, height)
    iconOverlay:setColor(unpack(CombineHUD.COLOR.INACTIVE))
    iconOverlay:setUVs(GuiUtils.getUVs(uvs, self.atlasRefSize))
    iconOverlay:setIsVisible(true)

    return iconOverlay
end

function CombineHUD:setVehicle(vehicle)
    --print("CombineHUD:setVehicle")
    self.vehicle = vehicle
    if self.main ~= nil then
        local hasVehicle = vehicle ~= nil

        if hasVehicle then
            -- TODO: KO
            -- if not vehicle:getIsTurnedOn() then
            --     hasVehicle = false
            -- end
        end

        self.main:setVisible(hasVehicle)
    end
end

function CombineHUD:isVehicleActive(vehicle)
    --print("CombineHUD:isVehicleActive")
    return vehicle == self.vehicle
end


---Called on mouse event.
function CombineHUD:update(dt)
    if self.vehicle ~= nil then
        local spec = self.vehicle.spec_xpCombine
        self:setData(spec.mrCombineLimiter)
    end
end

function CombineHUD:setData(mrCombineLimiter)
    --print("CombineHUD:setData")
    local tonPerHour = mrCombineLimiter.tonPerHour
    if tonPerHour ~= tonPerHour then
        tonPerHour = 0.
    end
    self.tonPerHour = tonPerHour
    local loadMultiplier = mrCombineLimiter.loadMultiplier
    if loadMultiplier ~= loadMultiplier then
        loadMultiplier = 1
    end
    self.engineLoad = 100 * mrCombineLimiter.engineLoad * loadMultiplier
    local yield = mrCombineLimiter.yield
    if yield ~= yield then
        yield = 0.
    end
    self.yield = yield
    self.gameplay = g_combinexp.powerBoost
end

function CombineHUD:drawText()
    --print("CombineHUD:drawText")

    local _, paddingHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX_PADDING)
    local iconMarginWidth, _ = self:scalePixelToScreenVector(CombineHUD.SIZE.ICON_MARGIN)
    local textMarginWidth, _ = self:scalePixelToScreenVector(CombineHUD.SIZE.TEXT_MARGIN)
    local textSize = self:scalePixelToScreenHeight(self:getCorrectedTextSize(CombineHUD.TEXT_SIZE.HIGHLIGHT))
    local _, iconSmallHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.ICON_SMALL)
    iconSmallHeight = iconSmallHeight * 0.6

    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(unpack(CombineHUD.COLOR.TEXT_WHITE))
    setTextBold(true)

    local posX, posY = self.base:getPosition()
    local textX = posX + textMarginWidth
    local textY = posY + paddingHeight + paddingHeight
    renderText(textX, textY, textSize, string.format("%.1f T/"..g_i18n:getAreaUnit(false), self.yield / g_i18n:getArea(1)))

    textY = textY + iconSmallHeight + iconMarginWidth
    if self.engineLoad > 100 and self.engineLoad <= 120 then
        setTextColor(unpack(CombineHUD.COLOR.ORANGE))
    elseif self.engineLoad > 120 then
        setTextColor(unpack(CombineHUD.COLOR.RED))
    end
    renderText(textX, textY, textSize, string.format("%.1f %%", self.engineLoad))
    setTextColor(unpack(CombineHUD.COLOR.TEXT_WHITE))

    local gameplay = string.sub(g_i18n:getText("gameplayNormal"), 1, 1) .. "                                  "
    if self.gameplay >= 100 then
        gameplay = string.sub(g_i18n:getText("gameplayArcade"), 1, 1) .. "                                  "
    elseif self.gameplay >= 20 then
        gameplay = string.sub(g_i18n:getText("gameplayNormal"), 1, 1) .. "                                  "
    elseif self.gameplay >= 0 then
        gameplay = string.sub(g_i18n:getText("gameplayRealistic"), 1, 1) .. "                                  "
    end
    renderText(textX, textY, 0.7 * textSize, gameplay)

    textY = textY + iconSmallHeight + iconMarginWidth
    renderText(textX, textY, textSize, string.format("%.1f T/"..self.l10nHour, self.tonPerHour))

    if g_seasons then
        if g_seasons.weather.cropMoistureContent then
            textY = textY + iconSmallHeight + iconMarginWidth
            renderText(textX, textY, textSize, string.format("%.1f %%", g_seasons.weather.cropMoistureContent))
        end
    end
end

CombineHUD.TEXT_SIZE = {
    HEADER = 18,
    HIGHLIGHT = 22,
    SMALL = 12
}

CombineHUD.SIZE = {
    BOX_MARGIN = { 400, -200 },
    BOX_PADDING = { 4, 4 },
    ICON = { 40, 40 },
    ICON_MARGIN = { 15, 0 },
    ICON_SMALL = { 48, 48 },
    ICON_SMALL_MARGIN = { 5, 0 },
    TEXT_MARGIN = { 182, 0 }
}

CombineHUD.UV = {
    MASS = { 0, 0, 64, 64 },
    AREA = { 64, 0, 64, 64 },
    SLASH = { 128, 0, 64, 64 },
    ENGINE_LOAD = { 192, 0, 64, 64 },
    FILL = { 0, 64, 64, 64 },
    MOISTURE = { 64, 64, 64, 64 }
}

CombineHUD.COLOR = {
    TEXT_WHITE = { 1, 1, 1, 0.75 },
    INACTIVE = { 1, 1, 1, 0.75 },
    ORANGE = { 0.718, 0.5, 0, 0.75 },
    RED = { 0.718, 0, 0, 0.75 },
    MEDIUM_GLASS = { 0.018, 0.016, 0.015, 0.8 },
}
