local addonName, ns = ...
_G.MTCHealingFrames = ns
ns.addonName = "MTC: Healing Frames"
ns.modules = {}
ns.moduleOrder = {}
ns.state = {}
ns.L = ns.L or {}

local frame = CreateFrame("Frame")
ns.frame = frame

function ns:RegisterModule(name, mod)
    mod = mod or {}
    mod.name = name
    if not self.modules[name] then
        table.insert(self.moduleOrder, mod)
    end
    self.modules[name] = mod
    return mod
end

function ns:IterModules(method, ...)
    for _, mod in ipairs(self.moduleOrder) do
        if mod and mod[method] then
            local ok, err = pcall(mod[method], mod, ...)
            if not ok then 
                local msg = "Module Error ["..(mod.name or "Unknown")..":"..method.."]: "..tostring(err)
                self:Print(msg)
            end
        end
    end
end

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7cc7ffMTC:HF|r: "..tostring(msg))
end

local function EnsureSaved()
    PainboyDB = PainboyDB or {}
    PainboyDB.profiles = PainboyDB.profiles or {}
    PainboyDB.profileKeys = PainboyDB.profileKeys or {}
    
    local name = UnitName("player")
    local realm = GetRealmName()
    local key = (name and realm) and (name.." - "..realm) or "Default"
    
    local profileName = PainboyDB.profileKeys[key] or "Default"
    PainboyDB.profiles[profileName] = PainboyDB.profiles[profileName] or {}
    ns.DB = PainboyDB.profiles[profileName]
    
    -- Structure Setup
    ns.DB.frame = ns.DB.frame or {}
    ns.DB.bindings = ns.DB.bindings or {}
    ns.DB.scan = ns.DB.scan or {}
    
    local f = ns.DB.frame
    f.layoutStyle = f.layoutStyle or "bars"
    
    -- Split settings for Bars vs Grid
    f.bars = f.bars or {
        width = 180,
        height = 22,
        spacing = 4,
        scale = 1,
        groupsPerRow = 2,
        groupSpacing = 18,
        nameLength = 12,
        shortenNames = false,
    }
    
    f.grid = f.grid or {
        size = 40,
        columns = 5,
        spacing = 2,
        scale = 1,
        nameLength = 6,
        shortenNames = true,
    }

    f.outOfRangeAlpha = f.outOfRangeAlpha or 0.35
    if f.highlightCurableDebuffs == nil then f.highlightCurableDebuffs = true end
    if f.showAuraTimers == nil then f.showAuraTimers = true end
    if f.showManaBar == nil then f.showManaBar = true end
    if f.showHealthText == nil then f.showHealthText = true end
    if f.showStatusText == nil then f.showStatusText = true end
    
    PainboyGlobal = PainboyGlobal or {}
end

local function Bootstrap()
    EnsureSaved()
    ns:IterModules("OnInitialize")
    ns:IterModules("OnEnable")
    
    local events = { "PLAYER_ENTERING_WORLD", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA", "UNIT_POWER", "UNIT_DISPLAYPOWER" }
    for _, ev in ipairs(events) do frame:RegisterEvent(ev) end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        Bootstrap()
    else
        ns:IterModules("OnEvent", event, ...)
    end
end)
frame:RegisterEvent("ADDON_LOADED")
