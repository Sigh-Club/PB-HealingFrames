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
            criticalThreshold = 35,
            injuredThreshold = 70,
            layoutMode = "combined", -- combined|separate
            groupsPerRow = 2,
            groupSpacing = 18,
            autoScaleByRoster = true,
            sizePresets = {
                [5] = { width = 180, height = 24, spacing = 4, scale = 1.00, manaBarHeight = 3 },
                [10] = { width = 170, height = 22, spacing = 3, scale = 0.96, manaBarHeight = 3 },
                [25] = { width = 154, height = 20, spacing = 3, scale = 0.90, manaBarHeight = 2 },
                [40] = { width = 140, height = 18, spacing = 2, scale = 0.84, manaBarHeight = 2 },
            },
            fakeMode = false,
            fakeSize = 10,
            fakeAnimate = true,
            showManaBar = true,
            manaBarHeight = 3,
            showStatusText = true,
            showHealComm = true,
            classColorNames = true,
            alwaysFullAlphaText = false,
            showTextBackdrop = true,
            dispelPriority = { "Magic", "Curse", "Disease", "Poison" },
            dispelColors = {
                Magic = { 0.20, 0.60, 1.00 },
                Curse = { 0.60, 0.00, 1.00 },
                Disease = { 0.60, 0.40, 0.00 },
                Poison = { 0.00, 0.75, 0.20 },
            },
        },
        scan = {
            excludeGeneral = true,
            excludePassive = true,
            excludeProfessions = true,
            excludeRacials = true,
            excludeUtility = true,
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
    PB_HF_DB.profiles[name] = deepCopy(defaults())
    ns.DB = PB_HF_DB.profiles[name]
    copyMissing(ns.DB, defaults())
end

function Profiles:OnInitialize()
    copyMissing(ns.DB, defaults())
    if not ns.DB.activeProfile then ns.DB.activeProfile = self:GetProfileName() end
end
