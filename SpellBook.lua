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

local function normalizeRole(role)
    if role == "direct_heal" then return "heal" end
    if role == "healing_over_time" then return "hot" end
    return role
end

local utilityNameTokens = {
    "stone of retreat",
    "banner of recruitment",
    "manastorm:",
    "teleport:",
    "portal:",
    "hearthstone",
}

local function isUtilityLikeSpell(name)
    local lname = lower(name)
    for _, token in ipairs(utilityNameTokens) do
        if string.find(lname, token, 1, true) then
            return true
        end
    end
    return false
end

local function guessRole(name, spellId)
    local intel = ns.HealingIntel or {}
    
    -- Check if it's a racial first
    if ns.DB.scan.excludeRacials then
        if spellId and intel.racialSpellIds then
            for _, id in ipairs(intel.racialSpellIds) do
                if id == spellId then return "racial", "racial_id" end
            end
        end
        if intel.racialSpellNames then
            local lname = lower(name)
            for _, rname in ipairs(intel.racialSpellNames) do
                if lower(rname) == lname then return "racial", "racial_name" end
            end
        end
    end

    if spellId and intel.knownSpellRolesById and intel.knownSpellRolesById[spellId] then
        return intel.knownSpellRolesById[spellId], "id"
    end
    local exact = intel.knownSpellRolesByName and intel.knownSpellRolesByName[lower(name)]
    if exact then return exact, "name" end
    local keywords = intel.keywordRoles or {}
    local lname = lower(name)
    for role, list in pairs(keywords) do
        for _, token in ipairs(list) do
            if string.find(lname, token, 1, true) then
                return role, "keyword"
            end
        end
    end
    return nil, "none"
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
    local roleOrder = {"heal", "hot", "shield_absorb", "cleanse", "support"}
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
    local stats = {
        total = 0,
        bindable = 0,
        healing = 0,
        support = 0,
        raw_healing = 0,
        raw_support = 0,
        by_id = 0,
        by_name = 0,
        by_keyword = 0,
        by_manual = 0,
        untyped_bindable = 0,
        untyped_samples = {},
        excl_general = 0,
        excl_passive = 0,
        excl_trade = 0,
        excl_racial = 0,
        excl_utility = 0,
        excl_dedupe = 0
    }

    for tab = 1, tabCount do
        local tabName, _, offset, numSpells = ns.Compat:GetSpellTabInfo(tab)
        local isGeneral = (tab == 1) or (tabName and string.lower(tabName) == "general")
        local isTrade = ns.Compat:IsTradeskill(tabName)

        for slot = offset + 1, offset + numSpells do
            local name, rank = ns.Compat:GetSpellName(slot)
            if name then
                local link = ns.Compat:GetSpellLink(slot)
                local spellId = ns.Compat:GetSpellIdFromLink(link)
                stats.total = stats.total + 1
                local manualRole = normalizeRole(ns.DB.spellRoles[lower(name)])
                if manualRole == "" then manualRole = nil end

                local guessedRole, roleSource = guessRole(name, spellId)
                guessedRole = normalizeRole(guessedRole)
                if manualRole then
                    roleSource = "manual"
                end

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
                    role = manualRole or guessedRole,
                    roleSource = roleSource,
                }
                addRaw(entry)

                if entry.role and ns.HealingIntel then
                    if ns.HealingIntel.healingRoles and ns.HealingIntel.healingRoles[entry.role] then
                        stats.raw_healing = stats.raw_healing + 1
                    elseif ns.HealingIntel.supportRoles and ns.HealingIntel.supportRoles[entry.role] then
                        stats.raw_support = stats.raw_support + 1
                    end
                end
                if entry.roleSource == "id" then stats.by_id = stats.by_id + 1 end
                if entry.roleSource == "name" then stats.by_name = stats.by_name + 1 end
                if entry.roleSource == "keyword" then stats.by_keyword = stats.by_keyword + 1 end
                if entry.roleSource == "manual" then stats.by_manual = stats.by_manual + 1 end

                local ok = true
                if opts.excludeGeneral and entry.isGeneral then 
                    ok = false 
                    stats.excl_general = stats.excl_general + 1
                end
                if ok and opts.excludePassive and entry.isPassive then 
                    ok = false 
                    stats.excl_passive = stats.excl_passive + 1
                end
                if ok and opts.excludeProfessions and entry.isTrade then 
                    ok = false 
                    stats.excl_trade = stats.excl_trade + 1
                end
                if ok and opts.excludeRacials and entry.role == "racial" then
                    ok = false
                    stats.excl_racial = stats.excl_racial + 1
                end
                if ok and opts.excludeUtility ~= false and not entry.role and isUtilityLikeSpell(entry.name) then
                    ok = false
                    stats.excl_utility = stats.excl_utility + 1
                end
                if ok and opts.dedupeByName then
                    local k = lower(name)
                    if seen[k] then 
                        ok = false 
                        stats.excl_dedupe = stats.excl_dedupe + 1
                    else 
                        seen[k] = true 
                    end
                end

                if ok then
                    addBindable(entry)
                    stats.bindable = stats.bindable + 1
                    local role = entry.role
                    if role and ns.HealingIntel then
                        if ns.HealingIntel.healingRoles and ns.HealingIntel.healingRoles[role] then
                            stats.healing = stats.healing + 1
                        elseif ns.HealingIntel.supportRoles and ns.HealingIntel.supportRoles[role] then
                            stats.support = stats.support + 1
                        end
                    else
                        stats.untyped_bindable = stats.untyped_bindable + 1
                        if #stats.untyped_samples < 10 then
                            stats.untyped_samples[#stats.untyped_samples + 1] = entry.name
                        end
                    end
                end
            end
        end
    end

    self.stats.raw = stats.total
    self.stats.bindable = stats.bindable
    self.stats.healing = stats.healing
    self.stats.support = stats.support

    computeDispelCaps()
    chooseRangeSpell()
    table.sort(self.bindable, function(a, b) return a.name < b.name end)
    
    local msg = string.format("%s: bindable=%d (heal=%d, supp=%d)", (ns.L and ns.L.STATUS_SCAN) or "Scan complete", stats.bindable, stats.healing, stats.support)
    ns:Print(msg)
    
    if stats.excl_general > 0 or stats.excl_passive > 0 or stats.excl_trade > 0 or stats.excl_racial > 0 or stats.excl_utility > 0 then
        ns:Debug(string.format("Filtered: general=%d passive=%d trade=%d racial=%d utility=%d", stats.excl_general, stats.excl_passive, stats.excl_trade, stats.excl_racial, stats.excl_utility))
    end
    ns:Debug(string.format("Role classify: raw(h=%d,s=%d) bindable(h=%d,s=%d) sources[id=%d,name=%d,keyword=%d,manual=%d] untyped=%d", stats.raw_healing, stats.raw_support, stats.healing, stats.support, stats.by_id, stats.by_name, stats.by_keyword, stats.by_manual, stats.untyped_bindable))
    if #stats.untyped_samples > 0 then
        ns:Debug("Untyped sample: " .. table.concat(stats.untyped_samples, ", "))
    end
    if self.rangeSpellName then ns:Debug("Range spell: " .. self.rangeSpellName) end
    if next(self.dispelCapabilities) then
        local caps = {}
        local order = (ns.DB.frame and ns.DB.frame.dispelPriority) or (ns.HealingIntel and ns.HealingIntel.dispelPriority) or {}
        for _, dtype in ipairs(order) do
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
