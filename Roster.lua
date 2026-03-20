local _, ns = ...
local Roster = ns:RegisterModule("Roster", {})
ns.Roster = Roster

Roster.units = {}
Roster.entries = {}

local testNames = {
    "Valawrath", "Thibodeauxz", "Aurelia", "Kargan", "Mistfen", "Cinderleaf", "Solenne", "Rimepaw",
    "Ashmantle", "Duskwhisper", "Goldhorn", "Lunessa", "Brightshield", "Mournroot", "Stormveil", "Hollowmere",
    "Sunwarden", "Emberwake", "Ravenmend", "Tidecaller", "Gloomvine", "Lightspire", "Frostmire", "Wildbloom",
    "Stonebind", "Dawnpetal", "Nightquill", "Ironbark", "Starward", "Sablemist", "Wispheart", "Netherdew",
    "Moonquartz", "Gravewillow", "Skydrift", "Thornwatch", "Silverreed", "Auricvale", "Dreamfen", "Brassroot"
}

local function buildFakeList(size)
    wipe(Roster.units)
    wipe(Roster.entries)
    for i = 1, size do
        local subgroup = math.floor((i - 1) / 5) + 1
        local role = ({"direct_heal", "hot", "shield_absorb", "support", "cleanse"})[((i - 1) % 5) + 1]
        local entry = {
            unit = nil,
            name = testNames[i] or ("Player" .. i),
            group = subgroup,
            fake = true,
            classToken = ({"PRIEST", "PALADIN", "SHAMAN", "DRUID", "MAGE", "WARLOCK", "ROGUE", "WARRIOR"})[((i - 1) % 8) + 1],
            role = role,
        }
        Roster.entries[#Roster.entries + 1] = entry
        Roster.units[#Roster.units + 1] = entry
    end
end

local function buildLiveList()
    wipe(Roster.units)
    wipe(Roster.entries)
    if UnitInRaid("player") then
        local count = GetNumRaidMembers() or 0
        for i = 1, count do
            local unit = "raid" .. i
            local _, _, subgroup = GetRaidRosterInfo(i)
            local entry = { unit = unit, group = subgroup or (math.floor((i - 1) / 5) + 1), fake = false }
            Roster.entries[#Roster.entries + 1] = entry
            Roster.units[#Roster.units + 1] = unit
        end
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
        local entry = { unit = "player", group = 1, fake = false }
        Roster.entries[#Roster.entries + 1] = entry
        Roster.units[#Roster.units + 1] = "player"
        local count = GetNumPartyMembers()
        for i = 1, count do
            local unit = "party" .. i
            entry = { unit = unit, group = 1, fake = false }
            Roster.entries[#Roster.entries + 1] = entry
            Roster.units[#Roster.units + 1] = unit
        end
    else
        local entry = { unit = "player", group = 1, fake = false }
        Roster.entries[#Roster.entries + 1] = entry
        Roster.units[#Roster.units + 1] = "player"
    end
end

function Roster:Refresh()
    if ns.DB and ns.DB.frame and ns.DB.frame.fakeMode then
        buildFakeList(ns.DB.frame.fakeSize or 10)
    else
        buildLiveList()
    end
    if ns.Frames then ns.Frames:ApplyRoster() end
end

function Roster:SetFakeMode(enabled, size)
    ns.DB.frame.fakeMode = enabled and true or false
    if size then ns.DB.frame.fakeSize = size end
    self:Refresh()
    if ns.UI_Bars and ns.UI_Bars.Refresh then ns.UI_Bars:Refresh() end
end

function Roster:OnEnable()
    self:Refresh()
end

function Roster:OnEvent(event)
    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        if not (ns.DB and ns.DB.frame and ns.DB.frame.fakeMode) then
            self:Refresh()
        end
    end
end
