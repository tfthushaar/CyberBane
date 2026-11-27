-- Cyberbane: "Join my crew" on a Night City Allies companion who is with you.
--
-- They become one of your crew in Cyberbane, called, kitted and ranked there like the rest, and leave this squad in the
-- same moment, so the two mods never have the same person out at once. Needs Cyberbane 2.8.2 or later; without it the
-- choice never shows.

local function crewDoor()
    local container = Game.GetScriptableSystemsContainer()
    if container == nil then
        return nil
    end
    return container:Get("CBCrewDoor")
end

local function join(npc)
    local door = crewDoor()
    if door == nil then
        return
    end
    -- The look they wear now, or the outfit picked for them here when they have no body yet.
    local look = npc:GetSelectedAppearance()
    local body = npc:GetEntity()
    if body ~= nil then
        look = body:GetCurrentAppearanceName()
    end
    local id = door:Join(npc:GetRecordID(), look, npc:GetName(), CName.new("NightCityAllies"), npc:GetFriendship())
    if id > 0 then
        npc:Dismiss()
    end
end

-- Built each time the menu opens, so the words follow Cyberbane's language and the choice shows only when they can come.
return function(npc)
    local door = crewDoor()
    if door == nil or npc == nil or not npc:IsSquad() or npc:IsMech() or npc:IsDrone() then
        return {}
    end
    if not door:CanJoin(npc:GetRecordID()) then
        return {}
    end
    return {
        {
            label = door:JoinLabel(),
            icon = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.HandshakeIcon"),
            type = gameinteractionsChoiceType.Blueline,
            callback = function(who)
                join(who)
            end
        }
    }
end
