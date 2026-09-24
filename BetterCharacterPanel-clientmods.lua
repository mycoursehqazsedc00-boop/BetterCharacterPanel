-- O――――――――――――――――――――――――――――――――――――――――――O
-- |   Optional client-mod integrations (all guarded)   |
-- O――――――――――――――――――――――――――――――――――――――――――O
--
-- Every feature in this file is optional. Each one checks for the function it
-- needs at call time and quietly does nothing when the mod that provides it is
-- not installed, so BCP keeps working with Nampower alone.
--
--   ClassicAPI  : C_Item.GetEnchantInfo, C_Item.GetWeaponEnchantInfo,
--                 GetInventoryItemDurability, GetInventoryItemRepairCost
--   SuperWoW    : ExportFile
--   Nampower    : (already required by BCP) GetEquippedItem, GetItemLevel,
--                 GetItemStatsField
--
-- Written in plain 1.12 Lua 5.0 style (no '#', no '%', no varargs syntax).

BCPClientMods = BCPClientMods or {}
local M = BCPClientMods

-- English defaults. The locale files don't know about these strings yet, so
-- every language falls back to English until they are translated.
BCP_CONFIG_SEC_CLIENTMODS = BCP_CONFIG_SEC_CLIENTMODS or "Client Mod Extras"
BCP_CONFIG_CM_DURABILITY = BCP_CONFIG_CM_DURABILITY or "Show Durability On Slots"
BCP_CONFIG_CM_DURABILITY_TT = BCP_CONFIG_CM_DURABILITY_TT or
    "Shows a small durability percentage on damaged equipment slots. Character panel only. Requires ClassicAPI."
BCP_CONFIG_CM_TIMERS = BCP_CONFIG_CM_TIMERS or "Show Temporary Enchant Timers"
BCP_CONFIG_CM_TIMERS_TT = BCP_CONFIG_CM_TIMERS_TT or
    "Adds the remaining time (and charges) to weapon oils, stones and poisons. Character panel only. Requires ClassicAPI."
BCP_CONFIG_CM_TOOLTIP = BCP_CONFIG_CM_TOOLTIP or "Show Gear Summary Tooltip"
BCP_CONFIG_CM_TOOLTIP_TT = BCP_CONFIG_CM_TOOLTIP_TT or
    "Hover the character model to see average item level, average durability and the estimated repair cost."
BCP_CM_GEAR_SUMMARY = BCP_CM_GEAR_SUMMARY or "Gear Summary"
BCP_CM_AVG_ILVL = BCP_CM_AVG_ILVL or "Average item level"
BCP_CM_AVG_DURABILITY = BCP_CM_AVG_DURABILITY or "Average durability"
BCP_CM_LOWEST_DURABILITY = BCP_CM_LOWEST_DURABILITY or "Lowest durability"
BCP_CM_REPAIR_COST = BCP_CM_REPAIR_COST or "Estimated repair cost"
BCP_CM_EXPORT_MISSING = BCP_CM_EXPORT_MISSING or "Gear export needs SuperWoW (ExportFile was not found)."
BCP_CM_EXPORT_NO_UNIT = BCP_CM_EXPORT_NO_UNIT or "Nothing to export: target a player and use /bcp export target."
BCP_CM_EXPORT_DONE = BCP_CM_EXPORT_DONE or "Gear exported to the SuperWoW imports folder as"

-- Equipment slots that can carry a weapon temporary enchant.
local WEAPON_TEMP_SLOTS = { [16] = true, [17] = true, [18] = true }

-- =================
-- =   Utilities   =
-- =================

function M:IsEnabled(key)
    return BCPConfig and BCPConfig.ClientMods and BCPConfig.ClientMods[key] and true or false
end

local function FormatDuration(ms)
    local s = math.floor(ms / 1000)

    if s >= 3600 then
        return math.floor(s / 3600) .. "h"
    elseif s >= 60 then
        return math.floor(s / 60) .. "m"
    end

    return s .. "s"
end

local function FormatMoney(copper)
    copper = copper or 0

    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    local rest = math.mod(copper, 100)

    return "|cffffd700" .. gold .. "g|r |cffc7c7cf" .. silver .. "s|r |cffeda55f" .. rest .. "c|r"
end

-- Green -> yellow -> orange -> red as durability drops.
local function DurabilityColor(pct)
    if pct <= 25 then
        return "|cffff3333"
    elseif pct <= 50 then
        return "|cffff8800"
    elseif pct <= 75 then
        return "|cffffff00"
    end

    return "|cff44ee44"
end

local function Shorten(text, maxLen)
    if string.len(text) > maxLen then
        return string.sub(text, 1, maxLen - 2) .. ".."
    end

    return text
end

-- ==========================================
-- =   ClassicAPI: enchant names from DBC   =
-- ==========================================

-- BCP's own database only knows the enchants it was taught. When an id is
-- missing, the panel used to show a generic "Enchanted". The client's own
-- SpellItemEnchantment table (exposed by ClassicAPI) can fill that gap.
local enchantNameCache = {}

function M:GetEnchantName(enchantId)
    if not enchantId or enchantId == 0 then
        return nil
    end

    local cached = enchantNameCache[enchantId]

    if cached ~= nil then
        return cached or nil
    end

    local name = false

    if C_Item and C_Item.GetEnchantInfo then
        local ok, info = pcall(C_Item.GetEnchantInfo, enchantId)

        if ok and info and info.name and info.name ~= "" then
            name = Shorten(info.name, 24)
        end
    end

    enchantNameCache[enchantId] = name

    return name or nil
end

-- ============================================
-- =   ClassicAPI: temporary enchant timers   =
-- ============================================

local weaponEnchantScratch = {}

local function ReadWeaponEnchants()
    if not (C_Item and C_Item.GetWeaponEnchantInfo) then
        return nil
    end

    local ok, hasMain, mainExp, mainCh, _, hasOff, offExp, offCh, _, hasRanged, rangedExp, rangedCh =
        pcall(C_Item.GetWeaponEnchantInfo)

    if not ok then
        return nil
    end

    weaponEnchantScratch[16] = { has = hasMain, exp = mainExp, charges = mainCh }
    weaponEnchantScratch[17] = { has = hasOff, exp = offExp, charges = offCh }
    weaponEnchantScratch[18] = { has = hasRanged, exp = rangedExp, charges = rangedCh }

    return weaponEnchantScratch
end

function M:IsWeaponSlot(slotId)
    return WEAPON_TEMP_SLOTS[slotId] and true or false
end

-- Returns the " (12m, 3)" style suffix for a weapon slot, or "" when the
-- feature is off, ClassicAPI is missing, or the slot has no timed enchant.
function M:GetTimerSuffix(slotId, data)
    if not self:IsEnabled("TempEnchantTimers") or not WEAPON_TEMP_SLOTS[slotId] then
        return ""
    end

    data = data or ReadWeaponEnchants()

    local entry = data and data[slotId]

    if not entry or not entry.has then
        return ""
    end

    local parts = ""

    if entry.exp and entry.exp > 0 then
        local color = "|cffaaaaaa"

        if entry.exp < 120000 then
            color = "|cffff5555"
        end

        parts = color .. FormatDuration(entry.exp) .. "|r"
    end

    if entry.charges and entry.charges > 0 then
        if parts ~= "" then
            parts = parts .. "|cffaaaaaa, |r"
        end

        parts = parts .. "|cffaaaaaa" .. entry.charges .. "x|r"
    end

    if parts == "" then
        return ""
    end

    return " |cffaaaaaa(|r" .. parts .. "|cffaaaaaa)|r"
end

-- Called by BCP_Refresh for the player's temp text. Remembers the un-suffixed
-- text so the one-second ticker below can refresh only the countdown.
function M:DecorateTempText(fontString, baseText, slotId)
    fontString.bcpBase = nil

    if baseText == "" or not WEAPON_TEMP_SLOTS[slotId] then
        return baseText
    end

    -- Widen the label a little so the timer isn't clipped.
    fontString:SetWidth(176)

    fontString.bcpBase = baseText
    fontString.bcpSlotId = slotId

    return baseText .. self:GetTimerSuffix(slotId)
end

local timerFrame = CreateFrame("Frame")
local timerElapsed = 0

timerFrame:SetScript("OnUpdate", function()
    timerElapsed = timerElapsed + arg1

    if timerElapsed < 1 then
        return
    end

    timerElapsed = 0

    if not PaperDollFrame or not PaperDollFrame:IsVisible() then
        return
    end

    if not M:IsEnabled("TempEnchantTimers") then
        return
    end

    local data = ReadWeaponEnchants()

    if not data then
        return
    end

    for slotId in pairs(WEAPON_TEMP_SLOTS) do
        for _, info in ipairs(BCP_SLOTS or {}) do
            if info.slotId == slotId then
                local fs = getglobal("BCP_" .. info.tag .. "_Temp")

                if fs and fs.bcpBase then
                    fs:SetText(fs.bcpBase .. M:GetTimerSuffix(slotId, data))
                end
            end
        end
    end
end)

-- =================================================
-- =   ClassicAPI: durability + repair cost       =
-- =================================================

function M:HasDurabilityAPI()
    return GetInventoryItemDurability and true or false
end

local function GetSlotLabel(info)
    local frameTag = info.frameTag or info.tag
    local label = getglobal(string.upper(frameTag) .. "SLOT")

    return label or info.tag
end

-- Returns avg %, lowest %, lowest slot label, total repair cost (copper),
-- or nil when the API is not available / nothing has durability.
function M:GetDurabilitySummary()
    if not self:HasDurabilityAPI() then
        return nil
    end

    local pctSum, count, lowest, lowestLabel, cost = 0, 0, nil, nil, 0

    for _, info in ipairs(BCP_SLOTS or {}) do
        local cur, max = GetInventoryItemDurability(info.slotId)

        if cur and max and max > 0 then
            local pct = (cur / max) * 100

            pctSum = pctSum + pct
            count = count + 1

            if not lowest or pct < lowest then
                lowest = pct
                lowestLabel = GetSlotLabel(info)
            end

            if GetInventoryItemRepairCost then
                cost = cost + (GetInventoryItemRepairCost(info.slotId) or 0)
            end
        end
    end

    if count == 0 then
        return nil
    end

    return pctSum / count, lowest, lowestLabel, cost
end

local function GetDurabilityFontString(slotFrame)
    if slotFrame.bcpDurability then
        return slotFrame.bcpDurability
    end

    local fs = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local fontPath = fs:GetFont()

    fs:SetFont(fontPath, 9, "OUTLINE")
    fs:SetPoint("BOTTOM", slotFrame, "BOTTOM", 0, 2)

    slotFrame.bcpDurability = fs

    return fs
end

-- Player only: durability of other players is not broadcast by the server.
function M:RefreshSlotDurability(unit, prefix)
    if prefix ~= "BCP_" then
        return
    end

    local enabled = unit == "player" and self:IsEnabled("DurabilityOnSlots") and self:HasDurabilityAPI()

    for _, info in ipairs(BCP_SLOTS or {}) do
        local slotFrame = getglobal("Character" .. (info.frameTag or info.tag) .. "Slot")

        if slotFrame then
            local text = ""

            if enabled then
                local cur, max = GetInventoryItemDurability(info.slotId)

                if cur and max and max > 0 and cur < max then
                    local pct = math.floor((cur / max) * 100 + 0.5)

                    text = DurabilityColor(pct) .. pct .. "%|r"
                end
            end

            if text ~= "" or slotFrame.bcpDurability then
                GetDurabilityFontString(slotFrame):SetText(text)
            end
        end
    end
end

-- =====================================
-- =   Gear summary tooltip (model)    =
-- =====================================

function M:GetAverageItemLevel(unit)
    local total, count = 0, 0

    for slot = 1, 18 do
        if slot ~= 4 then -- skip the shirt
            local ilvl = BCPLib:GetItemLevelFromEquipmentSlot(unit, slot)

            if ilvl and ilvl > 0 then
                total = total + ilvl
                count = count + 1
            end
        end
    end

    if count == 0 then
        return nil
    end

    return total / count
end

function M:ShowGearTooltip(frame, unit)
    if not self:IsEnabled("GearTooltip") then
        return
    end

    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    GameTooltip:AddLine(BCP_CM_GEAR_SUMMARY, 1, 0.82, 0)

    local ok, avg = pcall(self.GetAverageItemLevel, self, unit)

    if ok and avg then
        GameTooltip:AddDoubleLine(BCP_CM_AVG_ILVL, string.format("%.1f", avg), 1, 1, 1, 1, 1, 1)
    end

    if unit == "player" then
        local avgPct, lowPct, lowLabel, cost = self:GetDurabilitySummary()

        if avgPct then
            GameTooltip:AddDoubleLine(BCP_CM_AVG_DURABILITY,
                DurabilityColor(avgPct) .. string.format("%.0f%%", avgPct) .. "|r", 1, 1, 1, 1, 1, 1)

            if lowPct and lowPct < 100 then
                GameTooltip:AddDoubleLine(BCP_CM_LOWEST_DURABILITY,
                    lowLabel .. " " .. DurabilityColor(lowPct) .. string.format("%.0f%%", lowPct) .. "|r",
                    1, 1, 1, 1, 1, 1)
            end

            if cost and cost > 0 then
                GameTooltip:AddDoubleLine(BCP_CM_REPAIR_COST, FormatMoney(cost), 1, 1, 1, 1, 1, 1)
            end
        end
    end

    GameTooltip:Show()
end

local function HookTooltip(frame, unitGetter)
    if not frame or frame.bcpGearTooltip then
        return
    end

    frame.bcpGearTooltip = true

    local prevEnter = frame:GetScript("OnEnter")
    local prevLeave = frame:GetScript("OnLeave")

    frame:SetScript("OnEnter", function()
        if prevEnter then
            prevEnter()
        end

        M:ShowGearTooltip(this, unitGetter())
    end)

    frame:SetScript("OnLeave", function()
        if prevLeave then
            prevLeave()
        end

        GameTooltip:Hide()
    end)
end

-- Safe to call on every refresh; each frame is only hooked once.
function M:HookModelTooltips()
    HookTooltip(CharacterModelFrame, function() return "player" end)

    HookTooltip(InspectModelFrame, function()
        if InspectFrame and InspectFrame.unit and InspectFrame.unit ~= "" then
            return InspectFrame.unit
        end

        return "target"
    end)
end

-- =====================================
-- =   SuperWoW: /bcp export [target]  =
-- =====================================

function M:ExportGear(unit)
    if not ExportFile then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555BCP:|r " .. BCP_CM_EXPORT_MISSING)
        return
    end

    if unit ~= "player" and not UnitIsPlayer(unit) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555BCP:|r " .. BCP_CM_EXPORT_NO_UNIT)
        return
    end

    local unitName = UnitName(unit) or "Unknown"
    local lines = { "# Better Character Panel gear export: " .. unitName }

    for slot = 1, 19 do
        local okItem, item = pcall(GetEquippedItem, unit, slot)

        if okItem and item and item.itemId then
            local okName, itemName = pcall(GetItemStatsField, item.itemId, "displayName")
            local ilvl = BCPLib:GetItemLevelFromEquipmentSlot(unit, slot)
            local enchant = ""

            if item.permanentEnchantId and item.permanentEnchantId ~= 0 then
                local data = BCPLib:GetPermanentEnchantDataFromEnchantId(item.permanentEnchantId)

                enchant = (data and (data.Effect or data.Name)) or self:GetEnchantName(item.permanentEnchantId) or
                    ("enchant " .. item.permanentEnchantId)
            end

            table.insert(lines, string.format("slot=%d | id=%d | %s | ilvl=%s | %s",
                slot, item.itemId, (okName and itemName) or "?", ilvl or "?", enchant))
        end
    end

    local safeName = string.gsub(unitName, "[^%w]", "")
    local stamp = date and date("%Y%m%d_%H%M%S") or "gear"
    local fileName = "BCP_" .. safeName .. "_" .. stamp .. ".txt"

    ExportFile(fileName, table.concat(lines, "\n"))
    DEFAULT_CHAT_FRAME:AddMessage("|cff44ee44BCP:|r " .. BCP_CM_EXPORT_DONE .. " " .. fileName)
end

-- Returns true when the message was handled here.
function M:HandleSlash(msg)
    msg = string.lower(msg or "")

    if msg == "export" then
        self:ExportGear("player")
        return true
    end

    if msg == "export target" then
        self:ExportGear("target")
        return true
    end

    return false
end
