local _, ns = ...
local Frames = ns:RegisterModule("Frames", {})
ns.Frames = Frames

Frames.container = nil
Frames.groupAnchors = {}
Frames.buttons = {}
Frames.MAX = 40
Frames.testTicker = 0

local classColors = RAID_CLASS_COLORS or {}

local function unpackColor(t, default)
    if type(t) == "table" then return t[1] or 1, t[2] or 1, t[3] or 1 end
    return unpack(default or {1,1,1})
end

local function healthColor(pct)
    local f = ns.DB.frame
    if pct <= 35 then
        return unpackColor(f.criticalColor, {0.95, 0.15, 0.15})
    elseif pct <= 70 then
        return unpackColor(f.injuredColor, {0.95, 0.82, 0.20})
    else
        return unpackColor(f.healthyColor, {0.15, 0.78, 0.22})
    end
end

local function IsUnitInHealRange(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") or UnitIsUnit(unit, "pet") then return true end
    if UnitIsDeadOrGhost(unit) then return true end

    local spell = ns.SpellBook and ns.SpellBook:GetRangeSpellName()
    if spell then
        local r = ns.Compat:IsSpellInRange(spell, unit)
        if r == 1 then return true end
        if r == 0 then return false end
    end

    if UnitInRange and (UnitInParty(unit) or UnitInRaid(unit)) then
        local ok = UnitInRange(unit)
        if ok ~= nil then return ok and true or false end
    end
    return true
end

local function getCurableDebuff(unit)
    local intel = ns.HealingIntel or {}
    local prio = intel.dispelPriority or {}
    local best, firstTex
    for i = 1, 16 do
        local name, _, tex, _, dtype = UnitDebuff(unit, i)
        if tex and not firstTex then firstTex = tex end
        if name and dtype and ns.SpellBook and ns.SpellBook:PlayerCanDispel(dtype) then
            local rank = 999
            for idx, d in ipairs(prio) do if d == dtype then rank = idx break end end
            if not best or rank < best.rank then best = { name = name, texture = tex, dtype = dtype, rank = rank } end
        end
    end
    if best then return best end
    if firstTex then return { texture = firstTex } end
    return nil
end

local function CreateAnchor()
    local f = CreateFrame("Frame", "PainboyAnchor", UIParent)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", ns.DB.frame.x, ns.DB.frame.y)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", function(self)
        if ns.DB.locked then return end
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        ns.DB.frame.x = x
        ns.DB.frame.y = y
    end)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(0, 0, 0, 0.12)
    f:SetScript("OnUpdate", function(_, elapsed)
        if not (ns.DB and ns.DB.frame and ns.DB.frame.fakeMode) then return end
        Frames.testTicker = (Frames.testTicker or 0) + elapsed
        if Frames.testTicker < 0.12 then return end
        Frames.testTicker = 0
        for _, b in ipairs(Frames.buttons) do if b:IsShown() then Frames:UpdateButton(b) end end
    end)
    Frames.container = f
end

local function CreateGroupAnchor(index)
    local a = CreateFrame("Frame", "PainboyGroupAnchor"..index, UIParent)
    a:SetMovable(true)
    a:EnableMouse(true)
    a:RegisterForDrag("LeftButton")
    a:SetClampedToScreen(true)
    a.index = index
    a.label = a:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    a.label:SetPoint("TOPLEFT", 2, -2)
    a.label:SetText("G"..index)
    a:SetScript("OnDragStart", function(self)
        if ns.DB.locked or ns.DB.frame.layoutMode ~= "separate" then return end
        self:StartMoving()
    end)
    a:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        ns.DB.groupAnchors[index] = ns.DB.groupAnchors[index] or {}
        ns.DB.groupAnchors[index].x = x
        ns.DB.groupAnchors[index].y = y
    end)
    Frames.groupAnchors[index] = a
    return a
end

local function CreateButton(i)
    local b = CreateFrame("Button", "PainboyUnitButton" .. i, Frames.container, "SecureUnitButtonTemplate")
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("type2", "target")
    b:SetAttribute("*type1", "target")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(0.10, 0.10, 0.10, 0.85)
    b.bg = bg

    local hp = CreateFrame("StatusBar", nil, b)
    hp:SetPoint("TOPLEFT", 1, -1)
    hp:SetPoint("BOTTOMRIGHT", -1, 1)
    hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hp:SetMinMaxValues(0, 1)
    hp:SetValue(1)
    b.hp = hp

    local name = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", b, "LEFT", 6, 0)
    name:SetJustifyH("LEFT")
    b.nameText = name

    local value = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    value:SetJustifyH("RIGHT")
    b.valueText = value

    local status = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("CENTER", b, "CENTER", 0, 0)
    status:SetJustifyH("CENTER")
    b.statusText = status

    local mana = CreateFrame("StatusBar", nil, b)
    mana:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar")
    mana:SetMinMaxValues(0, 1)
    mana:SetValue(1)
    b.mana = mana

    local debuff = b:CreateTexture(nil, "OVERLAY")
    debuff:SetWidth(14)
    debuff:SetHeight(14)
    debuff:SetPoint("RIGHT", value, "LEFT", -3, 0)
    b.debuffIcon = debuff

    local glow = b:CreateTexture(nil, "BORDER")
    glow:SetAllPoints(true)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:Hide()
    b.aggro = glow

    b:SetFrameStrata("HIGH")
    b:SetScript("OnEnter", function(self)
        if self.unit and UnitExists(self.unit) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        elseif self.fakeData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.fakeData.name)
            GameTooltip:AddLine("Test mode preview", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

function Frames:GetGroupAnchor(index)
    if not self.groupAnchors[index] then CreateGroupAnchor(index) end
    return self.groupAnchors[index]
end

function Frames:RefreshGroupAnchors()
    local f = ns.DB.frame
    local width = f.width + 8
    local height = (f.height + f.spacing) * 5 + 8
    local perRow = math.max(1, f.groupsPerRow or 2)
    for i = 1, 8 do
        local a = self:GetGroupAnchor(i)
        a:SetScale(f.scale or 1)
        a:SetWidth(width)
        a:SetHeight(height)
        local saved = ns.DB.groupAnchors[i]
        if saved and saved.x and saved.y then
            a:ClearAllPoints()
            a:SetPoint("TOPLEFT", UIParent, "TOPLEFT", saved.x, saved.y)
        else
            local row = math.floor((i - 1) / perRow)
            local col = (i - 1) % perRow
            a:ClearAllPoints()
            a:SetPoint("TOPLEFT", self.container, "TOPLEFT", col * (f.width + f.groupSpacing), -row * (height + f.groupSpacing))
        end
        a.label:SetShown(not ns.DB.locked and f.layoutMode == "separate")
        a:SetAlpha((f.layoutMode == "separate") and 1 or 0)
        a:Show()
    end
end

function Frames:ApplyLayout(skipRoster)
    if not self.container then return end
    local dbf = ns.DB.frame
    self.container:SetScale(dbf.scale or 1)
    for _, b in ipairs(self.buttons) do
        local mh = (dbf.showManaBar and (dbf.manaBarHeight or 3) or 0)
        b:SetWidth(dbf.width)
        b:SetHeight(dbf.height + mh)
        b.hp:ClearAllPoints()
        b.hp:SetPoint("TOPLEFT", 1, -1)
        b.hp:SetPoint("BOTTOMRIGHT", -1, 1 + mh)
        b.mana:ClearAllPoints()
        if mh > 0 then
            b.mana:SetPoint("BOTTOMLEFT", 1, 1)
            b.mana:SetPoint("BOTTOMRIGHT", -1, 1)
            b.mana:SetHeight(mh)
            b.mana:Show()
        else
            b.mana:Hide()
        end
        b.nameText:SetWidth(math.max(40, dbf.width - 56))
        b.valueText:SetWidth(34)
        if dbf.showHealthText then b.valueText:Show() else b.valueText:Hide() end
        if dbf.showStatusText then b.statusText:Show() else b.statusText:Hide() end
    end
    self:RefreshGroupAnchors()
    if not skipRoster then self:ApplyRoster(true) end
end

function Frames:Ensure(skipLayout)
    if not self.container then CreateAnchor() end
    for i = 1, self.MAX do
        if not self.buttons[i] then self.buttons[i] = CreateButton(i) end
    end
    if not skipLayout then self:ApplyLayout(true) end
end

function Frames:ApplyRoster(skipEnsure)
    if not skipEnsure then self:Ensure(true) end
    local entries = ns.Roster.entries or {}
    local shown = 0
    local dbf = ns.DB.frame
    local countInGroup = {}

    for i = 1, self.MAX do
        local b = self.buttons[i]
        local entry = entries[i]
        if entry then
            shown = shown + 1
            local group = entry.group or 1
            countInGroup[group] = (countInGroup[group] or 0) + 1
            local idx = countInGroup[group]

            b:ClearAllPoints()
            b.fakeData = entry.fake and entry or nil
            b.unit = entry.unit
            if dbf.layoutMode == "separate" and group then
                local anchor = self:GetGroupAnchor(group)
                b:SetParent(anchor)
                b:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -(idx - 1) * (dbf.height + dbf.spacing))
            else
                b:SetParent(self.container)
                local perRow = math.max(1, dbf.groupsPerRow or 2)
                local col = math.floor((group - 1) % perRow)
                local row = math.floor((group - 1) / perRow)
                local x = 8 + col * (dbf.width + dbf.groupSpacing)
                local y = -8 - row * ((dbf.height + dbf.spacing) * 5 + dbf.groupSpacing) - (idx - 1) * (dbf.height + dbf.spacing)
                b:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, y)
            end
            b:SetAttribute("unit", entry.unit)
            b:Show()
            self:UpdateButton(b)
        else
            b.fakeData = nil
            b.unit = nil
            b:SetAttribute("unit", nil)
            b:Hide()
        end
    end

    local maxGroup = 1
    for _, e in ipairs(entries) do if e.group and e.group > maxGroup then maxGroup = e.group end end
    local rows = math.max(1, math.ceil(maxGroup / math.max(1, dbf.groupsPerRow or 2)))
    self.container:SetWidth((dbf.width * math.max(1, dbf.groupsPerRow or 2)) + (dbf.groupSpacing * math.max(0, (dbf.groupsPerRow or 2) - 1)) + 16)
    self.container:SetHeight(math.max(60, rows * ((dbf.height + dbf.spacing) * 5 + dbf.groupSpacing) + 16))
    if ns.ClickCast then ns.ClickCast:RefreshAll() end
end

function Frames:UpdateButton(b)
    local unit = b.unit
    local fake = b.fakeData
    local dbf = ns.DB.frame
    local name, hp, maxhp, pct, debuff, mana, maxmana, status

    if fake then
        name = fake.name
        maxhp = 100
        local t = GetTime() + (fake.group * 0.37)
        hp = math.floor(25 + (math.sin(t + (string.len(name) * 0.4)) + 1) * 37.5)
        pct = math.floor((hp / maxhp) * 100)
        debuff = (pct < 40 and { texture = "Interface\\Icons\\Spell_Nature_AbolishMagic", dtype = "Magic" }) or nil
        local cc = classColors[fake.classToken]
        if cc then b.nameText:SetTextColor(cc.r or 1, cc.g or 1, cc.b or 1) else b.nameText:SetTextColor(1,1,1) end
    else
        if not unit or not UnitExists(unit) then b:Hide() return end
        name = UnitName(unit) or unit
        hp = UnitHealth(unit) or 0
        maxhp = UnitHealthMax(unit) or 1
        mana = UnitMana and UnitMana(unit) or 0
        maxmana = UnitManaMax and UnitManaMax(unit) or 0
        if maxhp < 1 then maxhp = 1 end
        pct = math.floor((hp / maxhp) * 100)
    end

    b:Show()
    b:SetFrameLevel((self.container:GetFrameLevel() or 1) + 5)
    b.hp:SetMinMaxValues(0, maxhp)
    b.hp:SetValue(hp)
    if b.mana and ns.DB.frame.showManaBar and maxmana and maxmana > 0 and UnitPowerType and (not unit or UnitPowerType(unit) == 0 or fake) then
        b.mana:SetMinMaxValues(0, maxmana)
        b.mana:SetValue(mana or 0)
        b.mana:SetStatusBarColor(0.20, 0.45, 0.95, 0.95)
        b.mana:Show()
    elseif b.mana then
        b.mana:Hide()
    end
    b.nameText:SetText(name)
    b.valueText:SetText(dbf.showHealthText and (pct .. "%") or "")

    local barR, barG, barB = 0.15, 0.78, 0.22
    if dbf.useHealthGradient then barR, barG, barB = healthColor(pct) end
    local borderR, borderG, borderB = 1, 0, 0
    local showBorder = false

    if fake then
        b.bg:SetTexture(0.10, 0.10, 0.10, 0.85)
        if debuff and dbf.highlightCurableDebuffs then
            local c = (ns.HealingIntel and ns.HealingIntel.dispelColors and ns.HealingIntel.dispelColors[debuff.dtype]) or {1,0,1}
            barR, barG, barB = c[1], c[2], c[3]
            borderR, borderG, borderB = c[1], c[2], c[3]
            showBorder = true
            b.debuffIcon:SetTexture(debuff.texture)
            b.debuffIcon:Show()
        else
            b.debuffIcon:Hide()
        end
    elseif UnitIsDeadOrGhost(unit) then
        b.bg:SetTexture(0.25, 0.25, 0.25, 0.85)
        barR, barG, barB = 0.20, 0.20, 0.20
        b.nameText:SetTextColor(0.6, 0.6, 0.6)
        status = "DEAD"
    elseif not UnitIsConnected(unit) then
        b.bg:SetTexture(0.20, 0.12, 0.12, 0.85)
        barR, barG, barB = 0.4, 0.1, 0.1
        b.nameText:SetTextColor(0.8, 0.4, 0.4)
        status = "OFFLINE"
    else
        b.bg:SetTexture(0.10, 0.10, 0.10, 0.85)
        if dbf.classColorNames and RAID_CLASS_COLORS and unit and UnitClass then
            local _, class = UnitClass(unit)
            local cc = class and RAID_CLASS_COLORS[class]
            if cc then b.nameText:SetTextColor(cc.r, cc.g, cc.b) else b.nameText:SetTextColor(1,1,1) end
        else
            b.nameText:SetTextColor(1, 1, 1)
        end
        if UnitIsAFK and UnitIsAFK(unit) then status = "AFK" end
        debuff = getCurableDebuff(unit)
        if debuff and debuff.dtype and dbf.highlightCurableDebuffs then
            local c = (ns.HealingIntel and ns.HealingIntel.dispelColors and ns.HealingIntel.dispelColors[debuff.dtype]) or {1,0,1}
            barR, barG, barB = c[1], c[2], c[3]
            borderR, borderG, borderB = c[1], c[2], c[3]
            showBorder = true
        end
        if debuff and debuff.texture then
            b.debuffIcon:SetTexture(debuff.texture)
            b.debuffIcon:Show()
        else
            b.debuffIcon:Hide()
        end
    end

    b.hp:SetStatusBarColor(barR, barG, barB, 0.95)
    if b.statusText then b.statusText:SetText(dbf.showStatusText and (status or "") or "") end

    local isSelf = fake and false or (unit and UnitIsUnit(unit, "player"))
    local inRange = fake and true or (isSelf and true or IsUnitInHealRange(unit))
    if isSelf then
        b:SetFrameStrata("DIALOG")
        b:SetFrameLevel((self.container:GetFrameLevel() or 1) + 25)
    else
        b:SetFrameStrata("HIGH")
    end
    b:SetAlpha(inRange and 1 or (dbf.outOfRangeAlpha or 0.35))
    local textAlpha = inRange and 1 or (dbf.outOfRangeTextAlpha or 0.55)
    b.nameText:SetAlpha(textAlpha)
    b.valueText:SetAlpha(textAlpha)
    b.debuffIcon:SetAlpha(textAlpha)

    local hasAggro = (not fake and UnitThreatSituation and unit) and UnitThreatSituation("player", unit)
    if hasAggro and hasAggro >= 2 then
        b.aggro:SetVertexColor(1, 0, 0)
        b.aggro:Show()
    elseif showBorder then
        b.aggro:SetVertexColor(borderR, borderG, borderB)
        b.aggro:Show()
    else
        b.aggro:Hide()
    end
end

function Frames:OnEnable()
    self:Ensure(true)
    self:ApplyLayout(true)
    self:ApplyRoster(true)
end

function Frames:OnEvent(event, unit)
    if ns.DB and ns.DB.frame and ns.DB.frame.fakeMode and event ~= "PLAYER_ENTERING_WORLD" then
        for _, b in ipairs(self.buttons) do if b:IsShown() then self:UpdateButton(b) end end
        return
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_AURA" or event == "UNIT_FLAGS" or event == "UNIT_CONNECTION" then
        for _, b in ipairs(self.buttons) do
            if b.unit == unit then self:UpdateButton(b) end
        end
        return
    end
    for _, b in ipairs(self.buttons) do if b:IsShown() then self:UpdateButton(b) end end
end

function Frames:OnLeaveCombat()
    if self.container then self:ApplyRoster() end
end
