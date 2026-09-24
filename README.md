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
| Gear summary | None | Hover the character model: average item level, plus average durability, lowest slot and estimated repair cost on your own panel. On the inspect panel it shows average item level only |
| Gear export | None | `/bcp export` and `/bcp export target` write a text file (SuperWoW) |
| `/bcp` | Opens the config | Opens the config. `export` arguments are handled first |
| Config window | Existing sections | New **Client Mod Extras** section with three checkboxes: durability, timers, gear tooltip |
| Facetted Crystal Scope | Not in the database | Added as enchant ID **450**, "+2% Crit.", for Bow, Gun and Crossbow, in all seven languages |

### Notes on the new features

- **Repair cost** is the base, undiscounted cost. ClassicAPI only applies the reputation discount while a vendor window is open.
- **Durability of other players** is not sent to your client, so it appears on your own character panel only.
- **Export files** are written to SuperWoW's `imports` folder inside the game directory, named `BCP_<name>_<date>.txt`.
- **New strings** (the config labels and tooltip text) are English only for now. Other languages fall back to English.

### Facetted Crystal Scope

Enchant ID 450 was read from the game with `GetEquippedItem("player",18).permanentEnchantId`. The in-game description of the scope's spell (36945) says it attaches a permanent scope to a bow or gun that increases crit chance by 2%. The description names bows and guns only; crossbow is included here because the enchant is on a crossbow in practice, and it only affects the missing-enchant check.

The +2% appears as text on the ranged slot. It is **not** added into any crit number, because the addon does not calculate crit. Better Character Stats calculates crit itself by reading item tooltips, and this scope adds no tooltip line, so Better Character Stats does not count it.

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
