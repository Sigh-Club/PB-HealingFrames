local _, ns = ...
local SpellBook = ns:RegisterModule("SpellBook", {})
ns.SpellBook = SpellBook

SpellBook.raw = {}
SpellBook.bindable = {}
SpellBook.byName = {}
SpellBook.stats = { raw = 0, bindable = 0, healing = 0 }
SpellBook.dispelCapabilities = {}
SpellBook.rangeSpellName = nil

local function lower(s) return s and string.lower(s) or "" end

local function guessRole(name, spellId)
    local intel = ns.HealingIntel or {}
    if spellId and intel.knownSpellRolesById and intel.knownSpellRolesById[spellId] then
        return intel.knownSpellRolesById[spellId]
    end
    local exact = intel.knownSpellRolesByName and intel.knownSpellRolesByName[lower(name)]
    if exact then return exact end
    local keywords = intel.keywordRoles or {}
    local lname = lower(name)
    for role, list in pairs(keywords) do
        for _, token in ipairs(list) do
            if string.find(lname, token, 1, true) then
                return role
            end
        end
    end
    return nil
end

local function addRaw(entry)
    SpellBook.raw[#SpellBook.raw + 1] = entry
end

local function addBindable(entry)
    SpellBook.bindable[#SpellBook.bindable + 1] = entry
    SpellBook.byName[string.lower(entry.name)] = entry
end

local function computeDispelCaps()
    wipe(SpellBook.dispelCapabilities)
    local intel = ns.HealingIntel or {}
    local byName = SpellBook.byName
    local byId = {}
    for _, e in ipairs(SpellBook.raw) do
        if e.spellId then byId[e.spellId] = true end
        byName[string.lower(e.name)] = byName[string.lower(e.name)] or e
    end
    for dtype, ids in pairs(intel.dispelAbilities or {}) do
        for _, id in ipairs(ids) do
            local spellName = GetSpellInfo and GetSpellInfo(id)
            if byId[id] or (spellName and byName[string.lower(spellName)]) then
                SpellBook.dispelCapabilities[dtype] = true
                break
            end
        end
    end
end

local function chooseRangeSpell()
    SpellBook.rangeSpellName = nil
    local roleOrder = {"direct_heal", "hot", "shield_absorb", "cleanse", "support"}
    for _, role in ipairs(roleOrder) do
        for _, e in ipairs(SpellBook.bindable) do
            if e.role == role and ns.Compat:IsHelpfulRangeSpell(e.name) then
                SpellBook.rangeSpellName = e.name
                return
            end
        end
    end
    for _, fallback in ipairs((ns.HealingIntel and ns.HealingIntel.defaultRangeSpells) or {}) do
        if SpellBook.byName[string.lower(fallback)] and ns.Compat:IsHelpfulRangeSpell(fallback) then
            SpellBook.rangeSpellName = fallback
            return
        end
    end
end

function SpellBook:PlayerCanDispel(dtype)
    return self.dispelCapabilities[dtype] and true or false
end

function SpellBook:GetRangeSpellName()
    return self.rangeSpellName
end

function SpellBook:Scan()
    wipe(self.raw)
    wipe(self.bindable)
    wipe(self.byName)
    self.stats.raw = 0
    self.stats.bindable = 0
    self.stats.healing = 0

    local opts = ns.DB.scan
    local tabCount = ns.Compat:GetNumSpellTabs()
    local seen = {}

    for tab = 1, tabCount do
        local tabName, _, offset, numSpells = ns.Compat:GetSpellTabInfo(tab)
        local isGeneral = (tab == 1)
        local isTrade = ns.Compat:IsTradeskill(tabName)

        for slot = offset + 1, offset + numSpells do
            local name, rank = ns.Compat:GetSpellName(slot)
            if name then
                local link = ns.Compat:GetSpellLink(slot)
                local spellId = ns.Compat:GetSpellIdFromLink(link)
                local entry = {
                    name = name,
                    rank = rank or "",
                    slot = slot,
                    link = link,
                    spellId = spellId,
                    texture = ns.Compat:GetSpellTexture(slot),
                    tabIndex = tab,
                    tabName = tabName or "",
                    isGeneral = isGeneral,
                    isPassive = ns.Compat:IsPassive(slot),
                    isTrade = isTrade,
                    role = ns.DB.spellRoles[lower(name)] or guessRole(name, spellId),
                }
                addRaw(entry)
                self.stats.raw = self.stats.raw + 1

                local ok = true
                if opts.excludeGeneral and entry.isGeneral then ok = false end
                if opts.excludePassive and entry.isPassive then ok = false end
                if opts.excludeProfessions and entry.isTrade then ok = false end
                if opts.dedupeByName then
                    local k = lower(name)
                    if seen[k] then ok = false else seen[k] = true end
                end

                if ok then
                    addBindable(entry)
                    self.stats.bindable = self.stats.bindable + 1
                    if entry.role and ns.HealingIntel and ns.HealingIntel.healingRoles and ns.HealingIntel.healingRoles[entry.role] then
                        self.stats.healing = self.stats.healing + 1
                    end
                end
            end
        end
    end

    computeDispelCaps()
    chooseRangeSpell()
    table.sort(self.bindable, function(a, b) return a.name < b.name end)
    ns:Print(string.format("%s: raw=%d, bindable=%d, healing/support=%d", (ns.L and ns.L.STATUS_SCAN) or "Scan complete", self.stats.raw, self.stats.bindable, self.stats.healing))
    if self.rangeSpellName then ns:Debug("Range spell: " .. self.rangeSpellName) end
    if next(self.dispelCapabilities) then
        local caps = {}
        for _, dtype in ipairs(ns.HealingIntel.dispelPriority or {}) do
            if self.dispelCapabilities[dtype] then caps[#caps + 1] = dtype end
        end
        if #caps > 0 then ns:Debug("Dispel capabilities: " .. table.concat(caps, ", ")) end
    end
    if ns.UI_Bindings and ns.UI_Bindings.RefreshSpellList then ns.UI_Bindings:RefreshSpellList() end
end

function SpellBook:GetBindable()
    return self.bindable
end

function SpellBook:FindByName(name)
    if not name or name == "" then return nil end
    return self.byName[string.lower(name)]
end

function SpellBook:OnEnable()
    self:Scan()
end

function SpellBook:OnEvent(event)
    if event == "LEARNED_SPELL_IN_TAB" or event == "CHARACTER_POINTS_CHANGED" then
        self:Scan()
    end
end
