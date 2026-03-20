local _, ns = ...
local Config = ns:RegisterModule("UI_Config", {})
ns.UI_Config = Config

local panel

local optionsRegistered = false

local function RegisterOptionsPanels()
    if optionsRegistered then return end
    if not panel or not ns.UI_Bindings or not ns.UI_Bindings.panel or not ns.UI_Bars or not ns.UI_Bars.panel then return end
    InterfaceOptions_AddCategory(panel)
    InterfaceOptions_AddCategory(ns.UI_Bindings.panel)
    InterfaceOptions_AddCategory(ns.UI_Bars.panel)
    optionsRegistered = true
end

local function mkCheck(parent, label, tooltip, get, set)
    local b = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    b.Text:SetText(label)
    b.tooltipText = tooltip
    b:SetChecked(get())
    b:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    return b
end

local function applyBars()
    if ns.Frames then
        ns.Frames:ApplyLayout()
        ns.Roster:Refresh()
    end
end

function Config:Refresh()
    if not panel then return end
    panel.lockCheck:SetChecked(ns.DB.locked)
    panel.generalCheck:SetChecked(ns.DB.scan.excludeGeneral)
    panel.passiveCheck:SetChecked(ns.DB.scan.excludePassive)
    panel.profCheck:SetChecked(ns.DB.scan.excludeProfessions)
    panel.profileText:SetText("Profile: " .. (ns.Profiles:GetProfileName() or "Unknown"))
    panel.charText:SetText("Character key: " .. (ns.Profiles:GetCharKey() or "Unknown"))
end

function Config:OnInitialize()
    panel = CreateFrame("Frame", "PainboyOptionsPanel")
    panel.name = "Painboy"
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Painboy")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetWidth(620)
    sub:SetJustifyH("LEFT")
    sub:SetText("Simple healer frames for Ascension. Keep the main page focused: lock/unlock, spell scan filters, current character profile, and shortcuts to Keybinds and Bars.")

    panel.profileText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    panel.profileText:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)

    panel.charText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.charText:SetPoint("TOPLEFT", panel.profileText, "BOTTOMLEFT", 0, -6)

    panel.lockCheck = mkCheck(panel, "Lock frames", "Prevent dragging anchors.", function() return ns.DB.locked end, function(v) ns.DB.locked = v; applyBars() end)
    panel.lockCheck:SetPoint("TOPLEFT", panel.charText, "BOTTOMLEFT", 0, -14)

    panel.generalCheck = mkCheck(panel, "Exclude General tab from bindable spell list", "Recommended so Campfire/Warmode-style entries do not clutter the picker.", function() return ns.DB.scan.excludeGeneral end, function(v) ns.DB.scan.excludeGeneral = v; ns.SpellBook:Scan() end)
    panel.generalCheck:SetPoint("TOPLEFT", panel.lockCheck, "BOTTOMLEFT", 0, -10)

    panel.passiveCheck = mkCheck(panel, "Exclude passive spells", "Hide passive entries from the picker.", function() return ns.DB.scan.excludePassive end, function(v) ns.DB.scan.excludePassive = v; ns.SpellBook:Scan() end)
    panel.passiveCheck:SetPoint("TOPLEFT", panel.generalCheck, "BOTTOMLEFT", 0, -8)

    panel.profCheck = mkCheck(panel, "Exclude professions/tradeskills", "Hide profession tabs from the picker.", function() return ns.DB.scan.excludeProfessions end, function(v) ns.DB.scan.excludeProfessions = v; ns.SpellBook:Scan() end)
    panel.profCheck:SetPoint("TOPLEFT", panel.passiveCheck, "BOTTOMLEFT", 0, -8)

    local btnBind = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnBind:SetWidth(120); btnBind:SetHeight(22)
    btnBind:SetPoint("TOPLEFT", panel.profCheck, "BOTTOMLEFT", 0, -18)
    btnBind:SetText("Open Keybinds")
    btnBind:SetScript("OnClick", function() InterfaceOptionsFrame_OpenToCategory(ns.UI_Bindings.panel); InterfaceOptionsFrame_OpenToCategory(ns.UI_Bindings.panel) end)

    local btnBars = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnBars:SetWidth(120); btnBars:SetHeight(22)
    btnBars:SetPoint("LEFT", btnBind, "RIGHT", 8, 0)
    btnBars:SetText("Open Bars")
    btnBars:SetScript("OnClick", function() InterfaceOptionsFrame_OpenToCategory(ns.UI_Bars.panel); InterfaceOptionsFrame_OpenToCategory(ns.UI_Bars.panel) end)

    local btnReset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnReset:SetWidth(150); btnReset:SetHeight(22)
    btnReset:SetPoint("LEFT", btnBars, "RIGHT", 8, 0)
    btnReset:SetText("Reset this profile")
    btnReset:SetScript("OnClick", function() ns.Profiles:ResetCurrentProfile(); Config:Refresh(); applyBars(); ns.SpellBook:Scan(); if ns.UI_Bars then ns.UI_Bars:Refresh() end end)

    local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", btnBind, "BOTTOMLEFT", 0, -16)
    help:SetWidth(620)
    help:SetJustifyH("LEFT")
    help:SetText("Use /pb test 5, /pb test 10, /pb test 25, or /pb test 40 to preview fake animated bars while you position frames.")

end

function Config:OnEnable()
    self:Refresh()
end
