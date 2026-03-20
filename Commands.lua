
local _, ns = ...
local Commands = ns:RegisterModule("Commands", {})
ns.Commands = Commands

SLASH_PAINBOY1 = "/pb"
SLASH_PAINBOY2 = "/painboy"

local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

SlashCmdList["PAINBOY"] = function(msg)
    msg = trim(msg)
    if msg == "debug on" then
        ns.modules.Debug:SetEnabled(true)
    elseif msg == "debug off" then
        ns.modules.Debug:SetEnabled(false)
    elseif msg == "scan" then
        ns.SpellBook:Scan()
    elseif msg == "unlock" then
        ns.DB.locked = false
        ns:Print(ns.L.CFG_UNLOCKED or "Frames unlocked")
    elseif msg == "lock" then
        ns.DB.locked = true
        ns:Print(ns.L.CFG_LOCKED or "Frames locked")
    elseif msg == "binds" or msg == "keybinds" then
        InterfaceOptionsFrame_OpenToCategory(ns.UI_Bindings.panel)
        InterfaceOptionsFrame_OpenToCategory(ns.UI_Bindings.panel)
    elseif msg == "bars" then
        InterfaceOptionsFrame_OpenToCategory(ns.UI_Bars.panel)
        InterfaceOptionsFrame_OpenToCategory(ns.UI_Bars.panel)
    elseif msg:match("^test") then
        local n = tonumber(msg:match("test%s+(%d+)"))
        if msg == "test off" or msg == "test live" then
            ns.Roster:SetFakeMode(false)
            ns:Print("Test mode disabled")
        else
            ns.Roster:SetFakeMode(true, n or ns.DB.frame.fakeSize or 10)
            ns:Print("Test mode enabled")
        end
    elseif msg == "config" or msg == "" then
        InterfaceOptionsFrame_OpenToCategory(ns.UI_Config.panel)
        InterfaceOptionsFrame_OpenToCategory(ns.UI_Config.panel)
    else
        ns:Print("Commands: /pb scan, /pb binds, /pb bars, /pb config, /pb test 5|10|25|40|off, /pb lock, /pb unlock, /pb debug on|off")
    end
end
