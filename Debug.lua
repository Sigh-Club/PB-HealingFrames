
local _, ns = ...
local Debug = ns:RegisterModule("Debug", {})

local function isEnabled()
    return ns.DB and ns.DB.debug and true or false
end

local function LogToFile(msg)
    if not PB_HF_Global then return end
    PB_HF_Global.debugLog = PB_HF_Global.debugLog or {}
    
    local timestamp = date("%Y-%m-%d %H:%M:%S")
    table.insert(PB_HF_Global.debugLog, "[" .. timestamp .. "] " .. tostring(msg))
    
    -- Keep log size manageable (max 1000 entries)
    if #PB_HF_Global.debugLog > 1000 then
        table.remove(PB_HF_Global.debugLog, 1)
    end
end

function ns:Log(msg)
    LogToFile(msg)
end

function ns:Debug(msg, forceLog)
    if isEnabled() then
        self:Print("|cffaaaaaaDEBUG|r " .. tostring(msg))
    end
    if isEnabled() or forceLog then
        LogToFile(msg)
    end
end

function Debug:OnInitialize()
    ns.DB.debug = ns.DB.debug or false
end

function Debug:SetEnabled(flag)
    ns.DB.debug = flag and true or false
    ns:Print("Debug " .. (ns.DB.debug and "enabled" or "disabled"))
    LogToFile("Debug mode set to: " .. tostring(ns.DB.debug))
end
