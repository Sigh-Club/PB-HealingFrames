
local addonName, ns = ...
ns = ns or _G.MTCHealingFrames or {}
_G.MTCHealingFrames = ns

ns.HealingIntel = ns.HealingIntel or {
    meta = {
        name = "MTC: Healing Frames Intel",
        version = "0.1.0",
        realm = "Area 52 Free-Pick",
    }
}

if addonName and not ns.addonName then
    ns.addonName = addonName
end
