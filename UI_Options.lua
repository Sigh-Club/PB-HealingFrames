local _, ns = ...
local Opt = ns:RegisterModule("UI_Options", {})

local registered = false

local function panelDefault(panel)
    if panel and panel.defaultHandler then panel.defaultHandler() end
end

local function panelRefresh(panel)
    if panel and panel.refreshHandler then panel.refreshHandler() end
end

local function ensurePanelMeta(panel)
    if not panel then return end
    panel.okay = panel.okay or function() end
    panel.cancel = panel.cancel or function() end
    panel.default = panel.default or function(self) panelDefault(self) end
    panel.refresh = panel.refresh or function(self) panelRefresh(self) end
end

function Opt:RegisterAll()
    if registered then return true end
    if not (ns.UI_Config and ns.UI_Config.panel and ns.UI_Bindings and ns.UI_Bindings.panel and ns.UI_Bars and ns.UI_Bars.panel) then
        return false
    end

    local parent = ns.UI_Config.panel
    local keybinds = ns.UI_Bindings.panel
    local bars = ns.UI_Bars.panel

    parent.name = "Painboy"
    parent.parent = nil
    parent.defaultHandler = function()
        if ns.Profiles then ns.Profiles:ResetCurrentProfile() end
        if ns.UI_Config then ns.UI_Config:Refresh() end
        if ns.UI_Bars then ns.UI_Bars:Refresh() end
        if ns.UI_Bindings then ns.UI_Bindings:RefreshSlots(); ns.UI_Bindings:RefreshSpellList() end
        if ns.Frames then ns.Frames:ApplyLayout() end
        if ns.Roster then ns.Roster:Refresh() end
        if ns.SpellBook then ns.SpellBook:Scan() end
    end
    parent.refreshHandler = function()
        if ns.UI_Config then ns.UI_Config:Refresh() end
    end

    keybinds.name = "Keybinds"
    keybinds.parent = "Painboy"
    keybinds.defaultHandler = function()
        if ns.Bindings then ns.Bindings:ResetProfileBindings() end
        if ns.UI_Bindings then ns.UI_Bindings:RefreshSlots(); ns.UI_Bindings:RefreshSpellList() end
    end
    keybinds.refreshHandler = function()
        if ns.UI_Bindings then ns.UI_Bindings:RefreshSlots(); ns.UI_Bindings:RefreshSpellList() end
    end

    bars.name = "Bars"
    bars.parent = "Painboy"
    bars.defaultHandler = function()
        if ns.Profiles then ns.Profiles:ResetCurrentProfile() end
        if ns.UI_Bars then ns.UI_Bars:Refresh() end
        if ns.Frames then ns.Frames:ApplyLayout() end
        if ns.Roster then ns.Roster:Refresh() end
    end
    bars.refreshHandler = function()
        if ns.UI_Bars then ns.UI_Bars:Refresh() end
    end

    ensurePanelMeta(parent)
    ensurePanelMeta(keybinds)
    ensurePanelMeta(bars)

    InterfaceOptions_AddCategory(parent)
    InterfaceOptions_AddCategory(keybinds)
    InterfaceOptions_AddCategory(bars)
    registered = true
    return true
end

function Opt:OnInitialize()
    self:RegisterAll()
end

function Opt:OnEnable()
    self:RegisterAll()
end
