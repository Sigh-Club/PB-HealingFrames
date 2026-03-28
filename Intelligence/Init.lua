local addonName, ns = ...
ns = ns or _G.PB_HealingFrames or {}
_G.PB_HealingFrames = ns

ns.HealingIntel = ns.HealingIntel or {
    meta = {
        name = "PB: Healing Frames Intel",
        version = "1.0.0",
        realm = "Area 52 Free-Pick",
    }
}

if addonName and not ns.addonName then
    ns.addonName = "PB: Healing Frames"
end
