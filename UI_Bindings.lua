
local _, ns = ...
local UIB = ns:RegisterModule("UI_Bindings", {})
ns.UI_Bindings = UIB

UIB.selectedSlot = "LeftButton"
UIB.slotButtons = {}
UIB.rows = {}
UIB.filterMode = "recommended"
UIB.searchText = ""

local panel

local function applyBackdrop(f)
    if not f.SetBackdrop then return end
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
end

local function createSlotButton(parent, idx)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(170)
    b:SetHeight(20)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -36 - (idx - 1) * 22)
    b:SetText("")
    b.slot = nil
    b:SetScript("OnClick", function(self)
        UIB.selectedSlot = self.slot
        UIB:RefreshSlots()
    end)
    return b
end

local function createRow(parent, idx)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(300)
    b:SetHeight(18)
    if idx == 1 then
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
    else
        b:SetPoint("TOPLEFT", UIB.rows[idx-1], "BOTTOMLEFT", 0, -1)
    end

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(true)
    hl:SetTexture(1, 1, 1, 0.08)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(16); icon:SetHeight(16)
    icon:SetPoint("LEFT", 2, 0)
    b.icon = icon

    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    txt:SetPoint("RIGHT", -2, 0)
    txt:SetJustifyH("LEFT")
    b.text = txt

    b:SetScript("OnClick", function(self)
        if not self.spellName then return end
        ns.Bindings:SetSpell(UIB.selectedSlot, self.spellName)
    end)
    return b
end

function UIB:GetFiltered()
    local out = {}
    local search = string.lower(self.searchText or "")
    for _, entry in ipairs(ns.SpellBook:GetBindable()) do
        local keep = true
        if search ~= "" and not string.find(string.lower(entry.name), search, 1, true) then
            keep = false
        end
        if keep and self.filterMode == "healing" then
            keep = entry.role == "direct_heal" or entry.role == "hot" or entry.role == "shield_absorb" or entry.role == "damage_to_heal"
        elseif keep and self.filterMode == "support" then
            keep = entry.role == "support" or entry.role == "cleanse" or entry.role == "shield_absorb"
        elseif keep and self.filterMode == "res" then
            keep = entry.role == "resurrection"
        elseif keep and self.filterMode == "recommended" then
            keep = entry.role ~= nil
        end
        if keep then out[#out + 1] = entry end
    end
    return out
end

function UIB:RefreshSpellList()
    if not panel then return end
    local list = self:GetFiltered()
    FauxScrollFrame_Update(panel.scroll, #list, #self.rows, 19)

    local offset = FauxScrollFrame_GetOffset(panel.scroll)
    for i = 1, #self.rows do
        local row = self.rows[i]
        local entry = list[i + offset]
        if entry then
            row.spellName = entry.name
            row.icon:SetTexture(entry.texture)
            local role = entry.role and (" |cff88ffaa[" .. entry.role .. "]|r") or ""
            row.text:SetText(entry.name .. role)
            row:Show()
        else
            row.spellName = nil
            row:Hide()
        end
    end

    panel.summary:SetText(string.format("raw=%d   bindable=%d   healing/support=%d", ns.SpellBook.stats.raw or 0, ns.SpellBook.stats.bindable or 0, ns.SpellBook.stats.healing or 0))
end

function UIB:RefreshSlots()
    if not panel then return end
    for i, slot in ipairs(ns.Bindings:GetOrderedSlots()) do
        local btn = self.slotButtons[i]
        btn.slot = slot
        local rec = ns.Bindings:Get(slot)
        local marker = (slot == self.selectedSlot) and "|cff88ffaa> |r" or ""
        local value = rec.value and rec.value ~= "" and rec.value or "-"
        btn:SetText(marker .. slot .. "  |cffaaaaaa" .. value .. "|r")
    end
    panel.selected:SetText("Selected: " .. tostring(self.selectedSlot))
end

local function setFilter(mode)
    UIB.filterMode = mode
    UIB:RefreshSpellList()
end

function UIB:AssignSearch()
    local text = panel.searchBox:GetText() or ""
    if text == "" then return end
    local entry = ns.SpellBook:FindByName(text)
    if not entry then
        local lc = string.lower(text)
        for _, sp in ipairs(ns.SpellBook:GetBindable()) do
            if string.find(string.lower(sp.name), lc, 1, true) then
                entry = sp
                break
            end
        end
    end
    if entry then
        ns.Bindings:SetSpell(self.selectedSlot, entry.name)
    else
        ns:Print("Spell not found in bindable list: " .. text)
    end
end

function UIB:OnInitialize()
    panel = CreateFrame("Frame", "PainboyBindingsPanel")
    panel.name = "Keybinds"
    panel.parent = "Painboy"
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Painboy - Keybinds")

    local leftBox = CreateFrame("Frame", nil, panel)
    leftBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    leftBox:SetWidth(200)
    leftBox:SetHeight(420)
    applyBackdrop(leftBox)

    local rightBox = CreateFrame("Frame", nil, panel)
    rightBox:SetPoint("TOPLEFT", leftBox, "TOPRIGHT", 12, 0)
    rightBox:SetWidth(360)
    rightBox:SetHeight(420)
    applyBackdrop(rightBox)

    local lTitle = leftBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lTitle:SetPoint("TOPLEFT", 10, -10)
    lTitle:SetText("Binding Slots")

    local rTitle = rightBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    rTitle:SetPoint("TOPLEFT", 10, -10)
    rTitle:SetText("Spell Picker")

    panel.selected = leftBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.selected:SetPoint("BOTTOMLEFT", leftBox, "BOTTOMLEFT", 10, 10)
    panel.selected:SetWidth(180)
    panel.selected:SetJustifyH("LEFT")
    panel.selected:SetText("Selected: LeftButton")

    for i, slot in ipairs(ns.Bindings:GetOrderedSlots()) do
        self.slotButtons[i] = createSlotButton(leftBox, i)
        self.slotButtons[i].slot = slot
    end

    panel.searchBox = CreateFrame("EditBox", nil, rightBox, "InputBoxTemplate")
    panel.searchBox:SetAutoFocus(false)
    panel.searchBox:SetWidth(180)
    panel.searchBox:SetHeight(20)
    panel.searchBox:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 10, -34)
    panel.searchBox:SetScript("OnTextChanged", function(self)
        UIB.searchText = self:GetText() or ""
        UIB:RefreshSpellList()
    end)
    panel.searchBox:SetScript("OnEnterPressed", function() UIB:AssignSearch() end)

    local assign = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    assign:SetWidth(70)
    assign:SetHeight(20)
    assign:SetPoint("LEFT", panel.searchBox, "RIGHT", 8, 0)
    assign:SetText(ns.L.ASSIGN or "Assign")
    assign:SetScript("OnClick", function() UIB:AssignSearch() end)

    local clear = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    clear:SetWidth(56)
    clear:SetHeight(20)
    clear:SetPoint("LEFT", assign, "RIGHT", 6, 0)
    clear:SetText(ns.L.CLEAR or "Clear")
    clear:SetScript("OnClick", function() ns.Bindings:Clear(UIB.selectedSlot) end)

    local searchLabel = rightBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    searchLabel:SetPoint("BOTTOMLEFT", panel.searchBox, "TOPLEFT", 2, 4)
    searchLabel:SetText("Type spell name, then Assign")

    local recommended = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    recommended:SetWidth(86)
    recommended:SetHeight(20)
    recommended:SetPoint("TOPLEFT", panel.searchBox, "BOTTOMLEFT", 0, -10)
    recommended:SetText("Recommended")
    recommended:SetScript("OnClick", function() setFilter("recommended") end)

    local allBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    allBtn:SetWidth(46); allBtn:SetHeight(20)
    allBtn:SetPoint("LEFT", recommended, "RIGHT", 6, 0)
    allBtn:SetText("All")
    allBtn:SetScript("OnClick", function() setFilter("all") end)

    local healBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    healBtn:SetWidth(56); healBtn:SetHeight(20)
    healBtn:SetPoint("LEFT", allBtn, "RIGHT", 6, 0)
    healBtn:SetText("Healing")
    healBtn:SetScript("OnClick", function() setFilter("healing") end)

    local suppBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    suppBtn:SetWidth(56); suppBtn:SetHeight(20)
    suppBtn:SetPoint("LEFT", healBtn, "RIGHT", 6, 0)
    suppBtn:SetText("Support")
    suppBtn:SetScript("OnClick", function() setFilter("support") end)

    local resBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    resBtn:SetWidth(40); resBtn:SetHeight(20)
    resBtn:SetPoint("LEFT", suppBtn, "RIGHT", 6, 0)
    resBtn:SetText("Res")
    resBtn:SetScript("OnClick", function() setFilter("res") end)

    local listFrame = CreateFrame("Frame", nil, rightBox)
    listFrame:SetPoint("TOPLEFT", recommended, "BOTTOMLEFT", 0, -10)
    listFrame:SetWidth(330)
    listFrame:SetHeight(290)
    applyBackdrop(listFrame)

    panel.summary = rightBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.summary:SetPoint("BOTTOMLEFT", rightBox, "BOTTOMLEFT", 10, 10)
    panel.summary:SetWidth(330)
    panel.summary:SetJustifyH("LEFT")

    panel.scroll = CreateFrame("ScrollFrame", "PainboySpellScroll", listFrame, "FauxScrollFrameTemplate")
    panel.scroll:SetPoint("TOPLEFT", 4, -4)
    panel.scroll:SetPoint("BOTTOMRIGHT", -26, 4)
    panel.scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 19, function() UIB:RefreshSpellList() end)
    end)

    local content = CreateFrame("Frame", nil, listFrame)
    content:SetWidth(302)
    content:SetHeight(290)
    content:SetPoint("TOPLEFT", 4, -4)

    for i = 1, 14 do
        self.rows[i] = createRow(content, i)
    end

end

function UIB:OnEnable()
    self:RefreshSlots()
    self:RefreshSpellList()
end
