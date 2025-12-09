-- this is a stub for OSI's mechanic and ground icons
-- TODO: create a translator for callbacks between OSI and Lib3DObjects
local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

OSI = OSI or {}
local OSICompatibleIcon = lib.OSICompatibleIcon
local mechanicIcons = {}

--------------------------------
------- utility functions ------
--------------------------------

--- returns the standard icon size for OSI Compatible Icons
--- @return number the icon size
function OSI.GetIconSize()
    return 100
end
--- prints the player's current world position to the chat
function OSI.PrintMyPosition()
    local zone, wX, wY, wZ = GetUnitRawWorldPosition( "player" )
    d( "|cffffff[L3DO - OSI Compatibility Layer]|r x=" .. wX .. " y=" .. wY .. " z=" .. wZ .. " zone=" .. zone )
end

--------------------------------
-------- position icons --------
--------------------------------

--- creates a OSI compatible position icon
--- @param x number the x coordinate
--- @param y number the y coordinate
--- @param z number the z coordinate
--- @param texture string the texture path for the icon
--- @param size number the size of the icon
--- @param color table the color of the icon
--- @param offset number the vertical offset of the icon
--- @param callback function a callback function to be called on icon update
--- @return OSICompatibleIcon the created position icon
function OSI.CreatePositionIcon(x, y, z, texture, size, color, offset, callback)
    local icon = OSICompatibleIcon:New(texture, size, color, offset, callback)
    icon.x, icon.y, icon.z = x, y, z
    icon:SetPosition(x, y, z)

    return icon
end

--- discards position icon
--- @param icon OSICompatibleIcon the icon to discard
function OSI.DiscardPositionIcon(icon)
    icon:Destroy()
end

--------------------------------
-------- mechanic icons --------
--------------------------------

--- sets mechanic icon for unit
--- @param displayName string the display name of the unit
--- @param texture string the texture path for the icon
--- @param size number the size of the icon
--- @param color table the color of the icon
--- @param offset number the vertical offset of the icon
--- @param callback function a callback function to be called on icon update
function OSI.SetMechanicIconForUnit(displayName, texture, size, color, offset, callback)
    displayName = string.lower(displayName)

    if mechanicIcons[displayName] then
        mechanicIcons[displayName]:Destroy()
        mechanicIcons[displayName] = nil
    end

    local icon = OSICompatibleIcon:New(texture, size, color, offset, callback)
    icon.data.displayName = displayName
    icon:MoveToUnitWithDisplayName(displayName)

    mechanicIcons[displayName] = icon
end

--- removes mechanic icon for unit
--- @param displayName string the display name of the unit
function OSI.RemoveMechanicIconForUnit(displayName)
    displayName = string.lower(displayName)
    if mechanicIcons[displayName] then
        mechanicIcons[displayName]:Destroy()
        mechanicIcons[displayName] = nil
    end
end

--- resets mechanic icons
function OSI.ResetMechanicIcons()
    for displayName, marker in pairs(mechanicIcons) do
        marker:Destroy()
        mechanicIcons[displayName] = nil
    end
end

--- gets icon currently assigned to player
--- @param displayName string the display name of the unit
--- @return OSICompatibleIcon|nil the mechanic icon assigned to the unit, or nil if none
function OSI.GetIconForPlayer(displayName)
    return mechanicIcons[string.lower(displayName)]
end

--------------------------------
-------- stub functions --------
--------------------------------

--function OSI.GetPositionIcons()
--    return {}
--end
--function OSI.GetIconForCompanion()
--    return nil
--end
--function OSI.UpdateIconData(icon, texture, color, hodor)
--    if texture then icon:SetTexture(texture) end
--    if color then icon:SetColor(color) end
--    if hodor then d("Setting hodor icons is not supported in Lib3DObjects OSI Compatibility layer") end
--end
--function OSI.CreateIconPool()
--    -- no pool needed in this implementation
--end
--function OSI.ResetIcons()
--    OSI.ResetMechanicIcons()
--end