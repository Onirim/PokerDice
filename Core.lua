-- Gestion de la localisation
local _, core = ...
local L = core.Locales[GetLocale()] or core.Locales["enUS"]


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
title:SetText("Poker dice")

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
    diceFrame:SetScript("OnMouseDown", function()
        selected[i] = not selected[i]
        if selected[i] then
            dice[i]:SetTextColor(1, 0, 0) -- Change la couleur en rouge si sélectionné
        else
            dice[i]:SetTextColor(1, 1, 1) -- Change la couleur en blanc si non sélectionné
        end
    end)
end

-- Création du bouton de roll
local rollButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
rollButton:SetPoint("TOP", PokerdiceFrame, "BOTTOM", 0, 30)
rollButton:SetSize(140, 40)
rollButton:SetText(L["Roll the dice"])
rollButton:SetNormalFontObject("GameFontNormalLarge")
rollButton:SetHighlightFontObject("GameFontHighlightLarge")
rollButton:SetScript("OnClick", function()
    -- Vérifie si au moins un dé est sélectionné
    local anySelected = false
    for i = 1, 5 do
        if selected[i] then
            anySelected = true
            break
        end
    end

    -- Lance les dés sélectionnés ou tous les dés si aucun n'est sélectionné
    for i = 1, 5 do
        if not anySelected or selected[i] then
            dice[i]:SetText(math.random(1, 6))
        end
    end
    PlaySound(36627) -- Joue un son

    -- Tri et affichage du résultat sous forme d'emote
    local results = {}
    for i = 1, 5 do
        table.insert(results, tonumber(dice[i]:GetText()))
    end
    table.sort(results, function(a, b) return a > b end)
    local resultString = table.concat(results, ", ")
    SendChatMessage(L["Rolls the dice and get "] .. resultString, "EMOTE")
end)

-- Commande pour afficher la fenêtre
SLASH_POKER1 = "/poker"
SlashCmdList["POKER"] = function(msg)
    PokerdiceFrame:Show()
end

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
local increaseButton = CreateFrame("Button", nil, goldFrame, "UIPanelButtonTemplate")
increaseButton:SetSize(20, 30)
increaseButton:SetPoint("LEFT", goldFrame, "RIGHT", -10, 25)
increaseButton:SetText("^")
increaseButton:SetScript("OnClick", function()
    local gold = tonumber(goldText:GetText())
    goldText:SetText(gold + 1)
	PlaySound(125355)
end)

local decreaseButton = CreateFrame("Button", nil, goldFrame, "UIPanelButtonTemplate")
decreaseButton:SetSize(20, 30)
decreaseButton:SetPoint("TOP", increaseButton, "BOTTOM", 0, -18)
decreaseButton:SetText("v")
decreaseButton:SetScript("OnClick", function()
    local gold = tonumber(goldText:GetText())
    if gold > 0 then
        goldText:SetText(gold - 1)
		PlaySound(125355)
    end
end)

