local _G = _G or getfenv(0)
local BS = BCPDBEnchants.Slot

BCP_SLOTS = {
    { tag = "Head",          slotId = BS.Head,     libSlot = BS.Head,     side = "left" },
    { tag = "Neck",          slotId = BS.Neck,     libSlot = BS.Neck,     side = "left" },
    { tag = "Shoulder",      slotId = BS.Shoulder, libSlot = BS.Shoulder, side = "left" },
    { tag = "Back",          slotId = BS.Cloak,    libSlot = BS.Cloak,    side = "left" },
    { tag = "Chest",         slotId = BS.Chest,    libSlot = BS.Chest,    side = "left" },
    { tag = "Wrist",         slotId = BS.Wrist,    libSlot = BS.Wrist,    side = "left",    valuesKey = "Wrists" },
    { tag = "Hands",         slotId = BS.Hands,    libSlot = BS.Hands,    side = "right" },
    { tag = "Waist",         slotId = BS.Belt,     libSlot = BS.Belt,     side = "right" },
    { tag = "Legs",          slotId = BS.Legs,     libSlot = BS.Legs,     side = "right" },
    { tag = "Feet",          slotId = BS.Feet,     libSlot = BS.Feet,     side = "right" },
    { tag = "Finger1",       slotId = BS.Finger1,  libSlot = BS.Finger1,  side = "right",   frameTag = "Finger0" },
    { tag = "Finger2",       slotId = BS.Finger2,  libSlot = BS.Finger2,  side = "right",   frameTag = "Finger1" },
    { tag = "Trinket1",      slotId = BS.Trinket1, libSlot = BS.Trinket1, side = "right",   frameTag = "Trinket0" },
    { tag = "Trinket2",      slotId = BS.Trinket2, libSlot = BS.Trinket2, side = "right",   frameTag = "Trinket1" },
    { tag = "MainHand",      slotId = BS.MainHand, libSlot = BS.MainHand, side = "special", valuesKey = "MainHand" },
    { tag = "SecondaryHand", slotId = BS.OffHand,  libSlot = BS.OffHand,  side = "special", valuesKey = "OffHand" },
    { tag = "Ranged",        slotId = BS.Range,    libSlot = BS.Range,    side = "special", valuesKey = "Ranged" },
}

BCP_STAT_FRAME_H = 11
BCP_CARD_PADDING = 4
BCP_TITLE_H = 16
BCP_CARD_MARGIN = 1

BCP_BCSSectionPrefixes = {}

local BCPActiveSkin = nil

local function BCP_GetActiveSkin()
    if BCPActiveSkin then
        return BCPActiveSkin
    end

    if BCP_IS_USING_PFUI then
        BCPActiveSkin = BCPSkin_pfUI
    else
        BCPActiveSkin = BCPSkin_Vanilla
    end

    return BCPActiveSkin
end

local function BCP_GetSlotFrame(info, prefix)
    local framePrefix = (prefix == "BCP_") and "Character" or "Inspect"
    local frameTag = info.frameTag or info.tag
    return getglobal(framePrefix .. frameTag .. "Slot")
end

local initialized = {}

local function BCP_Init(prefix, frameValues)
    if initialized[prefix] then
        return
    end

    for _, info in ipairs(BCP_SLOTS) do
        local side = info.side
        local slotFrame = BCP_GetSlotFrame(info, prefix)
        local tex = getglobal(prefix .. info.tag .. "_MissingEnchant")

        if tex then
            local sideKey = (side == "left" and "Left") or (side == "special" and "Special") or "Right"
            local anchorCorner = (side == "left" or side == "special") and "TOPRIGHT" or "TOPLEFT"
            local texFile = frameValues[sideKey .. "IconsMissingEnchantTexture"] or frameValues["RightIconsMissingEnchantTexture"]
            local texSize = frameValues[sideKey .. "IconsMissingEnchantSize"] or frameValues["RightIconsMissingEnchantSize"]
            local texOffsets = frameValues[sideKey .. "IconsMissingEnchantOffsets"] or frameValues["RightIconsMissingEnchantOffsets"]

            if texFile then
                tex:SetTexture(texFile)
            end

            if texSize then
                tex:SetWidth(texSize[1])
                tex:SetHeight(texSize[2])
            end

            if texOffsets and slotFrame then
                tex:ClearAllPoints()
                tex:SetPoint(anchorCorner, slotFrame, anchorCorner, texOffsets[1], texOffsets[2])
            end

            tex:SetVertexColor(1, 0, 0, 0.85)
        end

        if side == "left" or side == "right" or (side == "special" and info.valuesKey) then
            local permFS = getglobal(prefix .. info.tag .. "_Perm")
            local tempFS = getglobal(prefix .. info.tag .. "_Temp")

            if info.valuesKey then
                local vKey = info.valuesKey .. "Icon"

                if permFS and slotFrame then
                    local jh = frameValues[vKey .. "PermEnchantTextJustifyH"]
                    local anchors = frameValues[vKey .. "PermEnchantTextAnchors"]
                    local offsets = frameValues[vKey .. "PermEnchantOffsets"]

                    if jh then
                        permFS:SetJustifyH(jh)
                    end

                    if anchors and offsets then
                        permFS:ClearAllPoints()
                        permFS:SetPoint(anchors[1], slotFrame, anchors[2], offsets[1], offsets[2])
                    end
                end

                if tempFS and slotFrame then
                    local jh = frameValues[vKey .. "TempEnchantTextJustifyH"]
                    local anchors = frameValues[vKey .. "TempEnchantTextAnchors"]
                    local offsets = frameValues[vKey .. "TempEnchantOffsets"]

                    if jh then
                        tempFS:SetJustifyH(jh)
                    end

                    if anchors and offsets then
                        tempFS:ClearAllPoints()
                        tempFS:SetPoint(anchors[1], slotFrame, anchors[2], offsets[1], offsets[2])
                    end
                end
            else
                local sideKey = (side == "left") and "Left" or "Right"
                local textAnchor = (side == "left") and "LEFT" or "RIGHT"
                local slotAnchor = (side == "left") and "RIGHT" or "LEFT"
                local permOffsets = frameValues[sideKey .. "IconsPermEnchantOffsets"]
                local tempOffsets = frameValues[sideKey .. "IconsTempEnchantOffsets"]

                if permFS and permOffsets and slotFrame then
                    permFS:ClearAllPoints()
                    permFS:SetPoint(textAnchor, slotFrame, slotAnchor, permOffsets[1], permOffsets[2])
                end

                if tempFS and tempOffsets and slotFrame then
                    tempFS:ClearAllPoints()
                    tempFS:SetPoint(textAnchor, slotFrame, slotAnchor, tempOffsets[1], tempOffsets[2])
                end
            end
        end
    end

    local enchantCfgSection

    if prefix == "BCP_" then
        enchantCfgSection = BCPConfig and BCPConfig.CharacterPanel
    else
        enchantCfgSection = BCPConfig and BCPConfig.InspectPanel
    end

    local fontScale = (enchantCfgSection and enchantCfgSection.EnchantFontScale) or 1.0

    if fontScale ~= 1.0 then
        for _, info in ipairs(BCP_SLOTS) do
            local permFS = getglobal(prefix .. info.tag .. "_Perm")
            local tempFS = getglobal(prefix .. info.tag .. "_Temp")

            if permFS then
                local fontPath, fontSize, fontFlags = permFS:GetFont()
                if fontPath and fontSize then
                    permFS:SetFont(fontPath, fontSize * fontScale, fontFlags)
                end
            end

            if tempFS then
                local fontPath, fontSize, fontFlags = tempFS:GetFont()
                if fontPath and fontSize then
                    tempFS:SetFont(fontPath, fontSize * fontScale, fontFlags)
                end
            end
        end
    end

    initialized[prefix] = true
end

local function GetEnchantTexts(unit, slotId, libSlot, preloadedItem)
    local itemInfo = preloadedItem
    if not itemInfo then
        local okItem, res = pcall(GetEquippedItem, unit, slotId)
        if not okItem or not res then
            return "", "", false
        end
        itemInfo = res
    end

    local permText = ""
    local isMissing = false
    local permId = itemInfo.permanentEnchantId

    if permId and permId ~= 0 then
        local ok, data = pcall(BCPLib.GetPermanentEnchantDataFromEnchantId, BCPLib, permId)

        if ok and data and data.Effect then
            permText = "|cff44ee44" .. data.Effect .. "|r"
        else
            -- Not in BCP's database: ask the client (ClassicAPI) before giving up.
            local dbcName = BCPClientMods and BCPClientMods:GetEnchantName(permId)

            permText = "|cff44ee44" .. (dbcName or BCP_ENCHANTED) .. "|r"
        end
    else
        local ok, quality = pcall(GetItemStatsField, itemInfo.itemId, "quality")

        if ok and quality and quality >= BCPConfig.MissingEnchants.MinimumQuality then
            isMissing = BCPLib:IsEquippedItemMissingPermanentEnchant(unit, libSlot)
        end
    end

    local tempText = ""
    local tempId = itemInfo.tempEnchantId

    if tempId and tempId ~= 0 then
        local ok, data = pcall(BCPLib.GetTemporyEnchantDataFromEnchantId, BCPLib, tempId)

        if ok and data and data.Effect then
            tempText = "|cffffff44" .. data.Effect .. "|r"
        else
            local dbcName = BCPClientMods and BCPClientMods:GetEnchantName(tempId)

            tempText = "|cffffff44" .. (dbcName or BCP_TEMP_ENCHANT) .. "|r"
        end
    end

    return permText, tempText, isMissing
end

function BCP_GetBCSCategoryOrder()
    if not BCP_IS_USING_BCS or not BCS or type(BCS.PLAYERSTAT_DROPDOWN_OPTIONS) ~= "table" then
        return {}
    end

    if type(BCPConfig.StatPanel.CategoryOrder) ~= "table" then
        BCPConfig.StatPanel.CategoryOrder = {}
    end

    local order = BCPConfig.StatPanel.CategoryOrder
    local bcsCats = BCS.PLAYERSTAT_DROPDOWN_OPTIONS

    for i = table.getn(order), 1, -1 do
        local found = false

        for _, cat in ipairs(bcsCats) do
            if order[i] == cat then
                found = true; break
            end
        end

        if not found then
            table.remove(order, i)
        end
    end

    for _, cat in ipairs(bcsCats) do
        local found = false

        for _, oCat in ipairs(order) do
            if oCat == cat then
                found = true; break
            end
        end

        if not found then
            table.insert(order, cat)
        end
    end

    return order
end

function BCP_CreateBCSCompatStatFrame(skin, parent, name, yOffset, cardWidth)
    local cfg = skin.Config
    local fontScale = (BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.FontScale) or 1.0
    local leftPad = cfg.StatLabelLeftPad or 0
    local rightPad = cfg.StatValueRightPad or 0
    local scaledLabelRightPad = math.floor((cfg.StatLabelRightPad or 40) * fontScale)
    local scaledValueWidth = math.floor((cfg.StatValueWidth or 36) * fontScale)
    local labelWidth = cardWidth - scaledLabelRightPad - (BCP_CARD_PADDING * 2) - leftPad
    local valueWidth = scaledValueWidth
    local scaledStatH = math.ceil(BCP_STAT_FRAME_H * fontScale)
    local labelFontTemplate, valueFontTemplate = skin:GetStatFrameFonts()

    local frame = CreateFrame("Frame", name, parent)
    frame:SetWidth(cardWidth - (BCP_CARD_PADDING * 2))
    frame:SetHeight(scaledStatH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", BCP_CARD_PADDING, -yOffset)
    frame:EnableMouse(true)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local label = frame:CreateFontString(nil, "OVERLAY", labelFontTemplate)
    label:SetPoint("LEFT", frame, "LEFT", leftPad, 0)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1, 1, 1)

    local baseLabelSize = cfg.StatLabelFontSize or 10
    local lFontPath, _, lFontFlags = label:GetFont()
    label:SetFont(lFontPath, baseLabelSize * fontScale, lFontFlags)

    _G[name .. "Label"] = label

    local valueText = frame:CreateFontString(nil, "OVERLAY", valueFontTemplate)
    valueText:SetPoint("RIGHT", frame, "RIGHT", -rightPad, 0)
    valueText:SetWidth(valueWidth)
    valueText:SetJustifyH("RIGHT")

    local baseValueSize = cfg.StatValueFontSize or 10
    local vFontPath, _, vFontFlags = valueText:GetFont()
    valueText:SetFont(vFontPath, baseValueSize * fontScale, vFontFlags)

    _G[name .. "StatText"] = valueText

    return frame
end

local BCP_BCSRefreshing = false

function BCP_RefreshBCSSections(skipBCSUpdate)
    if not BCP_IS_USING_BCS then
        return
    end

    if BCP_BCSRefreshing then
        return
    end

    if table.getn(BCP_BCSSectionPrefixes) == 0 then
        return
    end

    BCP_BCSRefreshing = true

    if BCSFrame then
        BCSFrame:Hide()
    end

    if not skipBCSUpdate then
        BCS.needScanGear = true
        BCS.needScanSkills = true
        BCS.needUpdate = false
        BCS:UpdateStats()
    end

    if BCS then
        BCS.needScanSkills = true
        BCS:GetMHWeaponSkill()
        BCS:GetOHWeaponSkill()
        BCS:GetRangedWeaponSkill()
        BCS.needScanSkills = false
    end

    for _, sectionInfo in ipairs(BCP_BCSSectionPrefixes) do
        for j = 1, 6 do
            local lbl = getglobal(sectionInfo.prefix .. j .. "Label")
            local val = getglobal(sectionInfo.prefix .. j .. "StatText")

            if lbl then
                lbl:SetText("")
            end

            if val then
                val:SetText("")
            end
        end

        pcall(BCS.UpdatePaperdollStats, BCS, sectionInfo.prefix, sectionInfo.categoryKey)
    end

    if BCSFrame then
        BCSFrame:Hide()
    end

    BCP_BCSRefreshing = false
end

local bcpLastScrollLayout = nil

function BCP_RebuildBCSLayout()
    if not bcpLastScrollLayout then
        return
    end

    local l = bcpLastScrollLayout
    BCP_BuildScrollContent(l.skin, l.contentFrame, l.scrollFrame, l.scrollBar, l.bcsCardPrefix, l.bcsCatPrefix, l.nativeCardPrefix, true)
end

function BCP_BuildScrollContent(skin, contentFrame, scrollFrame, scrollBar, bcsCardPrefix, bcsCatPrefix, nativeCardPrefix, skipBCSUpdate)
    if not contentFrame then
        return
    end

    bcpLastScrollLayout = {
        skin = skin,
        contentFrame = contentFrame,
        scrollFrame = scrollFrame,
        scrollBar = scrollBar,
        bcsCardPrefix = bcsCardPrefix,
        bcsCatPrefix = bcsCatPrefix,
        nativeCardPrefix = nativeCardPrefix,
    }

    local infoFrame = scrollFrame and scrollFrame:GetParent()
    local cfg = skin.Config
    local fontScale = (BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.FontScale) or 1.0
    local isWideMode = BCP_IS_USING_BCS and BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.WideMode
    local baseInfoWidth = math.floor(cfg.InfoFrameWidth * fontScale)
    local resistanceFrameWidth = ((cfg.ResistanceItemWidth + cfg.ResistanceItemSpacing) * 5) - cfg.ResistanceItemSpacing
    local paddingAddition = (BCP_IS_USING_PFUI and 15) or 35

    if baseInfoWidth <= resistanceFrameWidth then
        baseInfoWidth = resistanceFrameWidth + paddingAddition
    end

    if infoFrame then
        infoFrame:SetWidth(baseInfoWidth)
    end

    local scrollPaddingX = (BCP_IS_USING_PFUI and 2) or 17
    local contentW = baseInfoWidth - scrollPaddingX
    local maxH = (scrollFrame and scrollFrame:GetHeight()) or 400

    if not isWideMode and BCP_IS_USING_BCS then
        local scrollbarWidth = (BCP_IS_USING_PFUI and 20) or 25

        contentW = contentW - scrollbarWidth
    end

    contentFrame:SetWidth(contentW)

    local titleTopPad = cfg.StatCardTitleTopPad or BCP_CARD_PADDING
    local bottomPad = cfg.StatCardBottomPad or BCP_CARD_PADDING
    local rowSpacing = cfg.StatRowSpacing or 0
    local columnSpacing = 4
    local cardWidth = contentW - (BCP_CARD_MARGIN * 2)
    local scaledStatH = math.ceil(BCP_STAT_FRAME_H * fontScale)
    local yOffset = 0

    if BCP_IS_USING_BCS then
        local categoryOrder = BCP_GetBCSCategoryOrder()
        local hiddenCats = BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.HiddenCategories
        local collapsedCats = BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.CollapsedCategories
        local currentX = BCP_CARD_MARGIN
        local currentY = 0
        local visibleIdx = 0

        BCP_BCSSectionPrefixes = {}

        local oldIdx = 1
        while _G[bcsCardPrefix .. oldIdx] do
            _G[bcsCardPrefix .. oldIdx]:Hide()
            oldIdx = oldIdx + 1
        end

        for _, categoryKey in ipairs(categoryOrder) do
            if not (hiddenCats and hiddenCats[categoryKey]) then
                visibleIdx = visibleIdx + 1
                local isCollapsed = collapsedCats and collapsedCats[categoryKey] and true or false
                local rowStep = scaledStatH + rowSpacing
                local cardH

                if isCollapsed then
                    cardH = titleTopPad + BCP_TITLE_H + bottomPad
                else
                    cardH = titleTopPad + BCP_TITLE_H + (6 * rowStep) - rowSpacing + bottomPad
                end

                if isWideMode and currentY + cardH > maxH and currentY > 0 then
                    currentX = currentX + cardWidth + columnSpacing
                    currentY = 0
                end

                local cardName = bcsCardPrefix .. visibleIdx
                local card = _G[cardName]
                local isNewCard = false

                if not card then
                    isNewCard = true
                    card = CreateFrame("Frame", cardName, contentFrame)
                    skin:ApplyCardBackdrop(card)

                    local titleFrame = CreateFrame("Frame", nil, card)
                    titleFrame:SetAllPoints(card)
                    titleFrame:SetFrameLevel(card:GetFrameLevel() + 2)

                    local title = titleFrame:CreateFontString(nil, "OVERLAY")
                    local fontPath, fontSize, fontFlags = skin:GetCardTitleFont()
                    title:SetFont(fontPath, math.floor(fontSize * fontScale), fontFlags)
                    title:SetPoint("TOP", card, "TOP", 0, -titleTopPad)
                    title:SetWidth(cardWidth - (BCP_CARD_PADDING * 2) - 24)
                    title:SetJustifyH("CENTER")
                    title:SetTextColor(1, 0.8, 0)
                    card.bcpTitle = title

                    local collapseBtn = CreateFrame("Button", nil, titleFrame)
                    collapseBtn:SetWidth(14)
                    collapseBtn:SetHeight(14)
                    collapseBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -BCP_CARD_PADDING - 2, -titleTopPad)
                    collapseBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
                    local btnText = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    btnText:SetAllPoints(collapseBtn)
                    btnText:SetJustifyH("CENTER")
                    btnText:SetTextColor(1, 0.82, 0)
                    collapseBtn.bcpText = btnText
                    collapseBtn:SetScript("OnEnter", function()
                        if this.bcpText then
                            this.bcpText:SetTextColor(1, 1, 1)
                        end
                    end)
                    collapseBtn:SetScript("OnLeave", function()
                        if this.bcpText then
                            this.bcpText:SetTextColor(1, 0.82, 0)
                        end
                    end)
                    collapseBtn:SetScript("OnClick", function()
                        local key = this.categoryKey
                        if not key or not BCPConfig or not BCPConfig.StatPanel then
                            return
                        end
                        BCPConfig.StatPanel.CollapsedCategories = BCPConfig.StatPanel.CollapsedCategories or {}
                        if BCPConfig.StatPanel.CollapsedCategories[key] then
                            BCPConfig.StatPanel.CollapsedCategories[key] = nil
                        else
                            BCPConfig.StatPanel.CollapsedCategories[key] = true
                        end
                        BCP_RebuildBCSLayout()
                    end)
                    card.bcpCollapseBtn = collapseBtn
                end

                card:ClearAllPoints()
                card:SetWidth(cardWidth)
                card:SetHeight(cardH)
                card:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", currentX, -currentY)
                card:Show()

                card.bcpTitle:SetText(BCS.L[categoryKey] or categoryKey)
                card.bcpCollapseBtn.categoryKey = categoryKey
                card.bcpCollapseBtn.bcpText:SetText(isCollapsed and "+" or "-")

                local rowPrefix = bcsCatPrefix .. visibleIdx .. "_"
                local rowYStart = titleTopPad + BCP_TITLE_H

                for j = 1, 6 do
                    local statFrame = _G[rowPrefix .. j]
                    if not statFrame then
                        statFrame = BCP_CreateBCSCompatStatFrame(skin, card, rowPrefix .. j, rowYStart + ((j - 1) * rowStep), cardWidth)
                    end
                    if isCollapsed then
                        statFrame:Hide()
                    else
                        statFrame:Show()
                    end
                end

                if not isCollapsed then
                    table.insert(BCP_BCSSectionPrefixes, { prefix = rowPrefix, categoryKey = categoryKey })
                end

                currentY = currentY + cardH + 3
                if not isWideMode then
                    yOffset = currentY
                end
            end
        end

        if isWideMode then
            local totalContentWidth = (visibleIdx > 0) and (currentX + cardWidth + BCP_CARD_MARGIN) or contentW
            contentFrame:SetWidth(totalContentWidth)

            if infoFrame then
                infoFrame:SetWidth(totalContentWidth + scrollPaddingX)

                if BCP_IS_USING_PFUI and BCPPFUIUnifiedBackdrop and BCPPFUIUnifiedBackdrop.backdrop then
                    BCPPFUIUnifiedBackdrop.backdrop:SetPoint("BOTTOMRIGHT", -30 + infoFrame:GetWidth() + 5, 72)
                end
            end

            contentFrame:SetHeight(maxH)
        else
            contentFrame:SetWidth(contentW)
            -- Was "yOffset - 45": an unexplained fixed subtraction not
            -- present in the equivalent native (non-BCS) branch below, which
            -- uses the same yOffset accumulation with no adjustment at all.
            -- The scrollbar's max scroll range is computed directly from
            -- this height, so under-reporting it meant some bottom rows of
            -- the last card(s) were permanently unreachable, not just
            -- visually cramped -- worse with fewer categories enabled, since
            -- 45px is a larger fraction of a short total height.
            contentFrame:SetHeight(yOffset)

            if BCP_IS_USING_PFUI and BCPPFUIUnifiedBackdrop and BCPPFUIUnifiedBackdrop.backdrop and infoFrame then
                BCPPFUIUnifiedBackdrop.backdrop:SetPoint("BOTTOMRIGHT", -30 + infoFrame:GetWidth() + 5, 72)
            end
        end

        if not contentFrame.bcpHooked then
            contentFrame.bcpHooked = true
            local _Orig_BCS_UpdateStats = BCS.UpdateStats

            BCS.UpdateStats = function(self)
                _Orig_BCS_UpdateStats(self)

                BCP_RefreshBCSSections(true)
            end
        end
    else
        local FRAME_H = math.ceil((cfg.NativeStatRowHeight or BCP_STAT_FRAME_H) * fontScale)
        local cardWidthExtra = cfg.NativeCardWidthExtra or 17
        local cardXOffset = cfg.NativeStatCardXOffset or 0
        local statFrameWidthExtra = cfg.NativeStatFrameWidthExtra or 0
        local statFrameXOffset = cfg.NativeStatFrameXOffset or 0
        local nativeCards = {
            {
                title = "Base Stats",
                frames = {
                    CharacterStatFrame1,
                    CharacterStatFrame2,
                    CharacterStatFrame3,
                    CharacterStatFrame4,
                    CharacterStatFrame5,
                    CharacterArmorFrame,
                },
            },
            {
                title = "Attack Ratings",
                frames = {
                    CharacterAttackFrame,
                    CharacterAttackPowerFrame,
                    CharacterDamageFrame,
                    CharacterRangedAttackFrame,
                    CharacterRangedAttackPowerFrame,
                    CharacterRangedDamageFrame,
                },
            },
        }

        local catTotal = table.getn(nativeCards)
        local innerWidth = cardWidth - (BCP_CARD_PADDING * 2)
        local frameRightPadding = 22
        local calculatedFrameW = (cardWidth + cardWidthExtra) - (BCP_CARD_PADDING + statFrameXOffset) - frameRightPadding +
            statFrameWidthExtra

        for i, cardDef in ipairs(nativeCards) do
            local rowCount = table.getn(cardDef.frames)
            local rowStep = FRAME_H + rowSpacing
            local cardH = titleTopPad + BCP_TITLE_H + (rowCount * rowStep) - rowSpacing + bottomPad

            local card = CreateFrame("Frame", nativeCardPrefix .. i, contentFrame)
            card:SetWidth(cardWidth + cardWidthExtra)
            card:SetHeight(cardH)
            card:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", BCP_CARD_MARGIN + cardXOffset, -yOffset)

            skin:ApplyCardBackdrop(card)

            local titleFrame = CreateFrame("Frame", nil, card)
            titleFrame:SetAllPoints(card)
            titleFrame:SetFrameLevel(card:GetFrameLevel() + 2)

            local titleFS = titleFrame:CreateFontString(nil, "OVERLAY")
            local fontPath, fontSize, fontFlags = skin:GetCardTitleFont()
            titleFS:SetFont(fontPath, math.floor(fontSize * fontScale), fontFlags)
            titleFS:SetPoint("TOP", card, "TOP", 0, -titleTopPad)
            titleFS:SetWidth(innerWidth)
            titleFS:SetJustifyH("CENTER")
            titleFS:SetTextColor(1, 0.8, 0)
            titleFS:SetText(cardDef.title)

            local rowY = -(titleTopPad + BCP_TITLE_H)

            for _, statFrame in ipairs(cardDef.frames) do
                statFrame:SetParent(card)
                statFrame:ClearAllPoints()
                statFrame:SetPoint("TOPLEFT", card, "TOPLEFT", BCP_CARD_PADDING + statFrameXOffset, rowY)
                statFrame:SetWidth(calculatedFrameW)
                statFrame:Show()
                rowY = rowY - rowStep
            end

            yOffset = yOffset + cardH

            if i < catTotal then
                yOffset = yOffset + 3
            end
        end

        contentFrame:SetHeight(yOffset)
    end

    if scrollFrame and scrollBar then
        if isWideMode then
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:SetValue(0)
            scrollBar:Hide()
        else
            local contentH = contentFrame:GetHeight()
            local frameH = scrollFrame:GetHeight()
            local maxScroll = math.max(0, contentH - frameH)

            scrollBar:SetMinMaxValues(0, maxScroll)
            if scrollBar:GetValue() > maxScroll then
                scrollBar:SetValue(maxScroll)
            end
            scrollBar:Show()
        end
    end

    BCP_RefreshBCSSections(skipBCSUpdate == true)
end

function BCP_Refresh(unit, prefix)
    local skin = BCP_GetActiveSkin()
    BCP_Init(prefix, skin.FrameValues)

    if prefix == "BCP_" then
        -- Hide character stats frame
        if CharacterAttributesFrame then
            CharacterAttributesFrame:Hide()
        end
    end

    local weaponEnchantData
    if unit == "player" and BCPClientMods and BCPClientMods.ReadWeaponEnchants then
        weaponEnchantData = BCPClientMods:ReadWeaponEnchants()
    end

    local equippedItems = nil
    if GetEquippedItems then
        local okItems, res = pcall(GetEquippedItems, unit)
        if okItems and res then
            equippedItems = res
        end
    end

    local missingCount = 0
    for _, info in ipairs(BCP_SLOTS) do
        local tag = info.tag
        local permText, tempText, isMissing = GetEnchantTexts(unit, info.slotId, info.libSlot, equippedItems and equippedItems[info.slotId] or nil)

        local permFS = getglobal(prefix .. tag .. "_Perm")

        if unit == "player" and not BCPConfig.PermanentEnchants.ShowOnCharPanel then
            permText = ""
        end

        if unit ~= "player" and not BCPConfig.PermanentEnchants.ShowOnInspect then
            permText = ""
        end

        if unit == "player" and not BCPConfig.TemporaryEnchants.ShowOnCharPanel then
            tempText = ""
        end

        if unit ~= "player" and not BCPConfig.TemporaryEnchants.ShowOnInspect then
            tempText = ""
        end

        if permFS then
            permFS:SetText(permText)
        end

        local tempFS = getglobal(prefix .. tag .. "_Temp")

        if tempFS then
            if unit == "player" and BCPClientMods then
                -- Adds the remaining time / charges on weapon slots (ClassicAPI).
                tempText = BCPClientMods:DecorateTempText(tempFS, tempText, info.slotId, weaponEnchantData)
            end

            tempFS:SetText(tempText)
        end

        local missingTex = getglobal(prefix .. tag .. "_MissingEnchant")
        local unitLevel = UnitLevel(unit)

        if missingTex then
            if isMissing and BCPConfig.MissingEnchants.Show and (not BCPConfig.MissingEnchants.OnlyAtLevel60 or (unitLevel and unitLevel == 60)) then
                missingTex:Show()
                missingCount = missingCount + 1
            else
                missingTex:Hide()
            end
        end
    end

    if BCPClientMods then
        if unit == "player" then
            BCPClientMods.LastPlayerMissingEnchants = missingCount
        else
            BCPClientMods:CaptureInspectSnapshot(unit, missingCount, equippedItems)
        end
        BCPClientMods:RefreshSlotDurability(unit, prefix)
        BCPClientMods:HookModelTooltips()
        BCPClientMods:Trace("BCP_Refresh unit=" .. tostring(unit) .. " prefix=" .. tostring(prefix) .. " missing=" .. tostring(missingCount))
    end
end


-- =============================
-- =   Character Frame Hooks   =
-- =============================

local _Orig_CharacterFrame_OnShow = CharacterFrame_OnShow

function CharacterFrame_OnShow()
    if _Orig_CharacterFrame_OnShow then
        _Orig_CharacterFrame_OnShow()
    end

    BCP_GetActiveSkin():OnCharacterFrameShow()
end

local _Orig_CharacterFrame_OnHide = CharacterFrame_OnHide

function CharacterFrame_OnHide()
    BCP_GetActiveSkin():OnCharacterFrameHide()

    if _Orig_CharacterFrame_OnHide then
        _Orig_CharacterFrame_OnHide()
    end
end

local _Orig_CharacterFrameTab_OnClick = CharacterFrameTab_OnClick

function CharacterFrameTab_OnClick()
    if _Orig_CharacterFrameTab_OnClick then
        _Orig_CharacterFrameTab_OnClick()
    end

    BCP_GetActiveSkin():OnCharacterFrameTabClick()
end

local _Orig_CharacterFrame_ShowSubFrame = CharacterFrame_ShowSubFrame

function CharacterFrame_ShowSubFrame(arg1)
    BCP_GetActiveSkin():OnCharacterFrameShowSubFrame()

    if _Orig_CharacterFrame_ShowSubFrame then
        _Orig_CharacterFrame_ShowSubFrame(arg1)
    end
end

-- =================================
-- =   Paper Doll Frame Hooks   =
-- =================================

local _Orig_PaperDollFrame_OnShow = PaperDollFrame_OnShow

function PaperDollFrame_OnShow()
    if _Orig_PaperDollFrame_OnShow then
        _Orig_PaperDollFrame_OnShow()
    end

    PaperDollFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

    -- Hide vanilla model rotate buttons
    if CharacterModelFrameRotateLeftButton then
        CharacterModelFrameRotateLeftButton:Hide()
    end

    if CharacterModelFrameRotateRightButton then
        CharacterModelFrameRotateRightButton:Hide()
    end

    -- Hide the default BCS panel
    if BCP_IS_USING_BCS and BCSFrame then
        BCSFrame:Hide()
    end

    BCP_GetActiveSkin():OnPaperDollShow()
    BCP_Refresh("player", "BCP_")

    if BCP_IS_USING_BCS and table.getn(BCP_BCSSectionPrefixes) > 0 then
        BCP_RefreshBCSSections(false)
    end
end

local _Orig_PaperDollFrame_OnEvent = PaperDollFrame_OnEvent

function PaperDollFrame_OnEvent(event, a1)
    if _Orig_PaperDollFrame_OnEvent then
        _Orig_PaperDollFrame_OnEvent(event, a1)
    end

    local unit = a1 or arg1
    if event == "UNIT_INVENTORY_CHANGED" then
        if unit == "player" and PaperDollFrame:IsVisible() then
            BCP_Refresh("player", "BCP_")
            BCP_RefreshBCSSections(false)
        elseif InspectFrame and InspectFrame.unit and unit == InspectFrame.unit then
            if InspectPaperDollFrame and InspectPaperDollFrame:IsVisible() then
                BCP_Refresh(InspectFrame.unit, "BCP_Inspect_")
            end
        end
    end
end

local BCP_GUIDFallbackFrame = CreateFrame("Frame")
local BCP_GUIDFallbackPendingPlayer = false
local BCP_GUIDFallbackPendingInspect = false
local BCP_GUIDFallbackTimer = 0

local function BCP_GUIDFallbackOnUpdate()
    if not BCP_GUIDFallbackPendingPlayer and not BCP_GUIDFallbackPendingInspect then
        BCP_GUIDFallbackFrame:SetScript("OnUpdate", nil)
        return
    end

    BCP_GUIDFallbackTimer = BCP_GUIDFallbackTimer - arg1

    if BCP_GUIDFallbackTimer > 0 then
        return
    end

    local doPlayer = BCP_GUIDFallbackPendingPlayer
    local doInspect = BCP_GUIDFallbackPendingInspect
    BCP_GUIDFallbackPendingPlayer = false
    BCP_GUIDFallbackPendingInspect = false
    BCP_GUIDFallbackFrame:SetScript("OnUpdate", nil)

    if doPlayer and PaperDollFrame and PaperDollFrame:IsVisible() then
        BCP_Refresh("player", "BCP_")

        if BCP_IS_USING_BCS and BCS then
            BCS.needScanGear = true
            BCS.needScanSkills = true
            BCS:UpdateStats()
        end
    end

    if doInspect and InspectPaperDollFrame and InspectPaperDollFrame:IsVisible() then
        local inspectUnit = (InspectFrame and InspectFrame.unit and InspectFrame.unit ~= "") and InspectFrame.unit or "target"
        BCP_Refresh(inspectUnit, "BCP_Inspect_")
    end
end

BCP_GUIDFallbackFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
BCP_GUIDFallbackFrame:SetScript("OnEvent", function()
    if event ~= "UNIT_INVENTORY_CHANGED" or arg1 == nil then
        return
    end

    if arg1 ~= "player" then
        local ok, isPlayer = pcall(UnitIsUnit, "player", arg1)
        if ok and isPlayer then
            BCP_GUIDFallbackPendingPlayer = true
            BCP_GUIDFallbackTimer = 0.2
            BCP_GUIDFallbackFrame:SetScript("OnUpdate", BCP_GUIDFallbackOnUpdate)
        end
    end

    if InspectPaperDollFrame and InspectPaperDollFrame:IsVisible() then
        local inspectUnit = (InspectFrame and InspectFrame.unit and InspectFrame.unit ~= "") and InspectFrame.unit or "target"
        if arg1 ~= inspectUnit then
            local ok, isInspect = pcall(UnitIsUnit, inspectUnit, arg1)
            if ok and isInspect then
                BCP_GUIDFallbackPendingInspect = true
                BCP_GUIDFallbackTimer = 0.2
                BCP_GUIDFallbackFrame:SetScript("OnUpdate", BCP_GUIDFallbackOnUpdate)
            end
        end
    end
end)

-- ===========================
-- =   Inspect Frame Hooks   =
-- ===========================

local function BCP_GetInspectUnit()
    if InspectFrame and InspectFrame.unit and InspectFrame.unit ~= "" then
        return InspectFrame.unit
    end

    return "target"
end

local _Orig_InspectPaperDollFrame_OnShow = InspectPaperDollFrame_OnShow

function InspectPaperDollFrame_OnShow()
    if _Orig_InspectPaperDollFrame_OnShow then
        _Orig_InspectPaperDollFrame_OnShow()
    end

    if InspectModelRotateLeftButton then
        InspectModelRotateLeftButton:Hide()
    end

    if InspectModelRotateRightButton then
        InspectModelRotateRightButton:Hide()
    end

    BCP_GetActiveSkin():OnInspectShow()
    BCP_Refresh(BCP_GetInspectUnit(), "BCP_Inspect_")
end

local BCP_InspectTargetFrame = CreateFrame("Frame")
BCP_InspectTargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
BCP_InspectTargetFrame:RegisterEvent("PLAYER_LOGIN")
BCP_InspectTargetFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        if BCS and type(BCS.RegisterCallback) == "function" then
            BCS:RegisterCallback("GEAR_UPDATED", function()
                if PaperDollFrame and PaperDollFrame:IsVisible() then
                    BCP_Refresh("player", "BCP_")
                    if BCP_IS_USING_BCS and BCP_RefreshBCSSections then
                        BCP_RefreshBCSSections(true)
                    end
                end
            end)
        end
        return
    end
    if InspectPaperDollFrame and InspectPaperDollFrame:IsVisible() then
        local inspectUnit = BCP_GetInspectUnit()
        if UnitExists(inspectUnit) and UnitIsPlayer(inspectUnit) then
            BCP_Refresh(inspectUnit, "BCP_Inspect_")
        end
    end
end)
