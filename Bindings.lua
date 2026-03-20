
local _, ns = ...
local Bindings = ns:RegisterModule("Bindings", {})
ns.Bindings = Bindings

local orderedSlots = {
    "LeftButton",
    "RightButton",
    "MiddleButton",
    "Button4",
    "Button5",
    "Shift-LeftButton",
    "Shift-RightButton",
    "Ctrl-LeftButton",
    "Ctrl-RightButton",
    "Alt-LeftButton",
    "Alt-RightButton",
}

function Bindings:GetOrderedSlots()
    return orderedSlots
end

function Bindings:Get(slot)
    ns.DB.bindings[slot] = ns.DB.bindings[slot] or { type = "spell", value = "" }
    return ns.DB.bindings[slot]
end

function Bindings:SetSpell(slot, spellName)
    local rec = self:Get(slot)
    rec.type = "spell"
    rec.value = spellName or ""
    ns:Print((ns.L and ns.L.STATUS_BINDING_SET or "Binding updated") .. ": " .. slot .. " -> " .. rec.value)
    if ns.ClickCast then ns.ClickCast:RefreshAll() end
    if ns.UI_Bindings then ns.UI_Bindings:RefreshSlots() end
end

function Bindings:Clear(slot)
    local rec = self:Get(slot)
    rec.type = "spell"
    rec.value = ""
    ns:Print((ns.L and ns.L.STATUS_BINDING_CLEARED or "Binding cleared") .. ": " .. slot)
    if ns.ClickCast then ns.ClickCast:RefreshAll() end
    if ns.UI_Bindings then ns.UI_Bindings:RefreshSlots() end
end
