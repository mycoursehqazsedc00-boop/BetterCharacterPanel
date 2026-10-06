-- O――――――――――――――――――――――――――――――――――――――――――O
-- |               Gear Score                          |
-- O――――――――――――――――――――――――――――――――――――――――――O
--
-- This is a port of the scoring formula already used by S_ItemTip's
-- ItemSocre.lua (itself a Turtle-tuned variant of the classic Shagu
-- GearScore addon). The weights below are NOT something this addon
-- invented -- they're copied as-is from that formula, so BCP reports the
-- same numbers players already see from that addon rather than a made-up
-- alternative.
--
-- Item level comes from Nampower's GetItemLevel (via BCPLib, already used
-- elsewhere in this addon), which reads item-stats data directly and isn't
-- affected by the "item not cached yet" gap that stock GetItemInfo has.
-- Quality and weapon-type detection use stock GetItemInfo instead -- see
-- the comment on GetSlotScore for why.

BCPGearScore = BCPGearScore or {}
local GS = BCPGearScore

local QUALITY_SCALE = {
	[0] = 1,    -- poor
	[1] = 0.25, -- common
	[2] = 0.6,  -- uncommon
	[3] = 0.85, -- rare
	[4] = 1.0,  -- epic
	[5] = 1.3,  -- legendary
}

local SLOT_COEFFICIENTS = {
	[1] = 1,       -- head
	[2] = 0.5625,  -- neck
	[3] = 0.75,    -- shoulder
	[5] = 1,       -- chest
	[6] = 0.5625,  -- waist
	[7] = 0.75,    -- legs
	[8] = 0.75,    -- feet
	[9] = 0.75,    -- wrist
	[10] = 0.75,   -- hands
	[11] = 0.5625, -- finger1
	[12] = 0.5625, -- finger2
	[13] = 0.5625, -- trinket1
	[14] = 0.5625, -- trinket2
	[15] = 0.5625, -- cloak
	-- 16 (main hand), 17 (off hand), 18 (ranged) are class/weapon dependent;
	-- see GetSlotCoefficient.
}

function GS:CalculateItemScore(quality, itemLevel)
	if not itemLevel or itemLevel <= 0 then
		return nil
	end

	local scale = QUALITY_SCALE[quality]

	if scale == nil then
		scale = 1
	end

	return itemLevel * scale
end

function GS:GetSlotCoefficient(slotId, unit, isTwoHand)
	if slotId == 16 or slotId == 17 or slotId == 18 then
		local _, class = UnitClass(unit)
		local isHunter = class == "HUNTER"

		if slotId == 16 then
			if isTwoHand then
				return isHunter and 1 or 2.6836
			end

			return isHunter and 0.5 or 1.6836
		elseif slotId == 17 then
			return isHunter and 0.5 or 1
		else -- 18: ranged
			return isHunter and 2 or 0.3164
		end
	end

	return SLOT_COEFFICIENTS[slotId] or 1
end

-- Returns this slot's contribution to gear score, plus the item level and
-- quality it was computed from (for display), or nil if the slot is empty
-- or its data isn't available (e.g. an other-faction inspect target).
--
-- Quality and two-handed detection both come from stock GetItemInfo (the
-- same source the original ItemSocre.lua formula uses for quality), rather
-- than Nampower's GetItemStatsField -- unlike GetEquippedItem and
-- GetItemLevel (both already proven by the average-item-level feature
-- above), GetItemStatsField's "quality" field was never actually confirmed
-- against a live client, and silently returning nil here would mean no
-- score ever showing at all. GetItemInfo carries the usual "not cached
-- yet" caveat, but for your own already-equipped gear that's almost always
-- a non-issue since the client has already seen it.
function GS:GetSlotScore(unit, slotId)
	local okItem, item = pcall(GetEquippedItem, unit, slotId)

	if not okItem or not item or not item.itemId then
		return nil
	end

	local itemLevel = BCPLib:GetItemLevelFromEquipmentSlot(unit, slotId)
	local okInfo, _, _, quality, _, _, _, _, _, equipSlot = pcall(GetItemInfo, item.itemId)

	if not itemLevel or not okInfo or quality == nil then
		return nil
	end

	local isTwoHand = slotId == 16 and equipSlot == "INVTYPE_2HWEAPON"

	local coef = self:GetSlotCoefficient(slotId, unit, isTwoHand)
	local base = self:CalculateItemScore(quality, itemLevel)

	if not base then
		return nil
	end

	return base * coef, itemLevel, quality
end

-- Total gear score for a unit, or nil if nothing could be scored at all
-- (e.g. no gear data available for that unit).
function GS:GetTotalScore(unit)
	local total, sawAny = 0, false

	for _, info in ipairs(BCP_SLOTS or {}) do
		local score = self:GetSlotScore(unit, info.slotId)

		if score then
			total = total + score
			sawAny = true
		end
	end

	if not sawAny then
		return nil
	end

	return tonumber(string.format("%.1f", (total / 17) * 1.355))
end

-- ==========================================================
-- =   Per-item score line on each equipped item's tooltip  =
-- ==========================================================

local function IsBCPTrackedSlot(slotId)
	for _, info in ipairs(BCP_SLOTS or {}) do
		if info.slotId == slotId then
			return true
		end
	end

	return false
end

local function AddItemScoreLine(unit, slotId)
	if not (BCPConfig and BCPConfig.ClientMods and BCPConfig.ClientMods.ItemScore) then
		return
	end

	if not IsBCPTrackedSlot(slotId) then
		return
	end

	local score = GS:GetSlotScore(unit, slotId)

	if not score then
		return
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(BCP_CM_ITEM_SCORE, string.format("%.1f", score), 1, 0.82, 0, 1, 1, 1)
	GameTooltip:Show()
end

-- SetInventoryItem is only used for an item actually equipped in a unit's
-- slot (bags/bank/mail use their own Set*Item calls), so this only ever
-- touches equipped-gear tooltips, which is exactly what gear score is
-- about. Pre-hooked so any addon's earlier hook still runs first. The
-- return value must be passed through unchanged: SetInventoryItem returns
-- true/false depending on whether the slot has an item, and callers use
-- that to decide whether to keep the tooltip shown at all.
local previousSetInventoryItem = GameTooltip.SetInventoryItem

GameTooltip.SetInventoryItem = function(self, unit, slotId)
	local hasItem = previousSetInventoryItem(self, unit, slotId)

	AddItemScoreLine(unit, slotId)

	return hasItem
end
