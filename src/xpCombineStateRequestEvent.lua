-- Request state data from Server event (no data sent in event)
-- Thanks scfmod to point FS19_PlaceAnywhereExtendedMP as example for this scenario
-- Client => xpCombineStateRequestEvent -> Server => xpCombineStateEvent -> Client

xpCombineStateRequestEvent = {}
local xpCombineStateRequestEvent_mt = Class(xpCombineStateRequestEvent, Event)

InitEventClass(xpCombineStateRequestEvent, 'xpCombineStateRequestEvent')

function xpCombineStateRequestEvent.emptyNew()
    return Event.new(xpCombineStateRequestEvent_mt)
end

function xpCombineStateRequestEvent.new()
    return xpCombineStateRequestEvent.emptyNew()
end

function xpCombineStateRequestEvent:readStream(streamId, connection)
    self:run(connection)
end

function xpCombineStateRequestEvent:writeStream(streamId, connection)
end

---@param connection Connection
function xpCombineStateRequestEvent:run(connection)
    -- Only process event on server side
    if not connection:getIsServer() then
        connection:sendEvent(xpCombineEvent.new(g_combinexp.powerBoost, g_combinexp.powerDependantSpeed.isActive, g_combinexp.timeDependantSpeed.isActive))
    end
end
