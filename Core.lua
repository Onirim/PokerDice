-- Gestion de la localisation
local _, core = ...
local L = core.Locales[GetLocale()] or core.Locales["enUS"]

-- Enregistrement du préfixe de l'addon
C_ChatInfo.RegisterAddonMessagePrefix("PokerDice")


-- Création de la fenêtre principale
local PokerdiceFrame = CreateFrame("Frame", "PokerdiceFrame", UIParent, "BasicFrameTemplateWithInset")
PokerdiceFrame:SetSize(200, 470) 
PokerdiceFrame:SetPoint("CENTER") 
PokerdiceFrame:EnableMouse(true)
PokerdiceFrame:SetMovable(true)
PokerdiceFrame:RegisterForDrag("LeftButton")
PokerdiceFrame:SetScript("OnDragStart", PokerdiceFrame.StartMoving)
PokerdiceFrame:SetScript("OnDragStop", PokerdiceFrame.StopMovingOrSizing)
PokerdiceFrame:Hide()

-- Création du titre
local title = PokerdiceFrame:CreateFontString(nil, "OVERLAY")
title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
title:SetPoint("TOP", PokerdiceFrame, "TOP", 0, -5)
title:SetText("PokerDice")

-- Ajoutez une variable pour suivre si une relance a déjà été effectuée
local isReroll = false

-- Création du bouton de roll
local rollButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
rollButton:SetPoint("TOP", PokerdiceFrame, "BOTTOM", 0, 30)
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
    
    dice[i] = diceFrame:CreateFontString(nil, "OVERLAY")
    dice[i]:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
    dice[i]:SetPoint("CENTER")
    dice[i]:SetText("-")
    
    selected[i] = false

    -- Modification du texte du bouton lors de la sélection d'un dé
    diceFrame:SetScript("OnMouseDown", function()
        if not isReroll then return end -- Empêche la sélection des dés si isReroll est false
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
	
	if isReroll == false or not anySelected then
        -- Si une relance a déjà été effectuée ou si aucun dé n'est sélectionné, lancez tous les dés
        for i = 1, 5 do
            dice[i]:SetText(math.random(1, 6))
            selected[i] = false
            dice[i]:SetTextColor(1, 1, 1) -- Change la couleur en blanc
        end
        if isReroll == false then 
			isReroll = true
		else 
			isReroll = false
		end
    else
        -- Sinon, relancez seulement les dés sélectionnés
        for i = 1, 5 do
            if selected[i] then
                dice[i]:SetText(math.random(1, 6))
                selected[i] = false
                dice[i]:SetTextColor(1, 1, 1) -- Change la couleur en blanc
            end
        end
		isReroll = false
		rollButton:SetText(L["Roll the dice"])
    end
	
	PlaySound(36627)

	local results = {}
    for i = 1, 5 do
        table.insert(results, tonumber(dice[i]:GetText()))
    end
    table.sort(results, function(a, b) return a > b end)
    local resultString = table.concat(results, ", ")
    -- Envoie un message différent en fonction de si les dés ont été lancés ou relancés
    if isReroll == false then
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

------------------------
-- FENETRE DES REGLES --
------------------------

-- Création de la fenêtre des règles et des combinaisons
local CombinaisonsFrame = CreateFrame("Frame", "CombinaisonsFrame", PokerdiceFrame, "BasicFrameTemplate")
CombinaisonsFrame:SetSize(400, 470) 
CombinaisonsFrame:SetPoint("LEFT", PokerdiceFrame, "RIGHT") 
CombinaisonsFrame:Hide()

CombinaisonsFrame:EnableMouse(true)
CombinaisonsFrame:SetMovable(true)
CombinaisonsFrame:RegisterForDrag("LeftButton")
CombinaisonsFrame:SetScript("OnDragStart", function() PokerdiceFrame:StartMoving() end)
CombinaisonsFrame:SetScript("OnDragStop", function() PokerdiceFrame:StopMovingOrSizing() end)

local combinaisonsText = CombinaisonsFrame:CreateFontString(nil, "OVERLAY")
combinaisonsText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
combinaisonsText:SetPoint("LEFT", CombinaisonsFrame, "TOP", -190, -240)
combinaisonsText:SetJustifyH("LEFT")
combinaisonsText:SetJustifyV("TOP")
local rulesText = L["RuleTextLib"]
combinaisonsText:SetText(rulesText)


-- Création du bouton des règles
local combinaisonsButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
combinaisonsButton:SetPoint("TOP", rollButton, "TOP", 42, 415)
combinaisonsButton:SetSize(100, 25)
combinaisonsButton:SetText(L["Rules"])
combinaisonsButton:SetNormalFontObject("GameFontNormalSmall")
combinaisonsButton:SetHighlightFontObject("GameFontHighlightSmall")
combinaisonsButton:SetScript("OnClick", function()
    if CombinaisonsFrame:IsShown() then
        CombinaisonsFrame:Hide()
    else
        CombinaisonsFrame:Show()
    end
end)

------------------------
-- GESTION DES PIECES --
------------------------

-- Création du cadre pour les pièces d'or
local goldFrame = CreateFrame("Frame", nil, PokerdiceFrame)
goldFrame:SetSize(80, 80)
goldFrame:SetPoint("RIGHT", PokerdiceFrame, "LEFT", 10, -195)

-- Ajout de l'icône en fond
local background = goldFrame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetTexture("Interface\\Icons\\inv_misc_bag_10")

local goldText = goldFrame:CreateFontString(nil, "OVERLAY")
goldText:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
goldText:SetPoint("CENTER")
goldText:SetText("6") -- Initialisé à 6 par défaut

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
potFrame:SetPoint("RIGHT", goldFrame, "RIGHT", 0, 125)

-- Ajout de l'icône en fond
local potBackground = potFrame:CreateTexture(nil, "BACKGROUND")
potBackground:SetAllPoints()
potBackground:SetTexture("Interface\\Icons\\inv_misc_bowl_01") -- Remplacez ceci par l'icône que vous voulez utiliser pour le pot

local potText = potFrame:CreateFontString(nil, "OVERLAY")
potText:SetFont("Fonts\\FRIZQT__.TTF", 40, "OUTLINE")
potText:SetPoint("CENTER")
potText:SetText("0") -- Initialisé à 0 par défaut

---------------------
-- GESTION DU POT  --
---------------------

-- Création d'une variable pour stocker le timer et le nombre de pièces déplacées vers le pot
local timer
local piecesMovedToPot = 0

-- Création d'une fonction pour afficher un texte en fondu
local function showFadeOutText(frame, text)
    local fadeOutText = frame:CreateFontString(nil, "OVERLAY")
    fadeOutText:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
    fadeOutText:SetPoint("TOP", potFrame, "TOP", 0, 25)
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
        piecesMovedToPot = piecesMovedToPot + 1
		showFadeOutText(goldFrame, "+1")
		PlaySound(125355)
		
		-- Annulation du timer précédent
		if timer then
			timer:Cancel()
		end
		
		-- Démarrage d'un nouveau timer
		timer = C_Timer.NewTimer(5, function()
			if piecesMovedToPot > 0 then
				SendChatMessage(L["add "] .. piecesMovedToPot .. L[" piece(s) to the pot"], "EMOTE")
				local channel = IsInRaid() and "RAID" or "PARTY"
				C_ChatInfo.SendAddonMessage("PokerDice", "ADD " .. piecesMovedToPot, channel)
			elseif piecesMovedToPot < 0 then
				SendChatMessage(L["remove "] .. math.abs(piecesMovedToPot) .. L[" piece(s) from the pot"], "EMOTE")
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
        piecesMovedToPot = piecesMovedToPot - 1
		showFadeOutText(goldFrame, "-1")
		PlaySound(125355)
		
		-- Annulation du timer précédent
		if timer then
			timer:Cancel()
		end
		
		-- Démarrage d'un nouveau timer
		timer = C_Timer.NewTimer(5, function()
			if piecesMovedToPot > 0 then
				SendChatMessage(L["add "] .. piecesMovedToPot .. L[" piece(s) to the pot"], "EMOTE")
				local channel = IsInRaid() and "RAID" or "PARTY"
				C_ChatInfo.SendAddonMessage("PokerDice", "ADD " .. piecesMovedToPot, channel)
			elseif piecesMovedToPot < 0 then
				SendChatMessage(L["remove "] .. math.abs(piecesMovedToPot) .. L[" piece(s) from the pot"], "EMOTE")
				local channel = IsInRaid() and "RAID" or "PARTY"
				C_ChatInfo.SendAddonMessage("PokerDice", "REMOVE " .. math.abs(piecesMovedToPot), channel)
			end
			piecesMovedToPot = 0
		end)
    end
end)

-- Création d'un cadre pour gérer les événements
local eventFrame = CreateFrame("Frame")

-- Enregistrement de l'événement "CHAT_MSG_ADDON"
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

-- Définition du gestionnaire d'événements
eventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "PokerDice" then
        -- Ignore les messages envoyés par le joueur lui-même
        local playerName = UnitName("player") -- Obtient le nom du joueur
        local senderName = strsplit("-", sender) -- Sépare le nom de l'expéditeur du nom du royaume
        if senderName == playerName then return end

        local action, amount = strsplit(" ", message)
        amount = tonumber(amount)
        if action == "ADD" then
            local pot = tonumber(potText:GetText())
            potText:SetText(pot + amount)
			showFadeOutText(goldFrame, "+" .. amount)
			PlaySound(125355)
        elseif action == "REMOVE" then
            local pot = tonumber(potText:GetText())
            potText:SetText(pot - amount)
			showFadeOutText(goldFrame, "-" .. amount)
			PlaySound(125355)
        end
    end
end)





