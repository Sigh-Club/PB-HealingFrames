## 0.2.1-testing
- Added aura corner indicators module with per-unit caching and button-level refresh
- Added incoming-heal overlay module (HealComm integration) with profile toggle support
- Improved spell scanning: racial and utility filtering, richer role diagnostics, and stronger role fallback
- Added buffs/form role handling (including Tree of Life) and Buffs filter category in the spell picker
- Refined SmartBind with deterministic ordering, duplicate prevention, fallback priorities, and detailed debug output
- Reworked Keybinds UI for compact layout, filter cycling, slot tooltips, shift-click spell linking, and right-click action menu
- Added Controls subpanel with Quick Setup action and `/pb setup` command
- Added startup diagnostics and defensive fallback bootstrap for missing intelligence data
- Added project luacheck configuration (`.luacheckrc`) and validated updated binding modules
- Added configurable health-color thresholds (critical/injured %) for raid bars
- Improved curable-debuff visual feedback with debuff school tags (MAG/CUR/DIS/POI) and safer stale-icon clearing
- Added debuff-priority border hierarchy with separate aggro + curable-debuff glows for clearer triage under pressure
- Added configurable debuff-triage UI (priority order + per-school colors) in Bars settings
- Added readability controls: always full-alpha text and text-backdrop strip options for raid frames
- Added dedicated Sizing Presets panel for per-tier 5/10/25/40 tuning (width, height, spacing, scale, mana strip)

## 0.2.0-testing
- Exclude General tab from bindable spells by default
- Cleaner two-pane bindings UI
- Embedded Ascension healing intelligence seed package
- Explicit spell assignment workflow
