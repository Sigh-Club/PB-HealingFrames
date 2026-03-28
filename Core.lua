local addonName, ns = ...
_G.PB_HealingFrames = ns
ns.addonName = "PB: Healing Frames"
ns.modules = {}
ns.moduleOrder = {}
ns.state = {}
ns.L = ns.L or {}

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
    local f = DEFAULT_CHAT_FRAME or ChatFrame1
    if f then
        f:AddMessage("|cff7cc7ffPB:HF|r: "..tostring(msg))
    else
        print("PB:HF: "..tostring(msg))
    end
end

local function EnsureSaved()
    PB_HF_DB = PB_HF_DB or {}
    PB_HF_DB.profiles = PB_HF_DB.profiles or {}
    PB_HF_DB.profileKeys = PB_HF_DB.profileKeys or {}
    
    local name = UnitName("player")
    local realm = GetRealmName()
    local key = (name and realm) and (name.." - "..realm) or "Default"
    
    local profileName = PB_HF_DB.profileKeys[key] or "Default"
    PB_HF_DB.profiles[profileName] = PB_HF_DB.profiles[profileName] or {}
    ns.DB = PB_HF_DB.profiles[profileName]
    
    -- Structure Setup
    ns.DB.frame = ns.DB.frame or {}
    ns.DB.bindings = ns.DB.bindings or {}
    ns.DB.scan = ns.DB.scan or {}
    ns.DB.spellRoles = ns.DB.spellRoles or {}
    
    local f = ns.DB.frame
    f.layoutStyle = f.layoutStyle or "bars"
    f.bars = f.bars or { width = 180, height = 22, spacing = 4, scale = 1, groupsPerRow = 2, groupSpacing = 18, nameLength = 12, shortenNames = false }
    f.grid = f.grid or { size = 40, columns = 5, spacing = 2, scale = 1, nameLength = 6, shortenNames = true }
    f.outOfRangeAlpha = f.outOfRangeAlpha or 0.35
    
    if f.highlightCurableDebuffs == nil then f.highlightCurableDebuffs = true end
    if f.showAuraTimers == nil then f.showAuraTimers = true end
    if f.showManaBar == nil then f.showManaBar = true end
    if f.showHealthText == nil then f.showHealthText = true end
    if f.showStatusText == nil then f.showStatusText = true end
    
    PB_HF_Global = PB_HF_Global or {}
end

local isBootstrapped = false
local function Bootstrap()
    if isBootstrapped then return end
    if not UnitName("player") or UnitName("player") == "Unknown Entity" then return end
    isBootstrapped = true
    
    EnsureSaved()
    ns:IterModules("OnInitialize")
    ns:IterModules("OnEnable")
    ns:Print("V 1.0 beta loaded. Type /pb for config.")
end

local frame = CreateFrame("Frame")
ns.frame = frame
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Bootstrap()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        Bootstrap()
    end
    
    if isBootstrapped then
        ns:IterModules("OnEvent", event, arg1)
    end
end)

local events = { "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA", "UNIT_POWER", "UNIT_DISPLAYPOWER" }
for _, ev in ipairs(events) do frame:RegisterEvent(ev) end

if IsLoggedIn() then Bootstrap() end
