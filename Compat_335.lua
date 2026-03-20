local _, ns = ...
local Compat = ns:RegisterModule("Compat", {})

ns.Compat = Compat

local BOOKTYPE = BOOKTYPE_SPELL or "spell"

function Compat:GetNumSpellTabs()
    return GetNumSpellTabs and GetNumSpellTabs() or 0
end

function Compat:GetSpellTabInfo(index)
    if not GetSpellTabInfo then return nil end
    return GetSpellTabInfo(index)
end

function Compat:GetSpellName(slot)
    if not GetSpellBookItemName then return nil end
    local name, rank = GetSpellBookItemName(slot, BOOKTYPE)
    return name, rank
end

function Compat:IsPassive(slot)
    if IsPassiveSpell then
        local ok, val = pcall(IsPassiveSpell, slot, BOOKTYPE)
        if ok and val ~= nil then return val end
    end
    return false
end

function Compat:GetSpellTexture(slot)
    if GetSpellBookItemTexture then
        return GetSpellBookItemTexture(slot, BOOKTYPE)
    end
end

function Compat:GetSpellLink(slot)
    if GetSpellLink then
        return GetSpellLink(slot, BOOKTYPE)
    end
end

function Compat:GetSpellIdFromLink(link)
    if not link then return nil end
    local sid = string.match(link, "spell:(%d+)")
    return sid and tonumber(sid) or nil
end

function Compat:IsTradeskill(tabName)
    if not tabName then return false end
    local s = string.lower(tabName)
    local bad = {
        "professions", "first aid", "cooking", "fishing", "blacksmith", "alchemy", "engineering",
        "enchanting", "tailoring", "leather", "mining", "herbal", "inscription", "jewelcraft"
    }
    for _, token in ipairs(bad) do
        if string.find(s, token, 1, true) then return true end
    end
    return false
end

function Compat:IsUsableSpellName(name)
    if not name or name == "" then return false end
    local ok, usable = pcall(IsUsableSpell, name)
    if ok and usable ~= nil then return usable and true or false end
    return true
end

function Compat:IsHelpfulRangeSpell(name)
    if not name or name == "" then return false end
    if not IsSpellInRange then return true end
    local ok, res = pcall(IsSpellInRange, name, "player")
    if ok and res ~= nil then return true end
    return false
end

function Compat:IsSpellInRange(name, unit)
    if not name or not unit or not UnitExists(unit) then return nil end
    if not IsSpellInRange then return nil end
    local ok, res = pcall(IsSpellInRange, name, unit)
    if ok then return res end
    return nil
end
