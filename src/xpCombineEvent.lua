xpCombineEvent = {}
local xpCombineEvent_mt = Class(xpCombineEvent, Event)

xpCombineEvent.debug = false --true --

InitEventClass(xpCombineEvent, "xpCombineEvent")

function xpCombineEvent.emptyNew()
    if xpCombineEvent.debug then print("xpCombineEvent:emptyNew") end
	local self = Event.new(xpCombineEvent_mt)
	return self
end

function xpCombineEvent.new(powerBoost, powerDependantSpeedActive, timeDependantSpeedActive)
    if xpCombineEvent.debug then print("xpCombineEvent:new") end
	local self = xpCombineEvent.emptyNew()

    self.powerBoost = powerBoost
    self.powerDependantSpeedActive = powerDependantSpeedActive
    self.timeDependantSpeedActive = timeDependantSpeedActive

	return self
end

function xpCombineEvent:writeStream(streamId, connection)
    if xpCombineEvent.debug then print("xpCombineEvent:writeStream") end
    streamWriteUInt8(streamId, self.powerBoost)
    streamWriteBool(streamId, self.powerDependantSpeedActive)
    streamWriteBool(streamId, self.timeDependantSpeedActive)
end

function xpCombineEvent:readStream(streamId, connection)
    if xpCombineEvent.debug then print("xpCombineEvent:readStream") end
    self.powerBoost = streamReadUInt8(streamId)
    self.powerDependantSpeedActive = streamReadBool(streamId)
    self.timeDependantSpeedActive = streamReadBool(streamId)
	self:run(connection)
end

function xpCombineEvent:run(connection)
    if xpCombineEvent.debug then print("xpCombineEvent:run") end
	if not connection:getIsServer() then
		-- local senderUserId = g_currentMission.userManager:getUserIdByConnection(connection)
		-- local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
		-- local isMasterUser = connection:getIsLocal() or g_currentMission.userManager:getIsConnectionMasterUser(connection)

        g_server:broadcastEvent(self, false, connection)
	end
    g_combinexp.powerBoost = self.powerBoost
    g_combinexp.powerDependantSpeed.isActive = self.powerDependantSpeedActive
    g_combinexp.timeDependantSpeed.isActive = self.timeDependantSpeedActive
end

function xpCombineEvent.sendEvent(powerBoost, power, daytime, noEventSend)
    if xpCombineEvent.debug then print("xpCombineEvent:sendEvent") end
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(xpCombineEvent:new(powerBoost, power, daytime), nil, nil)
        else
            g_client:getServerConnection():sendEvent(xpCombineEvent:new(powerBoost, powerDependantSpeedActive, timeDependantSpeedActive))
        end
    end
end
