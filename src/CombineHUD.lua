
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
    instance.atlasRefSize = { 1280, 256 }

    instance.speedMeterDisplay = mission.hud.speedMeter

    instance.yield = 0.

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
    self.uiScale = self:getUIScale()

    self:createElements()
    self:setVehicle(nil)
end

function CombineHUD:getNormalizedUVs(uvs)
    --print("CombineHUD:getNormalizedUVs")
    return getNormalizedUVs(uvs, self.atlasRefSize)
end

function CombineHUD:getUIScale()
    --print("CombineHUD:getUIScale")
    return self.speedMeterDisplay.uiScale
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

    self.main = self:createMainBox(nil, rightX - marginWidth, bottomY - marginHeight)
    self.speedMeterDisplay:addChild(self.main)

    self.base = self:createBaseBox(self.uiFilename, rightX - marginWidth, bottomY - marginHeight)
    self.main:addChild(self.base)

    local posX, posY = self.base:getPosition()
    posX = posX + paddingWidth
    posY = posY + paddingHeight

    local textSize = self:getCorrectedTextSize(CombineHUD.TEXT_SIZE.SMALL)


    self.iconMass = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.MASS)
    self.Mass = HUDElement:new(self.iconMass)

    self.iconSlash = self:createIcon(self.uiFilename, posX + iconMarginWidth, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.SLASH)
    self.Slash = HUDElement:new(self.iconSlash)

    posX = posX + iconSmallWidth + iconMarginWidth
    self.iconArea = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.AREA)
    self.Area = HUDElement:new(self.iconArea)

    posX = posX - iconSmallWidth - iconMarginWidth
    posY = posY + iconSmallHeight + iconMarginWidth
    self.iconEngineLoad = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.ENGINE_LOAD)
    self.EngineLoad = HUDElement:new(self.iconEngineLoad)

    posY = posY + iconSmallHeight + iconMarginWidth
    self.iconMass2 = self:createIcon(self.uiFilename, posX, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.MASS)
    self.Mass2 = HUDElement:new(self.iconMass2)

    self.iconSlash2 = self:createIcon(self.uiFilename, posX + iconMarginWidth, posY, iconSmallWidth, iconSmallHeight, CombineHUD.UV.SLASH)
    self.Slash2 = HUDElement:new(self.iconSlash2)

    posX = posX + iconSmallWidth + iconMarginWidth
    local operatingTimeWidth, operatingTimeHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.OPERATING_TIME))
    local operatingTimeOffsetX, operatingTimeOffsetY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.OPERATING_TIME))
    self.iconHour = Overlay:new(g_baseHUDFilename, posX, posY, operatingTimeWidth, operatingTimeHeight)
    self.iconHour:setUVs(getNormalizedUVs(SpeedMeterDisplay.UV.OPERATING_TIME))
    self.Hour = HUDElement:new(self.iconHour)


    self.base:addChild(self.Mass)
    self.base:addChild(self.Slash)
    self.base:addChild(self.Area)
    self.base:addChild(self.EngineLoad)
    self.base:addChild(self.Mass2)
    self.base:addChild(self.Slash2)
    self.base:addChild(self.Hour)

end

---Create main movable box.
function CombineHUD:createMainBox(hudAtlasPath, x, y)
    --print("CombineHUD:createMainBox")
    local boxWidth, boxHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX)
    local posX = x - boxWidth
    local boxOverlay = Overlay:new(hudAtlasPath, posX, y, boxWidth, boxHeight)
    local boxElement = HUDElement:new(boxOverlay)

    boxElement:setVisible(true)

    return boxElement
end

---Create the box with the HUD icons.
function CombineHUD:createBaseBox(hudAtlasPath, x, y)
    --print("CombineHUD:createBaseBox")
    local boxWidth, boxHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX)
    local posX = x - boxWidth
    local boxOverlay = Overlay:new(hudAtlasPath, posX, y, boxWidth, boxHeight)
    local boxElement = HUDElement:new(boxOverlay)

    boxElement:setColor(unpack(CombineHUD.COLOR.MEDIUM_GLASS))
    boxElement:setUVs(self:getNormalizedUVs(CombineHUD.UV.FILL))
    boxElement:setVisible(true)
    -- boxElement:setBorders("1dp 0dp 1dp 4dp", CombineHUD.COLOR.BORDER)

    return boxElement
end

function CombineHUD:createIcon(imagePath, baseX, baseY, width, height, uvs)
    --print("CombineHUD:createIcon")
    local iconOverlay = Overlay:new(imagePath, baseX, baseY, width, height)
    iconOverlay:setColor(unpack(CombineHUD.COLOR.INACTIVE))
    iconOverlay:setUVs(self:getNormalizedUVs(uvs))
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

-- NEVER CALLED
function CombineHUD:draw()
    --print("CombineHUD:draw")
    local paddingWidth, paddingHeight = self:scalePixelToScreenVector(CombineHUD.SIZE.BOX_PADDING)

    local iconSmallMarginWidth, _ = self:scalePixelToScreenVector(CombineHUD.SIZE.ICON_SMALL_MARGIN)
    local posX, posY = self.base:getPosition()
    posY = posY + paddingHeight
    local textX = posX + iconSmallMarginWidth
    local textY = posY
    local textSize = self:getCorrectedTextSize(CombineHUD.TEXT_SIZE.SMALL)

    setTextAlignment(RenderText.ALIGN_RIGHT);
    setTextColor(unpack(CombineHUD.COLOR.TEXT_WHITE));
    renderText(textX, textY, textSize, string.format("%.1f", 100 * self.yield))

end

CombineHUD.TEXT_SIZE = {
    HEADER = 18,
    HIGHLIGHT = 22,
    SMALL = 12
}

CombineHUD.SIZE = {
    BOX = { 190, 110 }, -- 4px border correction
    BOX_MARGIN = { 400, 400 },
    BOX_PADDING = { 4, 4 },
    ICON = { 40, 40 },
    ICON_MARGIN = { 15, 0 },
    ICON_SMALL = { 48, 48 },
    ICON_SMALL_MARGIN = { 5, 0 }
}

CombineHUD.UV = {
    MASS = { 0, 0, 256, 256 },
    AREA = { 256, 0, 256, 256 },
    SLASH = { 512, 0, 256, 256 },
    ENGINE_LOAD = { 768, 0, 256, 256 },
    FILL = { 1024, 0, 256, 256 }
}

CombineHUD.COLOR = {
    TEXT = { 0, 0, 0, 1 },
    TEXT_WHITE = { 1, 1, 1, 0.75 },
    INACTIVE = { 1, 1, 1, 0.75 },
    ACTIVE = { 0.9910, 0.3865, 0.0100, 1 },
    BORDER = { 0.718, 0.716, 0.715, 0.25 },
    RED = { 0.718, 0, 0, 0.75 },
    DARK_GLASS = { 0.018, 0.016, 0.015, 0.9 },
    MEDIUM_GLASS = { 0.018, 0.016, 0.015, 0.8 },
}
