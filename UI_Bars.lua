local _, ns = ...
local UIBars = ns:RegisterModule("UI_Bars", {})
ns.UI_Bars = UIBars

local panel
local sliders = {}
local sliderSeq = 0

local function mkCheck(parent, label, tooltip, get, set)
    local b = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    b.Text:SetText(label)
    b.tooltipText = tooltip
    b:SetChecked(get())
    b:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    return b
end

local function mkSlider(parent, label, minv, maxv, step, getter, setter)
    sliderSeq = sliderSeq + 1
    local name = "PainboyBarSlider" .. sliderSeq
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetWidth(220)
    s:SetMinMaxValues(minv, maxv)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s.getter = getter
    s.label = label
    _G[name .. "Low"]:SetText(tostring(minv))
    _G[name .. "High"]:SetText(tostring(maxv))
    s:SetScript("OnValueChanged", function(self, value)
        value = math.floor((value / step) + 0.5) * step
        if step < 1 then value = math.floor(value * 100 + 0.5) / 100 end
        setter(value)
        _G[self:GetName() .. "Text"]:SetText(label .. ": " .. tostring(value))
        if ns.Frames then ns.Frames:ApplyLayout() end
        if ns.Roster then ns.Roster:Refresh() end
    end)
    table.insert(sliders, s)
    return s
end

local function openColorPicker(current, callback)
    local r, g, b = current[1], current[2], current[3]
    ColorPickerFrame.func = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        callback({nr, ng, nb})
    end
    ColorPickerFrame.cancelFunc = function(prev)
        callback({prev.r, prev.g, prev.b})
    end
    ColorPickerFrame.opacityFunc = nil
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = { r = r, g = g, b = b }
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

local function mkColorButton(parent, label, getter, setter)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetWidth(120); btn:SetHeight(20)
    btn:SetText(label)
    btn.getter = getter
    btn.swatch = btn:CreateTexture(nil, "ARTWORK")
    btn.swatch:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    btn.swatch:SetWidth(18); btn.swatch:SetHeight(18)
    btn:SetScript("OnClick", function()
        openColorPicker(getter(), function(c) setter(c); UIBars:Refresh(); if ns.Frames then ns.Frames:ApplyLayout() end end)
    end)
    return btn
end

function UIBars:Refresh()
    if not panel then return end
    panel.healthCheck:SetChecked(ns.DB.frame.showHealthText)
    panel.gradientCheck:SetChecked(ns.DB.frame.useHealthGradient)
    panel.curableCheck:SetChecked(ns.DB.frame.highlightCurableDebuffs)
    panel.splitCheck:SetChecked(ns.DB.frame.layoutMode == "separate")
    panel.testCheck:SetChecked(ns.DB.frame.fakeMode)
    panel.manaCheck:SetChecked(ns.DB.frame.showManaBar)
    panel.statusCheck:SetChecked(ns.DB.frame.showStatusText)
    for _, s in ipairs(sliders) do
        local v = s.getter()
        s:SetValue(v)
        _G[s:GetName() .. "Text"]:SetText(s.label .. ": " .. tostring(v))
    end
    for _, b in ipairs(panel.colorButtons) do
        local c = b.getter()
        b.swatch:SetTexture(c[1], c[2], c[3], 1)
    end
end

function UIBars:OnInitialize()
    panel = CreateFrame("Frame", "PainboyBarsPanel")
    panel.name = "Bars"
    panel.parent = "Painboy"
    panel.colorButtons = {}
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Painboy - Bars")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetWidth(620)
    sub:SetJustifyH("LEFT")
    sub:SetText("Compact healer bars with simple customization. Move the whole cluster together or split raid groups into separate anchors.")

    panel.healthCheck = mkCheck(panel, "Show health percent text", "Show or hide right-side health text.", function() return ns.DB.frame.showHealthText end, function(v) ns.DB.frame.showHealthText = v; ns.Frames:ApplyLayout() end)
    panel.healthCheck:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)

    panel.manaCheck = mkCheck(panel, "Show mana bar strip", "Show a small mana bar strip on units with mana.", function() return ns.DB.frame.showManaBar end, function(v) ns.DB.frame.showManaBar = v; ns.Frames:ApplyLayout() end)
    panel.manaCheck:SetPoint("TOPLEFT", panel.healthCheck, "BOTTOMLEFT", 0, -8)

    panel.statusCheck = mkCheck(panel, "Show status text", "Show DEAD / OFFLINE / AFK text.", function() return ns.DB.frame.showStatusText end, function(v) ns.DB.frame.showStatusText = v; ns.Frames:ApplyLayout() end)
    panel.statusCheck:SetPoint("TOPLEFT", panel.manaCheck, "BOTTOMLEFT", 0, -8)

    panel.gradientCheck = mkCheck(panel, "Color bars by missing health", "Use healthy/injured/critical colors.", function() return ns.DB.frame.useHealthGradient end, function(v) ns.DB.frame.useHealthGradient = v; ns.Frames:ApplyLayout() end)
    panel.gradientCheck:SetPoint("TOPLEFT", panel.statusCheck, "BOTTOMLEFT", 0, -8)

    panel.curableCheck = mkCheck(panel, "Highlight curable debuffs on bars", "Override bar color for curable debuffs you can actually dispel.", function() return ns.DB.frame.highlightCurableDebuffs end, function(v) ns.DB.frame.highlightCurableDebuffs = v; ns.Frames:ApplyLayout() end)
    panel.curableCheck:SetPoint("TOPLEFT", panel.gradientCheck, "BOTTOMLEFT", 0, -8)

    panel.splitCheck = mkCheck(panel, "Separate raid groups", "Each raid subgroup gets its own draggable anchor.", function() return ns.DB.frame.layoutMode == "separate" end, function(v) ns.DB.frame.layoutMode = v and "separate" or "combined"; ns.Frames:ApplyLayout(); ns.Roster:Refresh() end)
    panel.splitCheck:SetPoint("TOPLEFT", panel.curableCheck, "BOTTOMLEFT", 0, -8)

    panel.testCheck = mkCheck(panel, "Enable fake test bars", "Preview animated fake bars for layout testing.", function() return ns.DB.frame.fakeMode end, function(v) ns.Roster:SetFakeMode(v, ns.DB.frame.fakeSize or 10) end)
    panel.testCheck:SetPoint("TOPLEFT", panel.splitCheck, "BOTTOMLEFT", 0, -8)

    local left = 320
    local s1 = mkSlider(panel, "Bar width", 100, 240, 2, function() return ns.DB.frame.width end, function(v) ns.DB.frame.width = v end)
    s1:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", left, -12)
    local s2 = mkSlider(panel, "Bar height", 14, 32, 1, function() return ns.DB.frame.height end, function(v) ns.DB.frame.height = v end)
    s2:SetPoint("TOPLEFT", s1, "BOTTOMLEFT", 0, -24)
    local s3 = mkSlider(panel, "Bar spacing", 0, 8, 1, function() return ns.DB.frame.spacing end, function(v) ns.DB.frame.spacing = v end)
    s3:SetPoint("TOPLEFT", s2, "BOTTOMLEFT", 0, -24)
    local s4 = mkSlider(panel, "Frame scale", 0.7, 1.4, 0.05, function() return ns.DB.frame.scale end, function(v) ns.DB.frame.scale = v end)
    s4:SetPoint("TOPLEFT", s3, "BOTTOMLEFT", 0, -24)
    local s5 = mkSlider(panel, "Out-of-range bar alpha", 0.15, 0.9, 0.05, function() return ns.DB.frame.outOfRangeAlpha end, function(v) ns.DB.frame.outOfRangeAlpha = v end)
    s5:SetPoint("TOPLEFT", s4, "BOTTOMLEFT", 0, -24)
    local s6 = mkSlider(panel, "Out-of-range text alpha", 0.15, 1.0, 0.05, function() return ns.DB.frame.outOfRangeTextAlpha end, function(v) ns.DB.frame.outOfRangeTextAlpha = v end)
    s6:SetPoint("TOPLEFT", s5, "BOTTOMLEFT", 0, -24)
    local s7 = mkSlider(panel, "Groups per row", 1, 4, 1, function() return ns.DB.frame.groupsPerRow end, function(v) ns.DB.frame.groupsPerRow = v end)
    s7:SetPoint("TOPLEFT", s6, "BOTTOMLEFT", 0, -24)
    local s8 = mkSlider(panel, "Group spacing", 4, 30, 1, function() return ns.DB.frame.groupSpacing end, function(v) ns.DB.frame.groupSpacing = v end)
    s8:SetPoint("TOPLEFT", s7, "BOTTOMLEFT", 0, -24)
    local s9 = mkSlider(panel, "Mana bar height", 0, 6, 1, function() return ns.DB.frame.manaBarHeight end, function(v) ns.DB.frame.manaBarHeight = v end)
    s9:SetPoint("TOPLEFT", s8, "BOTTOMLEFT", 0, -24)

    local c1 = mkColorButton(panel, "Healthy color", function() return ns.DB.frame.healthyColor end, function(v) ns.DB.frame.healthyColor = v end)
    c1:SetPoint("TOPLEFT", panel.testCheck, "BOTTOMLEFT", 0, -18)
    local c2 = mkColorButton(panel, "Injured color", function() return ns.DB.frame.injuredColor end, function(v) ns.DB.frame.injuredColor = v end)
    c2:SetPoint("TOPLEFT", c1, "BOTTOMLEFT", 0, -10)
    local c3 = mkColorButton(panel, "Critical color", function() return ns.DB.frame.criticalColor end, function(v) ns.DB.frame.criticalColor = v end)
    c3:SetPoint("TOPLEFT", c2, "BOTTOMLEFT", 0, -10)
    panel.colorButtons = { c1, c2, c3 }

    local test5 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    test5:SetWidth(60); test5:SetHeight(20); test5:SetPoint("TOPLEFT", c3, "BOTTOMLEFT", 0, -18); test5:SetText("Test 5")
    test5:SetScript("OnClick", function() ns.Roster:SetFakeMode(true, 5) end)
    local test10 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    test10:SetWidth(60); test10:SetHeight(20); test10:SetPoint("LEFT", test5, "RIGHT", 8, 0); test10:SetText("Test 10")
    test10:SetScript("OnClick", function() ns.Roster:SetFakeMode(true, 10) end)
    local test25 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    test25:SetWidth(60); test25:SetHeight(20); test25:SetPoint("LEFT", test10, "RIGHT", 8, 0); test25:SetText("Test 25")
    test25:SetScript("OnClick", function() ns.Roster:SetFakeMode(true, 25) end)
    local test40 = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    test40:SetWidth(60); test40:SetHeight(20); test40:SetPoint("LEFT", test25, "RIGHT", 8, 0); test40:SetText("Test 40")
    test40:SetScript("OnClick", function() ns.Roster:SetFakeMode(true, 40) end)
    local live = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    live:SetWidth(70); live:SetHeight(20); live:SetPoint("LEFT", test40, "RIGHT", 8, 0); live:SetText("Test Off")
    live:SetScript("OnClick", function() ns.Roster:SetFakeMode(false) end)

end

function UIBars:OnEnable()
    self:Refresh()
end
