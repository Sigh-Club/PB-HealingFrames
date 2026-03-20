
local addonName, ns = ...

_G.Painboy = ns
ns.addonName = addonName
ns.modules = ns.modules or {}
ns.moduleOrder = ns.moduleOrder or {}
ns.state = ns.state or {}
ns.L = ns.L or {}
ns.DB = nil

local frame = CreateFrame("Frame")
ns.frame = frame

local startupEvents = {
    "PLAYER_ENTERING_WORLD",
    "PARTY_MEMBERS_CHANGED",
    "RAID_ROSTER_UPDATE",
    "UNIT_HEALTH",
    "UNIT_MAXHEALTH",
    "UNIT_AURA",
    "UNIT_FLAGS",
    "UNIT_CONNECTION",
    "LEARNED_SPELL_IN_TAB",
    "CHARACTER_POINTS_CHANGED",
}

function ns:RegisterModule(name, mod)
    mod = mod or {}
    mod.name = name
    if not self.modules[name] then
        self.moduleOrder[#self.moduleOrder + 1] = mod
    end
    self.modules[name] = mod
    return mod
end

function ns:IterModules(method, ...)
    for _, mod in ipairs(self.moduleOrder) do
        local fn = mod and mod[method]
        if fn then
            local ok, err = pcall(fn, mod, ...)
            if not ok then
                self:Print("Module error in " .. tostring(mod.name) .. "." .. tostring(method) .. ": " .. tostring(err))
            end
        end
    end
end

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7cc7ffPainboy|r: " .. tostring(msg))
end

function ns:InCombatLockdown()
    return InCombatLockdown and InCombatLockdown()
end

local function deepCopy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do
        out[k] = deepCopy(v)
    end
    return out
end

local function EnsureSaved()
    PainboyDB = PainboyDB or {}
    PainboyDB.global = PainboyDB.global or {}
    PainboyDB.profileKeys = PainboyDB.profileKeys or {}
    PainboyDB.profiles = PainboyDB.profiles or {}

    local charName = UnitName("player") or "Unknown"
    local realmName = GetRealmName() or "Realm"
    local key = charName .. " - " .. realmName
    ns.state.charKey = key

    local oldProfileName = PainboyDB.profileKeys[key]
    local defaultProfile = key

    if not oldProfileName or oldProfileName == "Default" then
        if not PainboyDB.profiles[defaultProfile] then
            if oldProfileName == "Default" and PainboyDB.profiles.Default then
                PainboyDB.profiles[defaultProfile] = deepCopy(PainboyDB.profiles.Default)
            else
                PainboyDB.profiles[defaultProfile] = {}
            end
        end
        PainboyDB.profileKeys[key] = defaultProfile
    end

    local profileName = PainboyDB.profileKeys[key]
    PainboyDB.profiles[profileName] = PainboyDB.profiles[profileName] or {}
    ns.DB = PainboyDB.profiles[profileName]
    ns.state.profileName = profileName
    PainboyGlobal = PainboyGlobal or {}
end

local function Bootstrap()
    EnsureSaved()
    ns:IterModules("OnInitialize")
    ns:IterModules("OnEnable")
    for _, ev in ipairs(startupEvents) do frame:RegisterEvent(ev) end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded == addonName then
            frame:UnregisterEvent("ADDON_LOADED")
            Bootstrap()
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        ns.state.inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.state.inCombat = false
        ns:IterModules("OnLeaveCombat")
    end

    ns:IterModules("OnEvent", event, ...)
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
