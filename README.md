# Better Character Panel (Client-Mods Fork)

Enhances the default Turtle WoW (1.12) character and inspect panels with permanent/temporary enchant labels, missing-enchant indicators, Gear Score, durability, cross-faction inspect summaries, gear export, and integrated **BetterCharacterStats** & **VanillaRatingBuster** support across both Vanilla and pfUI skins.

Fork of [Arthur-Helias/BetterCharacterPanel](https://github.com/Arthur-Helias/BetterCharacterPanel) (base version **1.3.6**).

## Required and Optional Client Mods

| Client Mod | Needed? | Used For |
|---|---|---|
| **Nampower** | **Required** | Reading equipped items, enchant IDs, item levels, and item stats (`GetEquippedItems`, `GetEquippedItem`, `GetItemLevel`, `GetItemStatsField`, `GetUnitGUID`) |
| **ClassicAPI** | Optional | Live enchant names, weapon enchant timers/charges, durability & repair cost, `C_Item.RequestLoadItemDataByID` / `ITEM_DATA_LOAD_RESULT` cache warmup, `GetAddOnMemoryUsage` in `/bcp perf` |
| **SuperWoW** | Optional | `/bcp export` & `/bcp export target` (`ExportFile`), GUID resolution for cross-faction inspect snapshots |

Companion addons (optional, auto-detected):
- **BetterCharacterStats:** Embedded stat cards inside the character panel (with category hide/collapse, class presets, and 1-tick sync via `BCS:RegisterCallback("GEAR_UPDATED")`).
- **VanillaRatingBuster:** Displays total VRB spec scores in the Character/Inspect model hover tooltip, `/bcp inspect`, and `/bcp lastinspect`.

## Features

- **Character & Inspect Enchant Overlays:** Permanent and temporary enchants beside each slot, missing-enchant markers, Facetted Crystal Scope (enchant `450`, `+2% Crit.` across all 7 locales), and ClassicAPI live enchant-name fallback.
- **Weapon Temp Enchant Timers & Slot Durability (ClassicAPI):** Live remaining time/charges `(12m, 3x)` on weapon slots with idle `OnUpdate` detach, color-coded durability percentages on damaged gear, and repair cost estimate on model hover.
- **Gear Score & Item Score Tooltips:** S_ItemTip/Shagu-compatible Gear Score in model tooltips and per-item `Item Score` lines across equipped slots, bags, bank, merchant, buyback, auction house, loot, quest, tradeskill, craft, mail, chat links (`ItemRefTooltip`), and comparison tooltips (`ShoppingTooltip1`/`2`).
- **Integrated BetterCharacterStats Panel:** Per-category visibility checkboxes, `"Auto-hide by Class"` / `"Show All"` presets, collapsible cards (`-`/`+`) with zero-rescan layout rebuild, aligned Vanilla and pfUI skins (normal and WideMode).
- **Cross-Faction Inspect & Snapshots:** Inspects other-faction players with GUID fallback, caches session inspect snapshots by GUID (`/bcp lastinspect`), and summarizes Avg iLvl, Gear Score, missing enchants, and VRB spec scores.
- **Gear Readiness & Diagnostics:** `/bcp ready` pre-pull checklist (missing enchants, low durability, missing weapon oils/stones), `/bcp export [target]` text export, `/bcp trace`, and `/bcp perf`.

## Commands

| Command | Description |
|---|---|
| `/bcp` or `/bettercharacterpanel` | Opens the configuration window |
| `/bcp export` | Exports your equipped gear, Avg iLvl, and Gear Score to a text file (SuperWoW) |
| `/bcp export target` | Exports the targeted player's gear (SuperWoW) |
| `/bcp inspect` | Prints cross-faction Avg iLvl, Gear Score, and VRB spec scores for your target |
| `/bcp lastinspect` | Recalls the most recent inspected player's cached snapshot |
| `/bcp ready` | Prints a pre-pull Gear Readiness checklist (missing enchants, durability, weapon temp enchants) |
| `/bcp trace` | Toggles debug trace logging in chat |
| `/bcp perf` | Prints detected client mods, companion addons, and addon memory usage |

## What Was Added & Improved vs Upstream (1.3.6)

| Area | Upstream (1.3.6) | This Fork |
|---|---|---|
| Client-mod extras | Nampower enchant lookup only | Added ClassicAPI enchant names, weapon timers, durability/repair cost, `ITEM_DATA_LOAD_RESULT` 18-slot cache warmup, and SuperWoW gear export |
| Gear Score & Item Score | Not included | Full Gear Score + `Item Score` across all item tooltips including bags, bank, AH, merchant, loot, quest, mail, `ItemRefTooltip`, and `ShoppingTooltip1`/`2` (with correct off-hand slot coefficient) |
| BCS Integration & Layout | Fixed list, scroll cutoff (`maxH + 75` / `-45`), redundant rescans | Per-category hide, card collapse, class presets, aligned Vanilla/pfUI frames, and 1-tick sync via `BCS:RegisterCallback("GEAR_UPDATED")` |
| Cross-Faction Inspect & VRB Synergy | Basic inspect refresh | GUID-based inspect refresh + session snapshot cache (`/bcp lastinspect`), `PLAYER_TARGET_CHANGED` refresh, and VRB total spec scores on inspect/model hover |
| Stability & Bug Fixes | `BCPPFUIUnifiedBackdrop` nil crash on first open, stacking `HookScript` in `EnableClickRotate`, nil `this.rotation`, `_G` nil global, double-init, stock 1.12 `GetItemInfo` index bugs, `ExportFile` `.txt.txt` / missing `pcall`, negative Head temp font height (`y="-7"`), ignored `SpecialIconsMissingEnchantOffsets`, unprefixed global button names | All fixed; batched Nampower `GetEquippedItems` calls and idle `OnUpdate` detach for minimal CPU overhead |

## Credits

Original addon by Arthur-Helias. Gear Score formula ported from S_ItemTip (`ItemSocre.lua`, Turtle-tuned Shagu GearScore).
