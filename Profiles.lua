local _, ns = ...
local Profiles = ns:RegisterModule("Profiles", {})
ns.Profiles = Profiles

local function defaults()
    return {
        debug = false,
        locked = false,
        activeProfile = nil,
        frame = {
            x = 400,
            y = -240,
            width = 180,
            height = 22,
            spacing = 3,
            scale = 1.00,
            outOfRangeAlpha = 0.35,
            outOfRangeTextAlpha = 0.55,
            showHealthText = true,
            grow = "DOWN",
            useHealthGradient = true,
            highlightCurableDebuffs = true,
            healthyColor = {0.15, 0.78, 0.22},
            injuredColor = {0.95, 0.82, 0.20},
            criticalColor = {0.95, 0.15, 0.15},
            layoutMode = "combined", -- combined|separate
            groupsPerRow = 2,
            groupSpacing = 18,
            fakeMode = false,
            fakeSize = 10,
            fakeAnimate = true,
            showManaBar = true,
            manaBarHeight = 3,
            showStatusText = true,
            classColorNames = true,
        },
        scan = {
            excludeGeneral = true,
            excludePassive = true,
            excludeProfessions = true,
            dedupeByName = true,
        },
        bindings = {
            ["LeftButton"] = { type = "spell", value = "" },
            ["RightButton"] = { type = "target", value = "" },
            ["MiddleButton"] = { type = "menu", value = "" },
            ["Shift-LeftButton"] = { type = "spell", value = "" },
            ["Shift-RightButton"] = { type = "spell", value = "" },
            ["Ctrl-LeftButton"] = { type = "spell", value = "" },
        },
        spellRoles = {},
        groupAnchors = {},
    }
end

local function deepCopy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do out[k] = deepCopy(v) end
    return out
end

local function copyMissing(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            copyMissing(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function Profiles:GetCharKey()
    return ns.state.charKey
end

function Profiles:GetProfileName()
    return ns.state.profileName or self:GetCharKey()
end

function Profiles:ResetCurrentProfile()
    local name = self:GetProfileName()
    PainboyDB.profiles[name] = deepCopy(defaults())
    ns.DB = PainboyDB.profiles[name]
    copyMissing(ns.DB, defaults())
end

function Profiles:OnInitialize()
    copyMissing(ns.DB, defaults())
    if not ns.DB.activeProfile then ns.DB.activeProfile = self:GetProfileName() end
end
