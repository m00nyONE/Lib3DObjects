
--[[ doc.lua begin ]]
--- @class Lib3DObjects
--- @field name string
--- @field version string
--- @field author string
--- @field AUTOROTATE_NONE number
--- @field AUTOROTATE_CAMERA number
--- @field AUTOROTATE_PLAYER number
local lib = {
    name = "Lib3DObjects",
    version = "dev",
    author = "@m00nyONE",
    core = {
        ObjectPoolManager = {},
    },

    AUTOROTATE_NONE = 1, -- manual mode
    AUTOROTATE_CAMERA = 2, -- always face camera
    AUTOROTATE_PLAYER = 3, -- always face player heading direction
}
local lib_name = lib.name
local lib_author = lib.author
local lib_version = lib.version
_G[lib_name] = lib

local EM = GetEventManager()


--[[ doc.lua end ]]
local function initialize()
    lib.core.createCameraHelperControl()

    --local _ = lib.examples.createReactiveGroundMarkerArray(50)
    --local _ = lib.examples.createReactiveGroundMarkerConcentricArray(6, 6, 200, 200)
    --local _ = lib.examples.createUnitMarkerArray(20)
    --local _ = lib.examples.createSingleReactiveFloatingMarker()
    --local _ = lib.examples.createReactiveFloatingMarkerArray(20)
    --local _ = lib.examples.createSingleLine()

end

EM:RegisterForEvent(lib_name, EVENT_ADD_ON_LOADED, function(_, name)
    if name ~= lib_name then return end

    EM:UnregisterForEvent(lib_name, EVENT_ADD_ON_LOADED)
    initialize()
end)

SLASH_COMMANDS["/lib3dobjects"] = function()
    d(string.format("%s by %s, version %s", lib_name, lib_author, lib_version))
end