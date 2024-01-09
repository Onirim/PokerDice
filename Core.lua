-- Gestion de la localisation
local _, core = ...
local L = core.Locales[GetLocale()] or core.Locales["enUS"]
local version = GetAddOnMetadata("PokerDice", "Version")

-- Enregistrement du préfixe de l'addon
C_ChatInfo.RegisterAddonMessagePrefix("PokerDice")

---------------------------
--   VARIABLES DE JEU    --
---------------------------
charGold = 6
charPenalty = 0
globalPot = 0
charBid = 0
isFirstRoll = true --Est le premier lancer de la manche ?
isFinished = false --le second lancer de la manche a t-il été fait ?

----------------------------
--   MESSAGE D'ACCUEIL    --
----------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    print("|cFFdaa520PokerDice " .. version .. L["PokerDice is loaded"])
end)
----------------------------
--  INTERFACE PRINCIPALE  --
----------------------------

-- Création de la fenêtre principale
local PokerdiceFrame = CreateFrame("Frame", "PokerdiceFrame", UIParent, "ButtonFrameTemplate")
PokerdiceFrame:SetPortraitToAsset("Interface\\ICONS\\misc_rune_pvp_random")
ButtonFrameTemplate_HideButtonBar(PokerdiceFrame)
PokerdiceFrame:SetSize(200, 470) 
PokerdiceFrame:SetPoint("CENTER") 
PokerdiceFrame:SetTitle("PokerDice")
PokerdiceFrame:EnableMouse(true)
PokerdiceFrame:SetMovable(true)
PokerdiceFrame:RegisterForDrag("LeftButton")
PokerdiceFrame:SetScript("OnDragStart", PokerdiceFrame.StartMoving)
PokerdiceFrame:SetScript("OnDragStop", PokerdiceFrame.StopMovingOrSizing)
PokerdiceFrame:SetFrameStrata("BACKGROUND")
PokerdiceFrame:Hide()

-- Création du bouton de roll
local rollButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
rollButton:SetPoint("TOP", PokerdiceFrame, "BOTTOM", 0, 47)
rollButton:SetSize(150, 40)
rollButton:SetText(L["Roll the dice"])
rollButton:SetNormalFontObject("GameFontNormalLarge")
rollButton:SetHighlightFontObject("GameFontHighlightLarge")

-- Création des dés
local dice = {}
local selected = {}
for i = 1, 5 do
    local diceFrame = CreateFrame("Frame", nil, PokerdiceFrame, "InsetFrameTemplate2")
    diceFrame:SetSize(60, 60)
    diceFrame:SetPoint("TOP", PokerdiceFrame, "TOP", 0, -70 * i)
	local background = diceFrame:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetTexture("Interface\\Icons\\6or_garrison_blackiron")
    
    dice[i] = diceFrame:CreateFontString(nil, "OVERLAY")
    dice[i]:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
    dice[i]:SetPoint("CENTER")
    dice[i]:SetText("-")
    
    selected[i] = false

    -- Modification du texte du bouton lors de la sélection d'un dé
    diceFrame:SetScript("OnMouseDown", function()
        if isFirstRoll or isFinished then return end -- Empêche la sélection des dés si isFirstRoll est true
		rollButton:Enable()
        selected[i] = not selected[i]
        if selected[i] then
            dice[i]:SetTextColor(1, 0, 0) -- Change la couleur en rouge si sélectionné
            rollButton:SetText(L["Reroll the dice"])
        else
            dice[i]:SetTextColor(1, 1, 1) -- Change la couleur en blanc si non sélectionné
            -- Vérifie si au moins un autre dé est sélectionné
            local anotherSelected = false
            for j = 1, 5 do
                if j ~= i and selected[j] then
                    anotherSelected = true
                    break
                end
            end
            -- Si aucun autre dé n'est sélectionné, changez le texte du bouton
            if not anotherSelected then
                rollButton:SetText(L["Roll the dice"])
            end
        end
    end)
end

rollButton:SetScript("OnClick", function()
    -- Vérifie si au moins un dé est sélectionné
    local anySelected = false
    for i = 1, 5 do
        if selected[i] then
            anySelected = true
            break
        end
    end
	
	if isFirstRoll then
	-- si c'est le premier lancer de la manche, on lance tous les dés
        for i = 1, 5 do
            dice[i]:SetText(math.random(1, 6))
            selected[i] = false
            dice[i]:SetTextColor(1, 1, 1) -- Change la couleur en blanc
        end
        isFirstRoll = false
		rollButton:SetText(L["Selection"])
		rollButton:Disable()
	elseif isFirstRoll == false and anySelected == false then
		rollButton:Disable() -- Désactive le bouton
    else
        -- Sinon, relancez seulement les dés sélectionnés
        for i = 1, 5 do
            if selected[i] then
                dice[i]:SetText(math.random(1, 6))
                selected[i] = false
                dice[i]:SetTextColor(1, 1, 1) -- Change la couleur en blanc
            end
        end
		rollButton:SetText(L["Finished"])
		rollButton:Disable()
		isFinished = true
    end
	
	PlaySound(36627)

	local results = {}
    for i = 1, 5 do
        table.insert(results, tonumber(dice[i]:GetText()))
    end
    table.sort(results, function(a, b) return a > b end)
    local resultString = table.concat(results, ", ")
    -- Envoie un message différent en fonction de si les dés ont été lancés ou relancés
    if isFirstRoll then
        SendChatMessage(L["Rerolls the dice and get "] .. resultString, "EMOTE")
    else
        SendChatMessage(L["Rolls the dice and get "] .. resultString, "EMOTE")
    end
end)




------------------------
--  COMMANDE SYSTEME  --
------------------------

-- Commande pour afficher la fenêtre
SLASH_POKER1 = "/poker"
SlashCmdList["POKER"] = function(msg)
    PokerdiceFrame:Show()
end

--------------------
-- FENETRE "PLUS" --
--------------------

-- Création de la fenêtre des règles et des Plus
local PlusFrame = CreateFrame("Frame", "PlusFrame", PokerdiceFrame, "BasicFrameTemplate")
PlusFrame:SetSize(400, 470) 
PlusFrame:SetPoint("LEFT", PokerdiceFrame, "RIGHT") 
PlusFrame:Hide()

PlusFrame:EnableMouse(true)
PlusFrame:SetMovable(true)
PlusFrame:RegisterForDrag("LeftButton")
PlusFrame:SetScript("OnDragStart", function() PokerdiceFrame:StartMoving() end)
PlusFrame:SetScript("OnDragStop", function() PokerdiceFrame:StopMovingOrSizing() end)

local PlusText = PlusFrame:CreateFontString(nil, "OVERLAY")
PlusText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
PlusText:SetPoint("LEFT", PlusFrame, "LEFT", 5, 120)
PlusText:SetJustifyH("LEFT")
PlusText:SetJustifyV("TOP")
local rulesText = L["RuleTextLib"]
PlusText:SetText(rulesText)


-- Création du bouton plus
local PlusButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
PlusButton:SetPoint("TOP", rollButton, "TOP", 42, 394)
PlusButton:SetSize(100, 25)
PlusButton:SetText(L["Plus"])
PlusButton:SetNormalFontObject("GameFontNormalSmall")
PlusButton:SetHighlightFontObject("GameFontHighlightSmall")
PlusButton:SetScript("OnClick", function()
    if PlusFrame:IsShown() then
        PlusFrame:Hide()
    else
        PlusFrame:Show()
    end
end)

------------------------
-- GESTION DES PIECES --
------------------------

-- Création du cadre pour les pièces d'or
local goldFrame = CreateFrame("Frame", nil, PokerdiceFrame)
goldFrame:SetSize(80, 80)
goldFrame:SetPoint("RIGHT", PokerdiceFrame, "LEFT", -2, -195)

-- Ajout de l'icône en fond
local background = goldFrame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetTexture("Interface\\Icons\\inv_misc_bag_10")

local goldText = goldFrame:CreateFontString(nil, "OVERLAY")
goldText:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
goldText:SetPoint("CENTER")
goldText:SetText(charGold) -- Initialisé à 6 par défaut

-- Création des boutons pour augmenter et diminuer le nombre de pièces d'or
local increaseButton = CreateFrame("Button", nil, goldFrame)
increaseButton:SetSize(35, 35)
increaseButton:SetPoint("LEFT", goldFrame, "RIGHT", -40, 55)
increaseButton:SetNormalTexture("Interface\\Icons\\misc_arrowlup")

local decreaseButton = CreateFrame("Button", nil, goldFrame)
decreaseButton:SetSize(35, 35)
decreaseButton:SetPoint("LEFT", goldFrame, "LEFT", 5, 55)
decreaseButton:SetNormalTexture("Interface\\Icons\\misc_arrowdown")


------------------------
-- AFFICHAGE DU POT   --
------------------------

-- Création du cadre pour le pot
local potFrame = CreateFrame("Frame", nil, PokerdiceFrame)
potFrame:SetSize(110, 110)
potFrame:SetPoint("RIGHT", goldFrame, "RIGHT", 1, 125)

-- Ajout de l'icône en fond
local potBackground = potFrame:CreateTexture(nil, "BACKGROUND")
potBackground:SetAllPoints()
potBackground:SetTexture("Interface\\Icons\\inv_misc_bowl_01") -- Remplacez ceci par l'icône que vous voulez utiliser pour le pot

local potText = potFrame:CreateFontString(nil, "OVERLAY")
potText:SetFont("Fonts\\FRIZQT__.TTF", 40, "OUTLINE")
potText:SetPoint("CENTER")
potText:SetText("0") -- Initialisé à 0 par défaut

-- Création de la boîte de dialogue de confirmation de récupération du pot
local ConfirmTakeThePotFrame = CreateFrame("Frame", "ConfirmTakeThePotFrame", potFrame, "BasicFrameTemplate")
ConfirmTakeThePotFrame:SetSize(400, 100)
ConfirmTakeThePotFrame:SetPoint("CENTER", potFrame, "CENTER", 300, -10)
ConfirmTakeThePotFrame:Hide()
ConfirmTakeThePotFrame:SetFrameStrata("HIGH")

local ConfirmTakeThePotText = ConfirmTakeThePotFrame:CreateFontString(nil, "OVERLAY")
ConfirmTakeThePotText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ConfirmTakeThePotText:SetPoint("CENTER")
ConfirmTakeThePotText:SetText(L["Confirm take the pot?"])

local YesTakeThePotButton = CreateFrame("Button", nil, ConfirmTakeThePotFrame, "GameMenuButtonTemplate")
YesTakeThePotButton:SetPoint("BOTTOMLEFT", ConfirmTakeThePotFrame, "BOTTOM", 10, 10)
YesTakeThePotButton:SetSize(80, 25)
YesTakeThePotButton:SetText(L["Yes"])
YesTakeThePotButton:SetScript("OnClick", function()
    potText:SetText(0)
	local channel = IsInRaid() and "RAID" or "PARTY"
	C_ChatInfo.SendAddonMessage("PokerDice", "RESETPOT", channel)
	SendChatMessage(L["has taken the pot!"] .. globalPot .. L["coins"] .. "!", "EMOTE")
	charGold = charGold + globalPot
	goldText:SetText(charGold)
	charBid = 0
	isFirstRoll = true
	isFinished = false
	rollButton:Enable() -- Réactive le bouton
	rollButton:SetText(L["Roll the dice"])
	PlaySound(179341)
    ConfirmTakeThePotFrame:Hide()
end)

local NoTakeThePotButton = CreateFrame("Button", nil, ConfirmTakeThePotFrame, "GameMenuButtonTemplate")
NoTakeThePotButton:SetPoint("BOTTOMRIGHT", ConfirmTakeThePotFrame, "BOTTOM", -10, 10)
NoTakeThePotButton:SetSize(80, 25)
NoTakeThePotButton:SetText(L["No"])
NoTakeThePotButton:SetScript("OnClick", function()
    ConfirmTakeThePotFrame:Hide()
end)

-- Création du bouton de récupération du pot
local TakeThePotButton = CreateFrame("Button", nil, potFrame, "GameMenuButtonTemplate")
TakeThePotButton:SetPoint("TOP", rollButton, "TOP", -165, 200)
TakeThePotButton:SetSize(130, 30)
TakeThePotButton:SetText(L["take the pot"])
TakeThePotButton:SetNormalFontObject("GameFontNormalLarge")
TakeThePotButton:SetHighlightFontObject("GameFontHighlightLarge")
TakeThePotButton:SetScript("OnClick", function()
    if ConfirmTakeThePotFrame:IsShown() then
        ConfirmTakeThePotFrame:Hide()
    else
        ConfirmTakeThePotFrame:Show()
    end
end)

------------------------------
-- GESTION DES GOLD ET POT  --
------------------------------

-- Création d'une variable pour stocker le timer et le nombre de pièces déplacées vers le pot
local timer
local piecesMovedToPot = 0

-- Création d'une fonction pour afficher un texte en fondu
local function showFadeOutText(frame, text)
    local fadeOutText = frame:CreateFontString(nil, "OVERLAY")
    fadeOutText:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
    fadeOutText:SetPoint("TOP", potFrame, "TOP", 90, -30)
    fadeOutText:SetText(text)
    fadeOutText:SetTextColor(1, 1, 0)
    UIFrameFadeOut(fadeOutText, 2, 1, 0) -- Fait disparaître le texte en 2 secondes
end

-- Modification des boutons pour augmenter et diminuer le nombre de pièces d'or
increaseButton:SetScript("OnClick", function()
    local gold = tonumber(goldText:GetText())
    local pot = tonumber(potText:GetText())
    if gold > 0 then
        goldText:SetText(gold - 1)
        potText:SetText(pot + 1)
		globalPot = (pot + 1)
        piecesMovedToPot = piecesMovedToPot + 1
		charBid = charBid +1
		showFadeOutText(goldFrame, "+1")
		PlaySound(125355)
		charGold = tonumber(goldText:GetText())
		
		-- Annulation du timer précédent
		if timer then
			timer:Cancel()
		end
		
		-- Démarrage d'un nouveau timer
		timer = C_Timer.NewTimer(5, function()
			if piecesMovedToPot > 0 then
				SendChatMessage(L["add "] .. piecesMovedToPot .. L[" coin(s) to the pot"], "EMOTE")
				local channel = IsInRaid() and "RAID" or "PARTY"
				C_ChatInfo.SendAddonMessage("PokerDice", "ADD " .. piecesMovedToPot, channel)
			elseif piecesMovedToPot < 0 then
				SendChatMessage(L["remove "] .. math.abs(piecesMovedToPot) .. L[" coin(s) from the pot"], "EMOTE")
				local channel = IsInRaid() and "RAID" or "PARTY"
				C_ChatInfo.SendAddonMessage("PokerDice", "REMOVE " .. math.abs(piecesMovedToPot), channel)
				
			end
			piecesMovedToPot = 0
		end)
    end
end)

decreaseButton:SetScript("OnClick", function()
    local gold = tonumber(goldText:GetText())
    local pot = tonumber(potText:GetText())
    if pot > 0 then
        goldText:SetText(gold + 1)
        potText:SetText(pot - 1)
		globalPot = (pot - 1)
        piecesMovedToPot = piecesMovedToPot - 1
		charBid = charBid -1
		showFadeOutText(goldFrame, "-1")
		PlaySound(125355)
		charGold = tonumber(goldText:GetText())
		
		-- Annulation du timer précédent
		if timer then
			timer:Cancel()
		end
		
		-- Démarrage d'un nouveau timer
		timer = C_Timer.NewTimer(5, function()
			if piecesMovedToPot > 0 then
				SendChatMessage(L["add "] .. piecesMovedToPot .. L[" coin(s) to the pot"], "EMOTE")
				local channel = IsInRaid() and "RAID" or "PARTY"
				C_ChatInfo.SendAddonMessage("PokerDice", "ADD " .. piecesMovedToPot, channel)
			elseif piecesMovedToPot < 0 then
				SendChatMessage(L["remove "] .. math.abs(piecesMovedToPot) .. L[" coin(s) from the pot"], "EMOTE")
				local channel = IsInRaid() and "RAID" or "PARTY"
				C_ChatInfo.SendAddonMessage("PokerDice", "REMOVE " .. math.abs(piecesMovedToPot), channel)
			end
			piecesMovedToPot = 0
		end)
    end
end)

------------------------
-- BOUTONS OPTIONNELS --
------------------------

-- Création de la boîte de dialogue de confirmation de reset du pot
local ConfirmResetFrame = CreateFrame("Frame", "ConfirmResetFrame", PlusFrame, "BasicFrameTemplate")
ConfirmResetFrame:SetSize(400, 100)
ConfirmResetFrame:SetPoint("CENTER", PlusFrame, "CENTER", 100, 10)
ConfirmResetFrame:Hide()

local ConfirmText = ConfirmResetFrame:CreateFontString(nil, "OVERLAY")
ConfirmText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ConfirmText:SetPoint("CENTER")
ConfirmText:SetText(L["Confirm reset the pot?"])

local YesResetButton = CreateFrame("Button", nil, ConfirmResetFrame, "GameMenuButtonTemplate")
YesResetButton:SetPoint("BOTTOMLEFT", ConfirmResetFrame, "BOTTOM", 10, 10)
YesResetButton:SetSize(80, 25)
YesResetButton:SetText(L["Yes"])
YesResetButton:SetScript("OnClick", function()
    potText:SetText(0)
	local channel = IsInRaid() and "RAID" or "PARTY"
	C_ChatInfo.SendAddonMessage("PokerDice", "RESETPOT", channel)
	SendChatMessage(L["has reset the pot to zero"], "EMOTE")
	globalPot = 0
	charBid = 0
	isFirstRoll = true
	isFinished = false
	rollButton:Enable() -- Réactive le bouton
	rollButton:SetText(L["Roll the dice"])
    ConfirmResetFrame:Hide()
end)

local NoResetButton = CreateFrame("Button", nil, ConfirmResetFrame, "GameMenuButtonTemplate")
NoResetButton:SetPoint("BOTTOMRIGHT", ConfirmResetFrame, "BOTTOM", -10, 10)
NoResetButton:SetSize(80, 25)
NoResetButton:SetText(L["No"])
NoResetButton:SetScript("OnClick", function()
    ConfirmResetFrame:Hide()
end)

-- Création du bouton de reset du pot
local ResetButton = CreateFrame("Button", nil, PlusFrame, "GameMenuButtonTemplate")
ResetButton:SetPoint("BOTTOM", rollButton, "RIGHT", 100, 0)
ResetButton:SetSize(125, 25)
ResetButton:SetText(L["Reset the pot"])
ResetButton:SetNormalFontObject("GameFontNormalSmall")
ResetButton:SetHighlightFontObject("GameFontHighlightSmall")
ResetButton:SetScript("OnClick", function()
    ConfirmResetFrame:Show()
end)

-- Création de la boîte de dialogue de confirmation de gage

local ConfirmPenaltyFrame = CreateFrame("Frame", "ConfirmPenaltyFrame", PlusFrame, "BasicFrameTemplate")
ConfirmPenaltyFrame:SetSize(400, 120)
ConfirmPenaltyFrame:SetPoint("CENTER", PlusFrame, "CENTER", 100, -110)
ConfirmPenaltyFrame:Hide()

local ConfirmText = ConfirmPenaltyFrame:CreateFontString(nil, "OVERLAY")
ConfirmText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ConfirmText:SetPoint("CENTER")
ConfirmText:SetText(L["Do you really want a penalty for two coins?"])

local YesPenaltyButton = CreateFrame("Button", nil, ConfirmPenaltyFrame, "GameMenuButtonTemplate")
YesPenaltyButton:SetPoint("BOTTOMLEFT", ConfirmPenaltyFrame, "BOTTOM", 10, 10)
YesPenaltyButton:SetSize(80, 25)
YesPenaltyButton:SetText(L["Yes"])
YesPenaltyButton:SetScript("OnClick", function()
	SendChatMessage(L["has accepted a penalty for gaining two coins"], "EMOTE")
	local gold = tonumber(goldText:GetText())
	charPenalty = charPenalty +1
	goldText:SetText(gold + 2)
	charGold = charGold + 2
    ConfirmPenaltyFrame:Hide()
end)

local NoPenaltyButton = CreateFrame("Button", nil, ConfirmPenaltyFrame, "GameMenuButtonTemplate")
NoPenaltyButton:SetPoint("BOTTOMRIGHT", ConfirmPenaltyFrame, "BOTTOM", -10, 10)
NoPenaltyButton:SetSize(80, 25)
NoPenaltyButton:SetText(L["No"])
NoPenaltyButton:SetScript("OnClick", function()
    ConfirmPenaltyFrame:Hide()
end)

-- Création du bouton de prise de gage
local PenaltyButton = CreateFrame("Button", nil, PlusFrame, "GameMenuButtonTemplate")
PenaltyButton:SetPoint("BOTTOM", rollButton, "RIGHT", 300, 0)
PenaltyButton:SetSize(210, 25)
PenaltyButton:SetText(L["Take a penalty, gain two coins"])
PenaltyButton:SetNormalFontObject("GameFontNormalSmall")
PenaltyButton:SetHighlightFontObject("GameFontHighlightSmall")
PenaltyButton:SetScript("OnClick", function()
    ConfirmPenaltyFrame:Show()
end)

------------------------
-- TABLEAU DES SCORES --
------------------------
local players = {}

-- Création de la table d'affichage
local displayTable = PlusFrame:CreateFontString(nil, "OVERLAY")
displayTable:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
displayTable:SetPoint("TOP", PlusText, "BOTTOM", 0, -10)
displayTable:SetJustifyH("LEFT")
displayTable:SetJustifyV("TOP")
displayTable:SetText(L["Need to be in party"])

-- Mise à jour de la table d'affichage
local function updateDisplayTable()
    local displayText = ""
    for name, player in pairs(players) do
        displayText = displayText .. "|cFF52BE80" .. name .. "|r : " .. player.tableGold .. L["coins"] .. ", " .. player.tableBid .. L["bid"] .. ", " .. player.tablePenalty .. L["penalty"] .. "\n"
    end
    displayTable:SetText(displayText)
end


-- Mise à jour de la table des participants lors de la réception d'un message SYNC
local function onSyncMessage(name, gold, bid, penalty)
    players[name] = {tableGold = gold, tableBid = bid, tablePenalty = penalty}
    updateDisplayTable()
end

-- Fonction pour envoyer les informations
local playerName = UnitName("player") -- Obtient le nom du joueur
local function sendInfo()
    C_ChatInfo.SendAddonMessage("PokerDice", "SYNC " .. playerName .. " " .. charGold .. " " .. charBid .. " " .. charPenalty, channel)
end

-- Création du ticker
local ticker = C_Timer.NewTicker(4, sendInfo)

------------------------------
-- GESTIONNAIRE D'EVENEMENT --
------------------------------

-- Création d'un cadre pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- Enregistrement de l'événement "CHAT_MSG_ADDON"
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "PokerDice" then
        -- Ignore les messages envoyés par le joueur lui-même
        local playerName = UnitName("player") -- Obtient le nom du joueur
        local senderName = strsplit("-", sender) -- Sépare le nom de l'expéditeur du nom du royaume

		local action, amount = strsplit(" ", message)
		local sync, name, gold, bid, penalty = strsplit(" ", message)
        if action == "ADD" and senderName ~= playerName then
            local pot = tonumber(potText:GetText())
            potText:SetText(pot + tonumber(amount))
			showFadeOutText(goldFrame, "+" .. amount)
			PlaySound(125355)
			globalPot = (pot + tonumber(amount))
        elseif action == "REMOVE" and senderName ~= playerName then
            local pot = tonumber(potText:GetText())
            potText:SetText(pot - tonumber(amount))
			showFadeOutText(goldFrame, "-" .. amount)
			PlaySound(125355)
			globalPot = (pot - tonumber(amount))
		elseif action == "RESETPOT" then
			potText:SetText(0)
			globalPot = 0
			charBid = 0
			isFirstRoll = true
			isFinished = false
			rollButton:Enable() -- Réactive le bouton
			rollButton:SetText(L["Roll the dice"])
			PlaySound(125355)
        elseif sync == "SYNC" then
            onSyncMessage(name, tonumber(gold), tonumber(bid), tonumber(penalty))
        end
    end
end)



