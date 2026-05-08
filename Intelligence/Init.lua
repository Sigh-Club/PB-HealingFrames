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

ns.intelListeners = ns.intelListeners or {}
function ns:RegisterIntelListener(callback)
    if type(callback) ~= "function" then return end
    table.insert(self.intelListeners, callback)
end

function ns:NotifyIntelUpdated(reason)
    if not self.intelListeners then return end
    for _, cb in ipairs(self.intelListeners) do
        local ok, err = pcall(cb, reason)
        if not ok and self.Debug then
            self:Debug("Intel listener error: " .. tostring(err), true)
        end
    end
end

if addonName and not ns.addonName then
    ns.addonName = "PB: Healing Frames"
end
