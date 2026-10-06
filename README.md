# Better Character Panel (client-mods fork)

An addon for Turtle WoW (vanilla 1.12) that improves the default character and inspect panels: enchant descriptions next to gear icons, a missing-enchant marker, an improved layout that works with the default UI and pfUI, and optional Better Character Stats integration. Configure it with `/bcp` or the minimap button.

This is a fork of [Arthur-Helias/BetterCharacterPanel](https://github.com/Arthur-Helias/BetterCharacterPanel) (base version **1.3.6**). It keeps everything the original does and adds optional features that use extra client mods.

## Required and optional client mods

| Client mod | Needed? | Used for |
|---|---|---|
| **Nampower** | **Required** (same as the original) | Reading equipped items and their enchant IDs (`GetEquippedItem`, `GetItemLevel`, `GetItemStatsField`) |
| **ClassicAPI** | Optional | Enchant names from the client, weapon enchant timers, durability, repair cost |
| **SuperWoW** | Optional | `/bcp export` (`ExportFile`) |
| Better Character Stats | Optional, recommended (same as the original) | Extra stats inside the panel layout |
| UnitXP SP3, VanillaHelpers, WeirdUtils | Not used | Nothing in them applies to a character panel |

Every optional feature checks for the function it needs when it runs. If the mod is missing, that feature does nothing and the rest of the addon works as before. With Nampower alone, this fork behaves like the original plus the new scope enchant.

## What changed from the original (1.3.6)

| | Original | This fork |
|---|---|---|
| Enchant not in BCP's database | Shows a generic "Enchanted" / "Temp Ench" | Shows the enchant's real name from the client's own data (ClassicAPI), shortened to 24 characters. Falls back to the generic text if ClassicAPI is missing |
| Weapon oils, stones, poisons | Name only | Adds remaining time and charges, for example `(12m, 3x)`. Turns red under 2 minutes. Refreshes every second while the panel is open. Character panel only (ClassicAPI) |
| Durability | Not shown | Percentage on damaged slots, coloured green to red. Character panel only (ClassicAPI) |
| Gear score | Not shown | Total gear score in the model-hover tooltip, plus a per-item score line on every equipped item's own tooltip (character and inspect panels). Ported from S_ItemTip's `ItemSocre.lua` formula (a Turtle-tuned Shagu GearScore variant), so the numbers match what that addon already reports. Uses Nampower for item level and quality; no extra client mod required |
| Gear summary | None | Hover the character model: average item level, gear score, plus average durability, lowest slot and estimated repair cost on your own panel. On the inspect panel it shows average item level and gear score only |
| BetterCharacterStats cards cut off at the bottom | The scrollable BCS-card area's height was calculated as `yOffset - 45`, an unexplained fixed subtraction not present in the equivalent native stat display code. The scrollbar's max range is computed from that height, so with few categories enabled the shortfall could hide 2-3 of a category's 6 rows with no way to scroll to them | Removed the `-45`; the scroll area now reports its true height and every row is reachable |
| Gear export | None | `/bcp export` and `/bcp export target` write a text file (SuperWoW) |
| `/bcp` | Opens the config | Opens the config. `export` arguments are handled first |
| Config window | Existing sections | New **Client Mod Extras** section with four checkboxes: durability, timers, gear tooltip, item score in tooltips |
| Facetted Crystal Scope | Not in the database | Added as enchant ID **450**, "+2% Crit.", for Bow, Gun and Crossbow, in all seven languages |

### Notes on the new features

- **Repair cost** is the base, undiscounted cost. ClassicAPI only applies the reputation discount while a vendor window is open.
- **Durability of other players** is not sent to your client, so it appears on your own character panel only.
- **Export files** are written to SuperWoW's `imports` folder inside the game directory, named `BCP_<name>_<date>.txt`.
- **New strings** (the config labels and tooltip text) are English only for now. Other languages fall back to English.

### Facetted Crystal Scope

Enchant ID 450 was read from the game with `GetEquippedItem("player",18).permanentEnchantId`. The in-game description of the scope's spell (36945) says it attaches a permanent scope to a bow or gun that increases crit chance by 2%. The description names bows and guns only; crossbow is included here because the enchant is on a crossbow in practice, and it only affects the missing-enchant check.

The +2% appears as text on the ranged slot. It is **not** added into any crit number, because the addon does not calculate crit. Better Character Stats calculates crit itself by reading item tooltips, and this scope adds no tooltip line, so Better Character Stats does not count it.

### Gear score

The formula (`BetterCharacterPanel-gearscore.lua`) is ported as-is from S_ItemTip's `ItemSocre.lua`, itself a Turtle-tuned version of the classic Shagu GearScore addon — the same per-slot weights, the same class/weapon-type coefficients for main hand, off hand and ranged, and the same `(total / 17) * 1.355` normalization. Nothing about the scoring math was invented for this fork; only where the numbers come from changed:

- **Item level and quality** come from Nampower's `GetItemStatsField`, which reads the item-stats data directly and isn't affected by the "item not cached yet" gap that stock `GetItemInfo` has. This makes item level and quality reliable even for an inspect target's gear you've never seen before.
- **Two-handed weapon detection** (for the main-hand coefficient) still uses stock `GetItemInfo`, exactly as the original formula does. On an inspect target's weapon you've never seen, this can briefly assume one-handed until something else warms the client's item cache — a minor, self-correcting inaccuracy, not a missing feature. It self-corrects on your next panel refresh.
- **Total score** shows in the model-hover gear tooltip, next to average item level.
- **Per-item score** is added as an extra line on every equipped item's own tooltip (both panels), by pre-hooking `GameTooltip.SetInventoryItem` — the same technique `ItemSocre.lua` itself uses, kept as its own toggle since it's a busier addition than a single hover-tooltip line.

## Installation

1. Install **Nampower** first. Install ClassicAPI and SuperWoW as well if you want the optional features.
2. Download this repository as a zip.
3. Extract it and rename the folder to `BetterCharacterPanel` (remove any `-main` suffix).
4. Put it in `Interface\AddOns\`. If you already have the original installed, replace it or move it out of the way, because two folders with the same addon name clash.
5. Enable the addon on the character selection screen.

## Commands

| Command | What it does |
|---|---|
| `/bcp` or `/bettercharacterpanel` | Opens the config window |
| `/bcp export` | Exports your equipped gear to a text file (needs SuperWoW) |
| `/bcp export target` | Exports the targeted player's gear (needs SuperWoW) |

## Files added or changed

- **New:** `BetterCharacterPanel-clientmods.lua` (all optional client-mod features)
- **Changed:** `BetterCharacterPanel.toc` (loads the new file), `BetterCharacterPanel.lua` (slash command), `BetterCharacterPanel-config.lua` (new defaults and config section), `BetterCharacterPanel-paperdoll.lua` (enchant name fallback, timers, durability, tooltip hooks), `BetterCharacterPanel-dbenchants.lua` (enchant 450)
- **Changed:** all seven locale files (enchant 450 name and effect)

## Status

The new code was written against the ClassicAPI, SuperWoW and Nampower documentation, checked for Lua syntax, and tested against a mock of the game API. It has not been confirmed in a live client yet, so check the weapon enchant label (widened to fit the timer) on both the default UI and pfUI. Report problems as issues.

## Credits

Original addon by Arthur-Helias (`X-URL` in the `.toc` still points to the upstream repository). Check the upstream repository for its license before redistributing.
