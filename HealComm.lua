local _, ns = ...
local HealCommModule = ns:RegisterModule("HealComm", {})
ns.HealComm = HealCommModule

local LHC

function HealCommModule:OnInitialize()
    if ns.DB.frame.showHealComm == nil then
        ns.DB.frame.showHealComm = true
    end

    LHC = LibStub and LibStub("LibHealComm-4.0", true)
    if not LHC then return end

    LHC.RegisterCallback(self, "HealComm_HealStarted", "UpdateHealComm")
    LHC.RegisterCallback(self, "HealComm_HealUpdated", "UpdateHealComm")
    LHC.RegisterCallback(self, "HealComm_HealDelayed", "UpdateHealComm")
    LHC.RegisterCallback(self, "HealComm_HealStopped", "UpdateHealComm")
    LHC.RegisterCallback(self, "HealComm_ModifierChanged", "UpdateHealComm")
end

function HealCommModule:UpdateHealComm(event, casterGUID, spellID, healType, endTime, ...)
    if not ns.Frames or not ns.Frames.buttons then return end

    if event == "HealComm_ModifierChanged" then
        for _, b in ipairs(ns.Frames.buttons) do
            if b:IsShown() then
                self:UpdateUnit(b)
            end
        end
        return
    end

    local units = {}
    for i = 1, select("#", ...) do
        local guid = select(i, ...)
        if guid then
            units[guid] = true
        end
    end

    for _, b in ipairs(ns.Frames.buttons) do
        if b:IsShown() and b.unit then
            local guid = UnitGUID(b.unit)
            if guid and units[guid] then
                self:UpdateUnit(b)
            end
        end
    end
end

function HealCommModule:UpdateUnit(b)
    if not b or not b.incHeal then return end
    
    if not LHC or not b.unit or b.fakeData or not ns.DB.frame.showHealComm then
        b.incHeal:SetValue(0)
        b.incHeal:Hide()
        return
    end

    local guid = UnitGUID(b.unit)
    if not guid then 
        b.incHeal:SetValue(0)
        b.incHeal:Hide()
        return 
    end

    local healAmount = LHC:GetOthersHealAmount(guid, LHC.ALL_HEALS) or 0
    local myAmount = LHC:GetHealAmount(guid, LHC.ALL_HEALS) or 0
    local total = healAmount + myAmount
    
    if total > 0 then
        local hp = UnitHealth(b.unit) or 0
        b.incHeal:SetValue(hp + total)
        b.incHeal:Show()
    else
        b.incHeal:SetValue(0)
        b.incHeal:Hide()
    end
end
