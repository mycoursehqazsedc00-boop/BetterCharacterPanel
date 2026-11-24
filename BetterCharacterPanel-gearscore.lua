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
local pendingCacheItems = {}

if C_Item and C_Item.RequestLoadItemDataByID then
	local gsCacheWatcher = CreateFrame("Frame")
	gsCacheWatcher:RegisterEvent("ITEM_DATA_LOAD_RESULT")
	gsCacheWatcher:SetScript("OnEvent", function()
		local itemId = tonumber(arg1)
		if not itemId or not pendingCacheItems[itemId] then
			return
		end
		pendingCacheItems[itemId] = nil
		if arg2 and BCP_Refresh then
			if PaperDollFrame and PaperDollFrame:IsVisible() then
				BCP_Refresh("player", "BCP_")
			end
			if InspectPaperDollFrame and InspectPaperDollFrame:IsVisible() then
				local unit = (InspectFrame and InspectFrame.unit and InspectFrame.unit ~= "") and InspectFrame.unit or "target"
				BCP_Refresh(unit, "BCP_Inspect_")
			end
		end
	end)
end

function GS:GetSlotScoreFromItem(unit, slotId, item)
	if not item or not item.itemId then
		return nil
	end

	local okLevel, itemLevel = pcall(GetItemLevel, item.itemId)
	if not okLevel or not itemLevel then
		return nil
	end

	-- Stock 1.12 GetItemInfo returns: name(1), link(2), quality(3), minLevel(4), type(5), subType(6), stack(7), equipLoc(8), texture(9)
	local okInfo, _, _, quality, _, _, _, _, equipSlot = pcall(GetItemInfo, item.itemId)

	if not okInfo or quality == nil then
		if C_Item and C_Item.RequestLoadItemDataByID and not pendingCacheItems[item.itemId] then
			pendingCacheItems[item.itemId] = true
			C_Item.RequestLoadItemDataByID(item.itemId)
		end
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

function GS:GetSlotScore(unit, slotId)
	local okItem, item = pcall(GetEquippedItem, unit, slotId)

	if not okItem or not item or not item.itemId then
		return nil
	end

	return self:GetSlotScoreFromItem(unit, slotId, item)
end

-- Maps GetItemInfo's equipLoc enum to the slot numbering used above, so an
-- item that ISN'T currently equipped (a bag or bank item) can still be
-- scored the same way. Ambiguous one-handers (INVTYPE_WEAPON, usable in
-- either hand) are scored as main hand, since that's the more heavily
-- weighted of the two for non-Hunters and there's no way to know which
-- hand a bag item would end up in. INVTYPE_RANGEDRIGHT covers Wands, Guns
-- and Crossbows on this (pre-2.4.3) client -- INVTYPE_RANGED alone is only
-- Bows. INVTYPE_RELIC (Idols/Totems/Librams) occupies the same physical
-- slot as a ranged weapon in vanilla.
local EQUIP_LOC_TO_SLOT = {
	INVTYPE_HEAD = 1,
	INVTYPE_NECK = 2,
	INVTYPE_SHOULDER = 3,
	INVTYPE_CHEST = 5,
	INVTYPE_ROBE = 5,
	INVTYPE_WAIST = 6,
	INVTYPE_LEGS = 7,
	INVTYPE_FEET = 8,
	INVTYPE_WRIST = 9,
	INVTYPE_HAND = 10,
	INVTYPE_FINGER = 11,
	INVTYPE_TRINKET = 13,
	INVTYPE_CLOAK = 15,
	INVTYPE_WEAPON = 16,
	INVTYPE_2HWEAPON = 16,
	INVTYPE_WEAPONMAINHAND = 16,
	INVTYPE_WEAPONOFFHAND = 17,
	INVTYPE_SHIELD = 17,
	INVTYPE_HOLDABLE = 17,
	INVTYPE_RANGED = 18,
	INVTYPE_RANGEDRIGHT = 18,
	INVTYPE_THROWN = 18,
	INVTYPE_RELIC = 18,
}

-- Scores an arbitrary item by link or numeric ID -- doesn't need to be
-- equipped, so this works for bag and bank items too. "unit" decides whose
-- class is used for the weapon-slot coefficient (almost always "player",
-- since a bag item belongs to you regardless of who you're looking at).
-- Returns the same (score, itemLevel, quality) shape as GetSlotScore, or
-- nil if the item's data isn't available (e.g. not cached yet) or it's not
-- an equippable item at all (consumables, quest items, etc. have no
-- equipLoc and are correctly skipped here).
function GS:GetItemLinkScore(itemLink, unit)
	if not itemLink then
		return nil
	end

	unit = unit or "player"

	local quality, itemLevel, equipSlot
	if C_Item and C_Item.GetItemInfo then
		local okInfo, _, _, q, ilvl, _, _, _, _, loc = pcall(C_Item.GetItemInfo, itemLink)
		if okInfo then
			quality, itemLevel, equipSlot = q, ilvl, loc
		end
	else
		local okInfo, _, _, q, _, _, _, _, loc = pcall(GetItemInfo, itemLink)
		if okInfo then
			quality, equipSlot = q, loc
		end
		local itemId = tonumber(itemLink)
		if not itemId and type(itemLink) == "string" then
			local _, _, idStr = string.find(itemLink, "item:(%d+)")
			itemId = idStr and tonumber(idStr)
		end
		if itemId and GetItemLevel then
			local okLvl, lvl = pcall(GetItemLevel, itemId)
			if okLvl then
				itemLevel = lvl
			end
		end
	end

	if quality == nil or not itemLevel or not equipSlot or equipSlot == "" then
		return nil
	end

	local slotId = EQUIP_LOC_TO_SLOT[equipSlot]

	if not slotId then
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
	local items = nil

	if GetEquippedItems then
		local okItems, res = pcall(GetEquippedItems, unit)
		if okItems and res then
			items = res
		end
	end

	for _, info in ipairs(BCP_SLOTS or {}) do
		local score
		if items then
			score = self:GetSlotScoreFromItem(unit, info.slotId, items[info.slotId])
		else
			score = self:GetSlotScore(unit, info.slotId)
		end

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

local trackedSlotLookup

local function IsBCPTrackedSlot(slotId)
	if not trackedSlotLookup then
		if not BCP_SLOTS then
			return false
		end

		trackedSlotLookup = {}
		for _, info in ipairs(BCP_SLOTS) do
			trackedSlotLookup[info.slotId] = true
		end
	end

	return trackedSlotLookup[slotId] == true
end

local function ShowItemScoreLine(score, tooltip)
	if not score then
		return
	end

	local tt = tooltip or GameTooltip
	tt:AddLine(" ")
	tt:AddDoubleLine(BCP_CM_ITEM_SCORE, string.format("%.1f", score), 1, 0.82, 0, 1, 1, 1)
	tt:Show()
end

local function AddItemScoreLine(unit, slotId, tooltip)
	if not (BCPConfig and BCPConfig.ClientMods and BCPConfig.ClientMods.ItemScore) then
		return
	end

	if not IsBCPTrackedSlot(slotId) then
		return
	end

	ShowItemScoreLine(GS:GetSlotScore(unit, slotId), tooltip)
end

-- For an item that isn't equipped -- a bag or bank item -- scored by link
-- instead of by slot, via GetItemLinkScore.
local function AddItemScoreLineForLink(itemLink, tooltip)
	if not (BCPConfig and BCPConfig.ClientMods and BCPConfig.ClientMods.ItemScore) then
		return
	end

	if not itemLink then
		return
	end

	local okScore, score = pcall(GS.GetItemLinkScore, GS, itemLink)

	ShowItemScoreLine(okScore and score or nil, tooltip)
end

-- SetInventoryItem covers both equipped gear (BCP_SLOTS, slot IDs 1-18)
-- and the bank's own main grid, which on this client is also shown via
-- SetInventoryItem with slot IDs outside that range. Pre-hooked so any
-- addon's earlier hook still runs first. The return value must be passed
-- through unchanged: SetInventoryItem returns true/false depending on
-- whether the slot has an item, and callers use that to decide whether to
-- keep the tooltip shown at all.
local previousSetInventoryItem = GameTooltip.SetInventoryItem

GameTooltip.SetInventoryItem = function(self, unit, slotId)
	local r1, r2, r3 = previousSetInventoryItem(self, unit, slotId)

	if IsBCPTrackedSlot(slotId) then
		if r1 then
			AddItemScoreLine(unit, slotId, self)
		end
	elseif r1 then
		local okLink, link = pcall(GetInventoryItemLink, unit, slotId)

		AddItemScoreLineForLink(okLink and link or nil, self)
	end

	return r1, r2, r3
end

-- Bag items (backpack, bags 0-4) and items inside purchased bank bag slots
-- both go through SetBagItem. The bank's own 24-slot main grid does not --
-- see the SetInventoryItem hook above. SetBagItem's own return values
-- (cooldown/repair-cost info) are preserved through unchanged, same
-- reasoning as SetInventoryItem above.
local previousSetBagItem = GameTooltip.SetBagItem

if previousSetBagItem then
	GameTooltip.SetBagItem = function(self, bag, slot)
		local r1, r2, r3 = previousSetBagItem(self, bag, slot)

		local okLink, link = pcall(GetContainerItemLink, bag, slot)

		AddItemScoreLineForLink(okLink and link or nil, self)

		return r1, r2, r3
	end
end

local function HookHyperlinkTooltip(tooltip)
	if not tooltip or not tooltip.SetHyperlink then
		return
	end

	local prev = tooltip.SetHyperlink
	tooltip.SetHyperlink = function(self, link, a, b, c)
		local r1, r2, r3 = prev(self, link, a, b, c)

		if type(link) == "string" and string.find(link, "item:%d+") then
			AddItemScoreLineForLink(link, self)
		end

		return r1, r2, r3
	end
end

local function HookTooltipLinkMethod(tooltip, methodName, linkResolver)
	if not tooltip or not tooltip[methodName] then
		return
	end

	local prev = tooltip[methodName]
	tooltip[methodName] = function(self, a1, a2, a3, a4)
		local r1, r2, r3 = prev(self, a1, a2, a3, a4)
		local link = linkResolver and linkResolver(a1, a2, a3, a4)

		if not link and self.GetItem then
			local okGet, _, ttLink = pcall(self.GetItem, self)
			if okGet then
				link = ttLink
			end
		end

		if link then
			AddItemScoreLineForLink(link, self)
		end

		return r1, r2, r3
	end
end

local EXTRA_GAME_TOOLTIP_HOOKS = {
	{ "SetMerchantItem", function(index) return GetMerchantItemLink and GetMerchantItemLink(index) end },
	{ "SetBuybackItem", function(index) return GetBuybackItemLink and GetBuybackItemLink(index) end },
	{ "SetAuctionItem", function(itemType, index) return GetAuctionItemLink and GetAuctionItemLink(itemType, index) end },
	{ "SetAuctionSellItem", nil },
	{ "SetLootItem", function(slot) return GetLootSlotLink and GetLootSlotLink(slot) end },
	{ "SetLootRollItem", function(id) return GetLootRollItemLink and GetLootRollItemLink(id) end },
	{ "SetQuestItem", function(qType, index) return GetQuestItemLink and GetQuestItemLink(qType, index) end },
	{ "SetQuestLogItem", function(qType, index) return GetQuestLogItemLink and GetQuestLogItemLink(qType, index) end },
	{ "SetTradeSkillItem", function(skill, id)
		if id and GetTradeSkillReagentItemLink then
			return GetTradeSkillReagentItemLink(skill, id)
		elseif GetTradeSkillItemLink then
			return GetTradeSkillItemLink(skill)
		end
		return nil
	end },
	{ "SetCraftItem", function(skill, id)
		if id and GetCraftReagentItemLink then
			return GetCraftReagentItemLink(skill, id)
		elseif GetCraftItemLink then
			return GetCraftItemLink(skill)
		end
		return nil
	end },
	{ "SetInboxItem", function(index, attachIndex)
		if GetInboxItemLink then
			local ok, link = pcall(GetInboxItemLink, index, attachIndex)
			if ok then return link end
		end
		return nil
	end },
	{ "SetSendMailItem", nil },
}

for _, entry in ipairs(EXTRA_GAME_TOOLTIP_HOOKS) do
	HookTooltipLinkMethod(GameTooltip, entry[1], entry[2])
end

HookHyperlinkTooltip(GameTooltip)
HookHyperlinkTooltip(ItemRefTooltip)

for _, compareName in ipairs({ "ShoppingTooltip1", "ShoppingTooltip2" }) do
	local compareTooltip = getglobal(compareName)
	if compareTooltip then
		if compareTooltip.SetInventoryItem then
			local prevInv = compareTooltip.SetInventoryItem
			compareTooltip.SetInventoryItem = function(self, unit, slot)
				local hasItem = prevInv(self, unit, slot)
				if hasItem then
					if IsBCPTrackedSlot(slot) then
						AddItemScoreLine(unit, slot, self)
					else
						local okLink, link = pcall(GetInventoryItemLink, unit, slot)
						AddItemScoreLineForLink(okLink and link or nil, self)
					end
				end
				return hasItem
			end
		end
		HookTooltipLinkMethod(compareTooltip, "SetBagItem", function(bag, slot)
			return GetContainerItemLink and bag and slot and GetContainerItemLink(bag, slot) or nil
		end)
		if compareTooltip.SetHyperlinkCompareItem then
			local prevCompare = compareTooltip.SetHyperlinkCompareItem
			compareTooltip.SetHyperlinkCompareItem = function(self, a1, a2, a3, a4)
				local r1, r2, r3 = prevCompare(self, a1, a2, a3, a4)
				if self.GetItem then
					local okGet, _, eqLink = pcall(self.GetItem, self)
					if okGet and eqLink then
						AddItemScoreLineForLink(eqLink, self)
					end
				end
				return r1, r2, r3
			end
		end
	end
end
