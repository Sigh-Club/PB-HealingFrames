
local _, ns = ...
local HI = ns.HealingIntel or {}
ns.HealingIntel = HI

HI.design_principles = {
    "Do not assume class implies healer.",
    "Do not assume helpful-flagged spells are the only healing actions.",
    "Use player-tagged roles as source of truth; use heuristics only as suggestions.",
    "Support direct-heal, HoT, shield, damage-to-heal, cleanse, resurrection, proc-heal and cooldown patterns.",
}

HI.roleSpellIds = {
    direct_heal = { 2050, 2054, 2060, 2061, 635, 19750, 331, 8004, 8005, 5185, 8936, 50464, 1064, 596, 34861, 48785 },
    hot = { 139, 774, 33763, 48438, 61295, 33076 },
    shield_absorb = { 17, 47515, 53563, 53601, 974 },
    cleanse = { 4987, 527, 528, 552, 475, 2782, 2893, 8946, 51886 },
    resurrection = { 2006, 7328, 50769, 20484, 20773 },
    support = { 33206, 47788, 29166, 10060, 16190, 29166, 6940, 1022, 1044, 53563 },
    damage_to_heal = { 20473, 635, 585, 20271 },
}

HI.roleSpellNames = {
    direct_heal = {
        "Heal", "Lesser Heal", "Greater Heal", "Flash Heal", "Binding Heal", "Penance",
        "Holy Light", "Flash of Light", "Holy Shock", "Healing Wave", "Lesser Healing Wave",
        "Healing Touch", "Regrowth", "Nourish", "Chain Heal", "Prayer of Healing", "Circle of Life"
    },
    hot = {
        "Renew", "Rejuvenation", "Lifebloom", "Wild Growth", "Riptide", "Prayer of Mending"
    },
    shield_absorb = {
        "Power Word: Shield", "Sacred Shield", "Earth Shield", "Divine Aegis", "Beacon of Light"
    },
    cleanse = {
        "Cleanse", "Purify", "Cure Disease", "Abolish Disease", "Remove Curse",
        "Abolish Poison", "Cure Poison", "Cleanse Spirit", "Dispel Magic"
    },
    resurrection = {
        "Resurrection", "Redemption", "Revive", "Rebirth", "Ancestral Spirit"
    },
    support = {
        "Pain Suppression", "Guardian Spirit", "Innervate", "Power Infusion", "Mana Tide Totem",
        "Hand of Sacrifice", "Hand of Protection", "Hand of Freedom", "Beacon of Light"
    },
    damage_to_heal = {
        "Holy Shock", "Judgement", "Smite", "Atonement"
    },
}

HI.keywordRoles = {
    direct_heal = { "heal", "holy light", "flash of light", "flash heal", "healing wave", "lesser healing wave", "chain heal", "nourish", "regrowth", "healing touch", "circle of life" },
    hot = { "renew", "rejuvenation", "lifebloom", "wild growth", "riptide", "prayer of mending" },
    shield_absorb = { "power word: shield", "sacred shield", "earth shield", "beacon of light" },
    cleanse = { "cleanse", "purify", "abolish", "remove curse", "cure", "dispel", "cleanse spirit" },
    resurrection = { "resurrection", "redemption", "rebirth", "ancestral spirit", "revive" },
    support = { "beacon", "sacred", "pain suppression", "guardian spirit", "innervate", "divine hymn", "mana tide", "power infusion" },
    damage_to_heal = { "judgement", "smite", "holy shock", "atonement" },
}

HI.dispelAbilities = {
    Magic = { 4987, 527, 528 },
    Curse = { 475, 2782, 51886 },
    Disease = { 4987, 528, 552 },
    Poison = { 4987, 2893, 8946 },
}

HI.dispelColors = {
    Magic = { 0.20, 0.60, 1.00 },
    Curse = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison = { 0.00, 0.75, 0.20 },
}

HI.dispelPriority = { "Magic", "Curse", "Disease", "Poison" }

HI.statHints = {
    { id = "spirit", note = "Common sustain and mana-regeneration priority in many healer discussions." },
    { id = "intellect", note = "Common throughput/scaling stat." },
    { id = "spell_power", note = "Direct throughput signal for many builds." },
    { id = "crit", note = "Useful for some healing variants." },
    { id = "haste", note = "Useful for cast-time and HoT cadence builds." },
}

HI.knownSpellRolesById = {}
HI.knownSpellRolesByName = {}

local function addRole(role, id)
    if id then
        HI.knownSpellRolesById[id] = role
        local name = GetSpellInfo and GetSpellInfo(id)
        if name and name ~= "" then
            HI.knownSpellRolesByName[string.lower(name)] = role
        end
    end
end

for role, ids in pairs(HI.roleSpellIds) do
    for _, id in ipairs(ids) do addRole(role, id) end
end
for role, names in pairs(HI.roleSpellNames) do
    for _, name in ipairs(names) do
        HI.knownSpellRolesByName[string.lower(name)] = role
    end
end


HI.defaultRangeSpells = { "Flash of Light", "Flash Heal", "Heal", "Holy Light", "Healing Wave", "Lesser Healing Wave", "Riptide", "Rejuvenation", "Renew", "Nourish", "Chain Heal", "Cleanse", "Purify", "Dispel Magic" }

HI.healingRoles = {
    direct_heal = true,
    hot = true,
    shield_absorb = true,
    damage_to_heal = true,
    cleanse = true,
    resurrection = true,
    support = true,
}
