local _, ns = ...
local PetFrames = ns:RegisterModule("PetFrames", {})
ns.PetFrames = PetFrames

PetFrames.container = nil
PetFrames.buttons = {}
PetFrames.unitButtons = {}
PetFrames.MAX = 40
PetFrames.queue = {}
PetFrames.fakeEnabled = false
PetFrames.fakeDriver = CreateFrame("Frame")
PetFrames.fakeDriver:Hide()
PetFrames.fakeDriver.accum = 0
PetFrames.fakeDriver:SetScript("OnUpdate", function(_, elapsed)
    PetFrames:OnFakeUpdate(elapsed)
end)

local SOLID_TEX = "Interface\\Buttons\\WHITE8X8"
local STATUS_BAR_TEX = "Interface\\TargetingFrame\\UI-StatusBar"
local classColors = RAID_CLASS_COLORS or {}

local testPetNames = {
    "Fluffy", "Whiskers", "Chomper", "Bitey", "Shadowfiend", "Gargoyle",
    "Water Elemental", "Treant", "Spirit Wolf", "Felguard", "Voidwalker",
    "Imp", "Succubus", "Ghoul", "Army of the Dead", "Snake Trap",
    "Explosive Trap", "Fire Elemental", "Earth Elemental", "Mirror Image",
    "Rune Weapon", "Bloodworm", "Treant", "Shadowfiend", "Imp",
    "Felhunter", "Doomguard", "Infernal", "Void Tentacle", "Spirit Link",
    "Ancestral Spirit", "Healing Stream", "Mana Tide", "Searing", "Magma",
    "Wrath", "Fire", "Earth", "Stoneclaw"
}

local function unpackColor(t, default)
    if type(t) == "table" then return t[1] or 1, t[2] or 1, t[3] or 1 end
    return unpack(default or {1,1,1})
end

local function healthColor(pct)
    local f = ns.DB.frame
    local crit = f.criticalThreshold or 35
    local inj = f.injuredThreshold or 70
    if pct <= crit then return unpackColor(f.criticalColor, {0.95, 0.15, 0.15})
    elseif pct <= inj then return unpackColor(f.injuredColor, {0.95, 0.82, 0.20})
    else return unpackColor(f.healthyColor, {0.15, 0.78, 0.22}) end
end

local function registerPetButtonUnit(btn, unit)
    if btn.unit and PetFrames.unitButtons[btn.unit] == btn then
        PetFrames.unitButtons[btn.unit] = nil
    end
    btn.unit = unit
    if unit then
        PetFrames.unitButtons[unit] = btn
    end
end

local function setPetUnit(btn, unit)
    if InCombatLockdown() then
        PetFrames.queue[btn] = unit
    else
        ns:SafeSetAttribute(btn, "unit", unit)
        registerPetButtonUnit(btn, unit)
        PetFrames.queue[btn] = nil
    end
end

local function processPetQueue()
    if InCombatLockdown() then return end
    for btn, unit in pairs(PetFrames.queue) do
        ns:SafeSetAttribute(btn, "unit", unit)
        registerPetButtonUnit(btn, unit)
        PetFrames.queue[btn] = nil
    end
end

local function CreatePetButton(i)
    local b = CreateFrame("Button", "PB_HF_PetButton"..i, PetFrames.container, "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate")
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("type2", "target")
    b.index = i
    b.isPet = true

    b:SetAttribute("_onenter", [=[
        self:ClearBindings()
        self:SetBindingClick(0, "MOUSEWHEELUP", self:GetName(), "Button6")
        self:SetBindingClick(0, "MOUSEWHEELDOWN", self:GetName(), "Button7")
        self:SetBindingClick(0, "SHIFT-MOUSEWHEELUP", self:GetName(), "Shift-Button6")
        self:SetBindingClick(0, "SHIFT-MOUSEWHEELDOWN", self:GetName(), "Shift-Button7")
        self:SetBindingClick(0, "CTRL-MOUSEWHEELUP", self:GetName(), "Ctrl-Button6")
        self:SetBindingClick(0, "CTRL-MOUSEWHEELDOWN", self:GetName(), "Ctrl-Button7")
        self:SetBindingClick(0, "ALT-MOUSEWHEELUP", self:GetName(), "Alt-Button6")
        self:SetBindingClick(0, "ALT-MOUSEWHEELDOWN", self:GetName(), "Alt-Button7")
    ]=])
    b:SetAttribute("_onleave", [=[
        self:ClearBindings()
    ]=])

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(SOLID_TEX)
    bg:SetVertexColor(0, 0, 0, 0.95)
    b.bg = bg

    local border = b:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetTexture(0, 0, 0, 1)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    b.border = border

    local shine = b:CreateTexture(nil, "OVERLAY", nil, 1)
    shine:SetPoint("TOPLEFT", 1, -1)
    shine:SetPoint("BOTTOMRIGHT", -1, 1)
    shine:SetTexture(1, 1, 1, 0.08)
    shine:SetBlendMode("ADD")
    b.shine = shine

    local hp = CreateFrame("StatusBar", nil, b)
    hp:SetPoint("TOPLEFT", 1, -1)
    hp:SetPoint("BOTTOMRIGHT", -1, 1)
    hp:SetFrameLevel(b:GetFrameLevel() + 1)
    hp:SetStatusBarTexture(STATUS_BAR_TEX)
    b.hp = hp

    local incHealOthers = CreateFrame("StatusBar", nil, b)
    incHealOthers:SetPoint("TOPLEFT", 1, -1)
    incHealOthers:SetPoint("BOTTOMRIGHT", -1, 1)
    incHealOthers:SetFrameLevel(b:GetFrameLevel() + 2)
    incHealOthers:SetStatusBarTexture(STATUS_BAR_TEX)
    incHealOthers:SetStatusBarColor(0.0, 0.5, 1.0, 0.35)
    b.incHealOthers = incHealOthers

    local incHealMine = CreateFrame("StatusBar", nil, b)
    incHealMine:SetPoint("TOPLEFT", 1, -1)
    incHealMine:SetPoint("BOTTOMRIGHT", -1, 1)
    incHealMine:SetFrameLevel(b:GetFrameLevel() + 3)
    incHealMine:SetStatusBarTexture(STATUS_BAR_TEX)
    incHealMine:SetStatusBarColor(0.2, 1.0, 0.2, 0.45)
    b.incHealMine = incHealMine

    local overlayLayer = CreateFrame("Frame", nil, b)
    overlayLayer:SetPoint("TOPLEFT", 1, -1)
    overlayLayer:SetPoint("BOTTOMRIGHT", -1, 1)
    overlayLayer:SetFrameLevel(b:GetFrameLevel() + 5)
    overlayLayer:EnableMouse(false)
    b.overlayLayer = overlayLayer

    local overlay = overlayLayer:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints()
    overlay:SetTexture(SOLID_TEX)
    overlay:SetBlendMode("BLEND")
    overlay:Hide()
    b.statusOverlay = overlay

    local statusPattern = overlayLayer:CreateTexture(nil, "OVERLAY", nil, 1)
    statusPattern:SetAllPoints()
    statusPattern:SetTexture("Interface\\ScanningConsole\\ScanningConsole-Volumetrics")
    statusPattern:SetAlpha(0.25)
    statusPattern:SetBlendMode("ADD")
    statusPattern:Hide()
    b.statusPattern = statusPattern

    local glow = CreateFrame("Frame", nil, b)
    glow:SetPoint("TOPLEFT", -1, 1)
    glow:SetPoint("BOTTOMRIGHT", 1, -1)
    glow:SetFrameLevel(b:GetFrameLevel() + 8)
    glow:EnableMouse(false)
    local borderTop = glow:CreateTexture(nil, "OVERLAY")
    borderTop:SetPoint("TOPLEFT"); borderTop:SetPoint("TOPRIGHT"); borderTop:SetHeight(1)
    local borderBottom = glow:CreateTexture(nil, "OVERLAY")
    borderBottom:SetPoint("BOTTOMLEFT"); borderBottom:SetPoint("BOTTOMRIGHT"); borderBottom:SetHeight(1)
    local borderLeft = glow:CreateTexture(nil, "OVERLAY")
    borderLeft:SetPoint("TOPLEFT"); borderLeft:SetPoint("BOTTOMLEFT"); borderLeft:SetWidth(1)
    local borderRight = glow:CreateTexture(nil, "OVERLAY")
    borderRight:SetPoint("TOPRIGHT"); borderRight:SetPoint("BOTTOMRIGHT"); borderRight:SetWidth(1)
    glow.SetBorderColor = function(self, r, g, bl, a)
        borderTop:SetTexture(r, g, bl, a)
        borderBottom:SetTexture(r, g, bl, a)
        borderLeft:SetTexture(r, g, bl, a)
        borderRight:SetTexture(r, g, bl, a)
    end
    glow:Hide()
    b.glow = glow

    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetTexture(1, 1, 1, 0.1)
    hover:SetBlendMode("ADD")
    b.hover = hover

    local inter = CreateFrame("Frame", nil, b)
    inter:SetAllPoints()
    inter:SetFrameLevel(b:GetFrameLevel() + 15)
    inter:EnableMouse(false)
    b.inter = inter

    local statusText = inter:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOM", 0, 2)
    statusText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    b.statusText = statusText

    local name = inter:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("CENTER", 0, 2)
    name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    name:SetShadowOffset(1, -1)
    name:SetTextColor(1, 1, 1)
    name:SetNonSpaceWrap(false)
    b.nameText = name

    local petIcon = inter:CreateTexture(nil, "OVERLAY")
    petIcon:SetSize(12, 12)
    petIcon:SetPoint("TOPLEFT", 2, -2)
    petIcon:SetTexture("Interface\\Icons\\Ability_Hunter_PetReview")
    petIcon:SetAlpha(0.6)
    b.petIcon = petIcon

    local mana = CreateFrame("StatusBar", nil, b)
    mana:SetStatusBarTexture(STATUS_BAR_TEX)
    mana:SetFrameLevel(b:GetFrameLevel() + 3)
    b.mana = mana

    return b
end

local function ShortenName(name, maxChars)
    if not maxChars then maxChars = 10 end
    if not name or string.len(name) <= maxChars then return name end
    if maxChars <= 4 then
        return string.sub(name, 1, maxChars)
    elseif maxChars <= 6 then
        return string.sub(name, 1, 4) .. string.sub(name, -1, -1)
    else
        return string.sub(name, 1, maxChars - 1) .. "~"
    end
end

local function getDispelColor(dtype)
    local intel = ns.HealingIntel or {}
    local c = (ns.DB.frame and ns.DB.frame.dispelColors and ns.DB.frame.dispelColors[dtype]) or (intel.dispelColors and intel.dispelColors[dtype])
    if not c then
        if dtype == "Magic" then return {0.2, 0.6, 1}
        elseif dtype == "Curse" then return {0.6, 0, 1}
        elseif dtype == "Poison" then return {0, 0.6, 0}
        elseif dtype == "Disease" then return {0.6, 0.4, 0}
        end
    end
    return c or { 1, 0, 1 }
end

local function getCurableDebuff(unit)
    local intel = ns.HealingIntel or {}
    local prio = (ns.DB.frame and ns.DB.frame.dispelPriority) or intel.dispelPriority or {"Magic", "Curse", "Poison", "Disease"}
    local best
    for i = 1, 40 do
        local name, _, icon, count, dtype, duration, expirationTime = UnitDebuff(unit, i)
        if not name then break end
        if dtype and ns.SpellBook and ns.SpellBook:PlayerCanDispel(dtype) then
            local rank = 999
            for idx, d in ipairs(prio) do if d == dtype then rank = idx break end end
            if not best or rank < best.rank then
                best = { name = name, texture = icon, dtype = dtype, rank = rank, duration = duration, expires = expirationTime, count = count }
            end
        end
    end
    return best
end

local function IsUnitInHealRange(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") or UnitIsUnit(unit, "pet") then return true end
    if UnitIsDeadOrGhost(unit) then return true end
    local spell
    if ns.SpellBook and ns.SpellBook.GetRangeSpellName then
        spell = ns.SpellBook:GetRangeSpellName()
    end
    if spell then
        local r = ns.Compat:IsSpellInRange(spell, unit)
        if r == 1 then return true end
        if r == 0 then return false end
    end
    return true
end

function PetFrames:UpdateButton(b)
    if not ns.DB.enabled then
        if not InCombatLockdown() then b:Hide() end
        return
    end
    local unit = b.unit
    local fake = b.fakeData

    if fake then
        local name = fake.name
        local maxhp = 100
        local t = GetTime()
        local hpVal = math.floor(20 + (math.sin(t + (b.index or 0)*0.7) + 1) * 35)
        local pct = math.floor((hpVal / maxhp) * 100)
        local debuff = nil
        if fake.fakeDebuff then debuff = { dtype = fake.fakeDebuff } end

        b.nameText:SetText(ShortenName(name, ns.DB.frame.bars and ns.DB.frame.bars.nameLength or 10))

        b.hp:SetMinMaxValues(0, maxhp)
        b.incHealMine:SetMinMaxValues(0, maxhp)
        b.incHealOthers:SetMinMaxValues(0, maxhp)

        local r, g, bl = healthColor(pct)
        b.nameText:SetTextColor(0.6, 0.8, 1.0)

        local tex = ns.DB.frame.barTexture or STATUS_BAR_TEX
        b.hp:SetStatusBarTexture(tex)
        b.incHealMine:SetStatusBarTexture(tex)
        b.incHealOthers:SetStatusBarTexture(tex)

        if ns.DB.frame.invertedColors then
            b.bg:SetVertexColor(r, g, bl, 0.9)
            b.hp:SetStatusBarColor(0, 0, 0, 0.8)
            b.hp:SetValue(maxhp - hpVal)
        else
            b.bg:SetVertexColor(0, 0, 0, 0.95)
            b.hp:SetStatusBarColor(r, g, bl, 0.9)
            b.hp:SetValue(hpVal)
        end

        b.incHealMine:SetValue(0)
        b.incHealMine:Hide()
        b.incHealOthers:SetValue(0)
        b.incHealOthers:Hide()

        if debuff and debuff.dtype and ns.DB.frame.highlightCurableDebuffs then
            local dc = getDispelColor(debuff.dtype)
            b.statusOverlay:SetVertexColor(dc[1], dc[2], dc[3], 0.45)
            b.statusOverlay:Show()
            b.glow:SetBorderColor(dc[1], dc[2], dc[3], 1)
            b.glow:Show()
        else
            b.statusOverlay:Hide()
            b.glow:Hide()
        end

        local stText
        if hpVal < maxhp and ns.DB.frame.showDeficit ~= false then
            local diff = maxhp - hpVal
            stText = "-" .. diff
        else
            stText = pct .. "%"
        end
        b.statusText:SetText(stText)

        b:SetAlpha(1)
        local hc = ns.DB.frame.hoverColor or {1, 1, 1, 0.1}
        b.hover:SetVertexColor(hc[1], hc[2], hc[3], hc[4] or 0.1)

        b:Show()
        return
    end

    if not unit or not UnitExists(unit) then
        if not InCombatLockdown() then b:Hide() end
        return
    end

    local dbf = ns.DB.frame
    local name = UnitName(unit) or "Pet"
    local hpVal = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    maxhp = (maxhp > 0) and maxhp or 1
    local pct = math.floor((hpVal / maxhp) * 100)
    local mana, maxmana = UnitPower(unit), UnitPowerMax(unit)
    local debuff = getCurableDebuff(unit)
    b.curableDebuff = debuff

    b.nameText:SetText(ShortenName(name, dbf.bars and dbf.bars.nameLength or 10))

    b.hp:SetMinMaxValues(0, maxhp)
    b.incHealMine:SetMinMaxValues(0, maxhp)
    b.incHealOthers:SetMinMaxValues(0, maxhp)

    local r, g, bl = healthColor(pct)
    b.nameText:SetTextColor(0.6, 0.8, 1.0)

    local tex = dbf.barTexture or STATUS_BAR_TEX
    b.hp:SetStatusBarTexture(tex)
    b.incHealMine:SetStatusBarTexture(tex)
    b.incHealOthers:SetStatusBarTexture(tex)

    if dbf.invertedColors then
        b.bg:SetVertexColor(r, g, bl, 0.9)
        b.hp:SetStatusBarColor(0, 0, 0, 0.8)
        b.hp:SetValue(maxhp - hpVal)
        b.incHealMine:SetStatusBarColor(0.2, 1.0, 0.2, 0.35)
        b.incHealOthers:SetStatusBarColor(0.0, 0.5, 1.0, 0.25)
    else
        b.bg:SetVertexColor(0, 0, 0, 0.95)
        b.hp:SetStatusBarColor(r, g, bl, 0.9)
        b.hp:SetValue(hpVal)
        b.incHealMine:SetStatusBarColor(0.2, 1.0, 0.2, 0.45)
        b.incHealOthers:SetStatusBarColor(0.0, 0.5, 1.0, 0.35)
    end

    if debuff and debuff.dtype and dbf.highlightCurableDebuffs then
        local dc = getDispelColor(debuff.dtype)
        b.statusOverlay:SetVertexColor(dc[1], dc[2], dc[3], 0.45)
        b.statusOverlay:Show()
        b.glow:SetBorderColor(dc[1], dc[2], dc[3], 1)
        b.glow:Show()
    else
        b.statusOverlay:Hide()
        b.glow:Hide()
    end

    local status
    if UnitIsDeadOrGhost(unit) then status = "DEAD"
    elseif not UnitIsConnected(unit) then status = "OFFLINE" end

    local stText = status
    if not stText then
        if hpVal < maxhp and dbf.showDeficit ~= false then
            local diff = maxhp - hpVal
            if diff >= 1000 then
                stText = string.format("-%.1fk", diff / 1000)
            else
                stText = "-" .. diff
            end
        else
            stText = pct .. "%"
        end
    end
    b.statusText:SetText(stText)

    if b.mana:IsShown() then
        b.mana:SetMinMaxValues(0, maxmana or 1)
        b.mana:SetValue(mana or 0)
        b.mana:SetStatusBarColor(0.2, 0.4, 1.0)
    end

    local inRange = IsUnitInHealRange(unit)
    b:SetAlpha(inRange and 1 or (dbf.outOfRangeAlpha or 0.35))

    local hc = dbf.hoverColor or {1, 1, 1, 0.1}
    b.hover:SetVertexColor(hc[1], hc[2], hc[3], hc[4] or 0.1)

    if ns.HealComm then ns.HealComm:UpdateUnit(b) end
end

function PetFrames:UpdateAll()
    for _, b in ipairs(self.buttons) do
        if b:IsShown() and (b.unit or b.fakeData) then
            self:UpdateButton(b)
        end
    end
end

function PetFrames:OnFakeUpdate(elapsed)
    if not self.fakeEnabled or not self.fakeDriver then return end
    if InCombatLockdown() then return end
    self.fakeDriver.accum = (self.fakeDriver.accum or 0) + elapsed
    if self.fakeDriver.accum < 0.05 then return end
    self.fakeDriver.accum = 0
    for _, b in ipairs(self.buttons) do
        if b.fakeData and b:IsShown() then
            self:UpdateButton(b)
        end
    end
end

function PetFrames:SetFakeUpdatesEnabled(flag)
    if not self.fakeDriver then return end
    self.fakeEnabled = flag and true or false
    self.fakeDriver.accum = 0
    if flag then
        self.fakeDriver:Show()
    else
        self.fakeDriver:Hide()
    end
end

function PetFrames:CreateContainer()
    if self.container then return end
    local f = CreateFrame("Frame", "PB_HF_PetAnchor", UIParent)
    f:SetSize(200, 100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    local dbf = ns.DB.frame
    local pos = dbf.petPanelPosition
    if pos and pos.x then
        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    else
        f:SetPoint("CENTER", -300, 0)
    end

    f:SetScript("OnDragStart", function(s) if InCombatLockdown() then return end; if not ns.DB.locked then s:StartMoving() end end)
    f:SetScript("OnDragStop", function(s)
        if InCombatLockdown() then return end
        s:StopMovingOrSizing()
        local x, y = s:GetLeft(), s:GetBottom()
        ns.DB.frame.petPanelPosition = { x = x, y = y }
    end)

    if not f.bg then
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.4)
        f.bg = bg
    end

    if not f.label then
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("CENTER")
        f.label = lbl
    end
    f.label:SetText("PB:HF Pets")

    self.container = f
end

function PetFrames:ApplyLayout()
    if InCombatLockdown() then
        self._layoutPending = true
        return
    end

    if not ns.DB.frame.showPetPanel then
        if self.container then self.container:Hide() end
        for _, b in ipairs(self.buttons) do b:Hide() end
        return
    end

    self:CreateContainer()

    local dbf = ns.DB.frame
    local isGrid = dbf.layoutStyle == "grid"
    local cfg = isGrid and dbf.grid or dbf.bars
    local tex = dbf.barTexture or STATUS_BAR_TEX
    local scale = cfg.scale or 1

    self.container:SetScale(scale)

    local isUnlocked = not ns.DB.locked
    if isUnlocked then
        self.container.bg:Show()
        self.container.label:Show()
    else
        self.container.bg:Hide()
        self.container.label:Hide()
    end

    local entries = ns.Roster.petEntries or {}
    local spacing = cfg.spacing or 4
    local countInGroup = {}

    for i = 1, self.MAX do
        local b = self.buttons[i] or CreatePetButton(i)
        self.buttons[i] = b

        b.hp:SetStatusBarTexture(tex)
        b.incHealMine:SetStatusBarTexture(tex)
        b.incHealOthers:SetStatusBarTexture(tex)

        local entry = entries[i]
        if entry and (entry.fake or (entry.unit and UnitExists(entry.unit) and UnitPlayerControlled(entry.unit))) then
            if entry.fake then
                b.fakeData = entry
                setPetUnit(b, nil)
            else
                b.fakeData = nil
                setPetUnit(b, entry.unit)
            end
            b:ClearAllPoints()

            local group = entry.group or 1
            countInGroup[group] = (countInGroup[group] or 0) + 1
            local unitIndex = countInGroup[group] - 1

            if isGrid then
                local unitsPerLine = math.max(1, math.floor(cfg.columns or 5))
                local col = unitIndex % unitsPerLine
                local row = math.floor(unitIndex / unitsPerLine)
                local size = cfg.size or 40
                local x = 8 + col * (size + spacing)
                local y = -8 - row * (size + spacing)
                b:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, y)
                b:SetSize(size, size)
                b.nameText:ClearAllPoints()
                b.nameText:SetPoint("TOP", b, "TOP", 0, -2)
                b.nameText:SetJustifyH("CENTER")
                b.statusText:Hide()
                b.border:Hide()
                b.shine:Hide()
            else
                local perRow = cfg.groupsPerRow or 4
                local groupSpacing = cfg.groupSpacing or 18
                local gCol = (group - 1) % perRow
                local gRow = math.floor((group - 1) / perRow)
                local width = cfg.width or 160
                local height = cfg.height or 20

                local unitsPerRow = math.max(1, math.floor(cfg.unitsPerRow or 1))
                local unitWidth = width + spacing
                local unitHeight = height + spacing
                local maxGroupSize = cfg.maxGroupSize or 5
                local groupRows = math.ceil(maxGroupSize / unitsPerRow)
                local groupWidth = unitsPerRow * unitWidth
                local groupHeight = groupRows * unitHeight
                local colInGroup = unitIndex % unitsPerRow
                local rowInGroup = math.floor(unitIndex / unitsPerRow)
                local groupBaseX = 8 + gCol * (groupWidth + groupSpacing)
                local groupBaseY = -8 - gRow * (groupHeight + groupSpacing)
                local x = groupBaseX + colInGroup * unitWidth
                local y = groupBaseY - rowInGroup * unitHeight
                b:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, y)
                b:SetSize(width, height)
                b.nameText:ClearAllPoints()
                b.nameText:SetPoint("TOP", b, "TOP", 0, -2)
                b.nameText:SetJustifyH("CENTER")
                b.statusText:Show()
                b.border:Show()
                b.shine:Show()
            end

            local mh = (dbf.showManaBar and (dbf.manaBarHeight or 3) or 0)
            if mh > 0 then
                b.mana:ClearAllPoints()
                b.mana:SetPoint("BOTTOMLEFT", 1, 1)
                b.mana:SetPoint("BOTTOMRIGHT", -1, 1)
                b.mana:SetHeight(mh)
                b.mana:Show()
            else
                b.mana:Hide()
            end

            b:Show()
            self:UpdateButton(b)
        else
            b:Hide()
            b.fakeData = nil
            setPetUnit(b, nil)
        end
    end

    local petCount = #entries
    if petCount > 0 then
        if isGrid then
            local cols = math.max(1, math.floor(cfg.columns or 5))
            local rows = math.ceil(petCount / cols)
            local size = cfg.size or 40
            self.container:SetSize(cols * (size + spacing) + 16, rows * (size + spacing) + 16)
        else
            local groups = {}
            local maxGroup = 0
            for _, entry in ipairs(entries) do
                local g = entry.group or 1
                groups[g] = (groups[g] or 0) + 1
                if g > maxGroup then maxGroup = g end
            end
            local perRow = cfg.groupsPerRow or 4
            local gCols = math.min(maxGroup, perRow)
            local gRows = math.ceil(maxGroup / perRow)
            local width = cfg.width or 160
            local height = cfg.height or 20
            local groupSpacing = cfg.groupSpacing or 18
            local maxUnitsPerGroup = 0
            for _, c in pairs(groups) do if c > maxUnitsPerGroup then maxUnitsPerGroup = c end end
            local groupHeight = math.ceil(maxUnitsPerGroup / math.max(1, cfg.unitsPerRow or 1)) * (height + spacing)
            self.container:SetSize(gCols * (width + groupSpacing) + 16, gRows * (groupHeight + groupSpacing) + 16)
        end
        self.container:Show()
    else
        self.container:SetSize(200, 100)
        self.container:Hide()
    end
end

function PetFrames:SetFakeMode(enabled, size)
    if not ns.DB.frame.showPetPanel then
        ns.DB.frame.showPetPanel = true
        ns:Print("Pet panel auto-enabled for test mode")
    end
    ns.DB.frame.fakePetMode = enabled
    ns.DB.frame.fakePetSize = size or 5
    if enabled then
        self:BuildFakePetList(ns.DB.frame.fakePetSize)
    else
        wipe(ns.Roster.petEntries)
        wipe(ns.Roster.tankPetMap)
        if ns.Roster then ns.Roster:Refresh() end
    end
    self:ApplyLayout()
    self:SetFakeUpdatesEnabled(enabled)
end

function PetFrames:BuildFakePetList(size)
    wipe(ns.Roster.petEntries)
    local debuffTypes = { "Magic", "Curse", "Poison", "Disease" }
    for i = 1, size do
        table.insert(ns.Roster.petEntries, {
            unit = nil,
            name = testPetNames[i] or ("Pet"..i),
            group = math.floor((i-1)/5) + 1,
            fake = true,
            fakeDebuff = (i % 3 == 0) and debuffTypes[math.floor((i/3)%4 + 1)] or nil,
            ownerUnit = ns.Roster.entries[math.min(i, #ns.Roster.entries)] and ns.Roster.entries[math.min(i, #ns.Roster.entries)].name or "Player"..i,
        })
    end
end

function PetFrames:OnInitialize()
end

function PetFrames:OnEnable()
    if ns.DB.frame.showPetPanel then
        self:ApplyLayout()
    end
end

function PetFrames:OnEvent(event, unit)
    if not ns.DB.frame.showPetPanel then return end

    if event == "PLAYER_ENTERING_WORLD" then
        self:ApplyLayout()
    elseif event == "PLAYER_REGEN_ENABLED" then
        processPetQueue()
        if self._layoutPending then
            self._layoutPending = nil
            self:ApplyLayout()
        end
    elseif event == "UNIT_PET" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        if ns.DB.frame.fakePetMode then return end
        if not InCombatLockdown() then
            self:ApplyLayout()
        else
            self._layoutPending = true
        end
    elseif unit then
        for _, b in ipairs(self.buttons) do
            if b.unit == unit then
                self:UpdateButton(b)
            end
        end
    end
end
