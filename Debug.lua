
local _, ns = ...
local Debug = ns:RegisterModule("Debug", {})

local function isEnabled()
    return ns.DB and ns.DB.debug and true or false
end

function ns:Debug(msg)
    if isEnabled() then
        self:Print("|cffaaaaaaDEBUG|r " .. tostring(msg))
    end
end

function Debug:OnInitialize()
    ns.DB.debug = ns.DB.debug or false
end

function Debug:SetEnabled(flag)
    ns.DB.debug = flag and true or false
    ns:Print("Debug " .. (ns.DB.debug and "enabled" or "disabled"))
end
