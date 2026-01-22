


--[[ doc.lua begin ]]
--- @class Lib3DObjects
--- @field name string
--- @field version string
--- @field author string
--- @field AUTOROTATE_NONE number
--- @field AUTOROTATE_CAMERA number
--- @field AUTOROTATE_PLAYER_HEADING number
--- @field AUTOROTATE_PLAYER_POSITION number
--- @field AUTOROTATE_GROUND number
local lib = {
    name = "Lib3DObjects",
    version = "dev",
    author = "@m00nyONE",
    core = {
        ObjectPoolManager = {},
        ObjectGroupManager = {},
    },
    renderer = {},
    util = {},

    AUTOROTATE_NONE = 1, -- manual mode
    AUTOROTATE_CAMERA = 2, -- always face camera
    AUTOROTATE_PLAYER_HEADING = 3, -- always face player heading direction
    AUTOROTATE_PLAYER_POSITION = 4, -- always face player
    AUTOROTATE_GROUND = 5, -- always align to ground normal

    PRIORITY_IGNORE = -1,
    PRIORITY_DEFAULT = 0,
    PRIORITY_LOW = 1,
    PRIORITY_MEDIUM = 2,
    PRIORITY_HIGH = 3,
    PRIORITY_MECHANIC = 999,
}
local lib_name = lib.name
local lib_author = lib.author
local lib_version = lib.version
_G[lib_name] = lib

local EM = GetEventManager()

local svName = "Lib3DObjectsSavedVars"
local svVersion = 1
local svDefault = {
    debug = false,
    updateInterval = 0, -- every frame
}


--[[ doc.lua end ]]
local function initialize()
    lib.core.sw = ZO_SavedVars:NewAccountWide(svName, svVersion, nil, svDefault)

    lib.core.InitializeCameraHelper()
    --SetShouldRenderWorld(false)
end

EM:RegisterForEvent(lib_name, EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= lib_name then return end

    EM:UnregisterForEvent(lib_name, EVENT_ADD_ON_LOADED)
    initialize()
end)

SLASH_COMMANDS["/l3do"] = function(str)
    if str == "version" then
        d(string.format("%s by %s, version %s", lib_name, lib_author, lib_version))
    elseif str == "axis" then
        local _ = lib.examples.createAxis(500)
        d("Created axis markers.")
    elseif str then
        d(string.format("Unknown command: %s", str))
    end
end