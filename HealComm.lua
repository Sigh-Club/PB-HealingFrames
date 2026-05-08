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
        for _, b in ipairs(ns.Frames.tankPetButtons or {}) do
            if b:IsShown() then
                self:UpdateUnit(b)
            end
        end
        if ns.PetFrames then
            for _, b in ipairs(ns.PetFrames.buttons or {}) do
                if b:IsShown() then
                    self:UpdateUnit(b)
                end
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
    for _, b in ipairs(ns.Frames.tankPetButtons or {}) do
        if b:IsShown() and b.unit then
            local guid = UnitGUID(b.unit)
            if guid and units[guid] then
                self:UpdateUnit(b)
            end
        end
    end
    if ns.PetFrames then
        for _, b in ipairs(ns.PetFrames.buttons or {}) do
            if b:IsShown() and b.unit then
                local guid = UnitGUID(b.unit)
                if guid and units[guid] then
                    self:UpdateUnit(b)
                end
            end
        end
    end
end

function HealCommModule:UpdateUnit(b)
    if not b then return end

    local mine = b.incHealMine
    local others = b.incHealOthers
    if not mine or not others then return end

    if not LHC or not b.unit or b.fakeData or not ns.DB.frame.showHealComm then
        mine:SetValue(0)
        mine:Hide()
        others:SetValue(0)
        others:Hide()
        return
    end

    local guid = UnitGUID(b.unit)
    if not guid then
        mine:SetValue(0)
        mine:Hide()
        others:SetValue(0)
        others:Hide()
        return
    end

    local othersAmount = LHC:GetOthersHealAmount(guid, LHC.ALL_HEALS) or 0
    local playerGUID = UnitGUID("player")
    local myAmount = 0
    if playerGUID then
        myAmount = LHC:GetHealAmount(guid, LHC.ALL_HEALS, nil, playerGUID) or 0
    end
    local hp = UnitHealth(b.unit) or 0

    if othersAmount > 0 then
        others:SetValue(hp + othersAmount)
        others:Show()
    else
        others:SetValue(0)
        others:Hide()
    end

    if myAmount > 0 then
        mine:SetValue(hp + othersAmount + myAmount)
        mine:Show()
    else
        mine:SetValue(0)
        mine:Hide()
    end
end
