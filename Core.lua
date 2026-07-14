-- Gestion de la localisation
local _, core = ...
local L = core.Locales[GetLocale()] or core.Locales["enUS"]
local Hands = core.Hands
local version = C_AddOns.GetAddOnMetadata("PokerDice", "Version")
local playerName = UnitName("player") -- identité réseau fixe, ne jamais réassigner

---------------------------
--   MACHINE A ETATS     --
---------------------------
local Phase = {
    ANTE = "ANTE",                   -- en attente de la mise initiale
    ROLL1_READY = "ROLL1_READY",     -- a misé, peut lancer les 5 dés
    DECISION2 = "DECISION2",         -- doit suivre ou se coucher
    ROLL2 = "ROLL2",                 -- peut relancer une sélection ou tout garder
    SHOWDOWN_WAIT = "SHOWDOWN_WAIT", -- a validé, attend les autres joueurs
    RESULTS = "RESULTS",             -- résultats affichés
}

local state = {
    phase = Phase.ANTE,
    gold = 6,
    penalty = 0,
    pot = 0,
    bid = 0,                         -- pièces misées par le joueur local cette manche (pour le scoreboard)
    dice = {0, 0, 0, 0, 0},
    selected = {false, false, false, false, false},
    roundPlayers = {},               -- [name] = { status = "active"|"followed"|"folded"|"locked", dice = {...} }
    resolved = false,                -- garde anti double-résolution de la manche
}

-- Widgets référencés par plusieurs fonctions
local PokerdiceFrame, rollButton, bidButton, foldButton, lockButton, statusText
local dice = {}
local goldFrame, goldText, potFrame, potText
local displayTable
local players = {} -- scoreboard persistant (or/mise/gage), peuplé par les messages SYNC

-- Fonctions déclarées ici pour permettre les références croisées avant leur définition
local refreshUI, clearRoundState, resetRound, lockHand
local tryResolveShowdown, onResult, onNoWinner, onPeerJoin
local getMissingPlayers, allActivePlayersLocked, allEnteredPlayersRolled
local updateRollButtonForSelection, anySelected, describeDice
local updateDisplayTable, onSyncMessage, showFadeOutText, sendInfo

----------------------------
--   BOUTON DE MINIMAP    --
----------------------------
local function CreateMinimapButton()
    local ldb = LibStub("LibDataBroker-1.1")
    local minimapButton = ldb:NewDataObject('PokerDiceMinimapIcon', {
        type = "launcher",
        icon = 1669494,
        OnClick = function(_, button)
            if button == "LeftButton" then
                if PokerdiceFrame:IsVisible() then
                    PokerdiceFrame:Hide()
                else
                    PokerdiceFrame:Show()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("PokerDice                                    " .. version)
            tooltip:AddLine(" ")
            tooltip:AddLine(L["Open/Close minimap button"])
        end,
    })
    local minimapIcon = LibStub("LibDBIcon-1.0")
    minimapIcon:Register('PokerDiceMinimapIcon', minimapButton, PokerDiceDb)
end

local minimapEventFrame = CreateFrame("Frame")
minimapEventFrame:RegisterEvent("VARIABLES_LOADED")
minimapEventFrame:SetScript("OnEvent", function()
    if type(PokerDiceDb) ~= "table" then
        PokerDiceDb = {}
    end
    if type(PokerDiceDb.minimapIcon) ~= "table" then
        PokerDiceDb.minimapIcon = {}
    end
    CreateMinimapButton()
end)

-- Enregistrement du préfixe de l'addon
C_ChatInfo.RegisterAddonMessagePrefix("PokerDice")

----------------------------
--   MESSAGE D'ACCUEIL    --
----------------------------
local loginEventFrame = CreateFrame("Frame")
loginEventFrame:RegisterEvent("PLAYER_LOGIN")
loginEventFrame:SetScript("OnEvent", function()
    print("|cFFdaa520PokerDice " .. version .. L["PokerDice is loaded"])
end)

----------------------------
--  INTERFACE PRINCIPALE  --
----------------------------

-- Création de la fenêtre principale
PokerdiceFrame = CreateFrame("Frame", "PokerdiceFrame", UIParent, "ButtonFrameTemplate")
PokerdiceFrame:SetPortraitToAsset("Interface\\ICONS\\misc_rune_pvp_random")
ButtonFrameTemplate_HideButtonBar(PokerdiceFrame)
PokerdiceFrame:SetSize(200, 550)
PokerdiceFrame:SetPoint("LEFT", UIParent, "LEFT", 200, 0)
PokerdiceFrame:SetTitle("PokerDice")
PokerdiceFrame:EnableMouse(true)
PokerdiceFrame:SetMovable(true)
PokerdiceFrame:RegisterForDrag("LeftButton")
PokerdiceFrame:SetScript("OnDragStart", PokerdiceFrame.StartMoving)
PokerdiceFrame:SetScript("OnDragStop", PokerdiceFrame.StopMovingOrSizing)
PokerdiceFrame:SetFrameStrata("BACKGROUND")
PokerdiceFrame:Hide()

-- Bouton plus (règles), casé en bas pour laisser la place au texte de statut en dessous
local PlusButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
PlusButton:SetPoint("TOP", PokerdiceFrame, "TOP", 44, -520)
PlusButton:SetSize(90, 22)
PlusButton:SetText(L["Plus"])
PlusButton:SetNormalFontObject("GameFontNormalSmall")
PlusButton:SetHighlightFontObject("GameFontHighlightSmall")

-- Texte de statut de la manche en cours
statusText = PokerdiceFrame:CreateFontString(nil, "OVERLAY")
statusText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
statusText:SetPoint("TOP", PokerdiceFrame, "TOP", 0, -38)
statusText:SetWidth(180)
statusText:SetJustifyH("CENTER")
statusText:SetJustifyV("TOP")
statusText:SetText("")

-- Création du bouton de roll (position fixe sous le bloc des dés)
rollButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
rollButton:SetPoint("TOP", PokerdiceFrame, "TOP", 0, -440)
rollButton:SetSize(150, 40)
rollButton:SetNormalFontObject("GameFontNormalLarge")
rollButton:SetHighlightFontObject("GameFontHighlightLarge")
rollButton:SetText(L["Bet first!"])
rollButton:Disable()

-- Bouton pour garder tous ses dés au second lancer (valide sans relancer)
lockButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
lockButton:SetPoint("TOP", rollButton, "BOTTOM", 0, -8)
lockButton:SetSize(150, 30)
lockButton:SetText(L["Keep all"])
lockButton:SetNormalFontObject("GameFontNormal")
lockButton:SetHighlightFontObject("GameFontHighlight")
lockButton:Hide()

-- Création des dés
for i = 1, 5 do
    local diceFrame = CreateFrame("Frame", nil, PokerdiceFrame, "InsetFrameTemplate2")
    diceFrame:SetSize(60, 60)
    diceFrame:SetPoint("TOP", PokerdiceFrame, "TOP", 0, -90 - 70 * (i - 1))
    local background = diceFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetTexture("Interface\\Icons\\6or_garrison_blackiron")

    dice[i] = diceFrame:CreateFontString(nil, "OVERLAY")
    dice[i]:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
    dice[i]:SetPoint("CENTER")
    dice[i]:SetText("-")

    diceFrame:SetScript("OnMouseDown", function()
        if state.phase ~= Phase.ROLL2 then return end
        state.selected[i] = not state.selected[i]
        if state.selected[i] then
            dice[i]:SetTextColor(1, 0, 0)
        else
            dice[i]:SetTextColor(1, 1, 1)
        end
        updateRollButtonForSelection()
    end)
end

------------------------
--   COMMANDE SYSTEME  --
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
local PlusFrame = CreateFrame("Frame", "PlusFrame", PokerdiceFrame, "ButtonFrameTemplate")
ButtonFrameTemplate_HideButtonBar(PlusFrame)
ButtonFrameTemplate_HidePortrait(PlusFrame)
PlusFrame.Inset:Hide()
PlusFrame:SetFrameStrata("BACKGROUND")
PlusFrame:SetSize(400, 550)
PlusFrame:SetPoint("LEFT", PokerdiceFrame, "RIGHT", 0, 0)
PlusFrame:Hide()

PlusFrame:EnableMouse(true)
PlusFrame:SetMovable(true)
PlusFrame:RegisterForDrag("LeftButton")
PlusFrame:SetScript("OnDragStart", function() PokerdiceFrame:StartMoving() end)
PlusFrame:SetScript("OnDragStop", function() PokerdiceFrame:StopMovingOrSizing() end)

local PlusText = PlusFrame:CreateFontString(nil, "OVERLAY")
PlusText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
PlusText:SetPoint("LEFT", PlusFrame, "LEFT", 15, 60)
PlusText:SetWidth(370)
PlusText:SetJustifyH("LEFT")
PlusText:SetJustifyV("TOP")
PlusText:SetWordWrap(true)
PlusText:SetText(L["RuleTextLib"])

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
goldFrame = CreateFrame("Frame", nil, PokerdiceFrame)
goldFrame:SetSize(80, 80)
goldFrame:SetPoint("RIGHT", PokerdiceFrame, "LEFT", -2, -234)

local goldBackground = goldFrame:CreateTexture(nil, "BACKGROUND")
goldBackground:SetAllPoints()
goldBackground:SetTexture("Interface\\Icons\\inv_misc_bag_10")

goldText = goldFrame:CreateFontString(nil, "OVERLAY")
goldText:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
goldText:SetPoint("CENTER")
goldText:SetText(state.gold)

------------------------
-- AFFICHAGE DU POT   --
------------------------

-- Création du cadre pour le pot
potFrame = CreateFrame("Frame", nil, PokerdiceFrame)
potFrame:SetSize(110, 110)
potFrame:SetPoint("RIGHT", goldFrame, "RIGHT", 1, 125)

local potBackground = potFrame:CreateTexture(nil, "BACKGROUND")
potBackground:SetAllPoints()
potBackground:SetTexture("Interface\\Icons\\inv_misc_bowl_01")

potText = potFrame:CreateFontString(nil, "OVERLAY")
potText:SetFont("Fonts\\FRIZQT__.TTF", 40, "OUTLINE")
potText:SetPoint("CENTER")
potText:SetText(state.pot)

------------------------------
-- GESTION DES GOLD ET POT  --
------------------------------

-- Création d'une fonction pour afficher un texte en fondu
showFadeOutText = function(frame, text)
    local fadeOutText = frame:CreateFontString(nil, "OVERLAY")
    fadeOutText:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
    fadeOutText:SetPoint("TOP", potFrame, "TOP", 90, -30)
    fadeOutText:SetText(text)
    fadeOutText:SetTextColor(1, 1, 0)
    UIFrameFadeOut(fadeOutText, 2, 1, 0)
end

-- Bouton de mise : sert à la fois pour l'ante (ANTE) et pour suivre (FOLLOW)
bidButton = CreateFrame("Button", nil, goldFrame, "GameMenuButtonTemplate")
bidButton:SetSize(70, 30)
bidButton:SetPoint("LEFT", goldFrame, "RIGHT", -70, 56)
bidButton:SetText(L["Bet"])
bidButton:SetNormalFontObject("GameFontNormal")
bidButton:SetHighlightFontObject("GameFontHighlight")
bidButton:SetScript("OnClick", function()
    if state.gold <= 0 then return end
    if state.phase ~= Phase.ANTE and state.phase ~= Phase.DECISION2 then return end
    -- On ne peut suivre que lorsque tous les joueurs entrés dans la manche ont lancé leurs dés
    if state.phase == Phase.DECISION2 and not allEnteredPlayersRolled() then return end

    local channel = IsInRaid() and "RAID" or "PARTY"
    state.pot = state.pot + 1
    state.bid = state.bid + 1
    state.gold = state.gold - 1
    potText:SetText(state.pot)
    goldText:SetText(state.gold)
    showFadeOutText(goldFrame, "+1")
    PlaySound(125355)

    if state.phase == Phase.ANTE then
        state.roundPlayers[playerName] = {status = "active"}
        C_ChatInfo.SendAddonMessage("PokerDice", "ANTE", channel)
        SendChatMessage(L["add a coin to the pot"], "EMOTE")
        state.phase = Phase.ROLL1_READY
    else
        state.roundPlayers[playerName].status = "followed"
        C_ChatInfo.SendAddonMessage("PokerDice", "FOLLOW", channel)
        SendChatMessage(L["add a coin to the pot"], "EMOTE")
        state.phase = Phase.ROLL2
    end
    updateDisplayTable()
    refreshUI()
end)

-- Bouton pour se coucher lors de la seconde mise (côte à côte avec bidButton, même niveau,
-- vers la gauche pour ne pas empiéter sur la fenêtre principale à droite)
foldButton = CreateFrame("Button", nil, goldFrame, "GameMenuButtonTemplate")
foldButton:SetSize(80, 30)
foldButton:SetPoint("RIGHT", bidButton, "LEFT", 0, 0)
foldButton:SetText(L["Fold"])
foldButton:SetNormalFontObject("GameFontNormal")
foldButton:SetHighlightFontObject("GameFontHighlight")
foldButton:Hide()
foldButton:SetScript("OnClick", function()
    if state.phase ~= Phase.DECISION2 then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    state.roundPlayers[playerName] = {status = "folded"}
    C_ChatInfo.SendAddonMessage("PokerDice", "FOLD", channel)
    SendChatMessage(L["folds"], "EMOTE")
    state.phase = Phase.SHOWDOWN_WAIT
    updateDisplayTable()
    refreshUI()
    tryResolveShowdown()
end)

------------------------
-- BOUTONS OPTIONNELS --
------------------------

-- Création de la boîte de dialogue de confirmation de reset du pot
local ConfirmResetFrame = CreateFrame("Frame", "ConfirmResetFrame", PlusFrame, "ButtonFrameTemplate")
ButtonFrameTemplate_HideButtonBar(ConfirmResetFrame)
ButtonFrameTemplate_HidePortrait(ConfirmResetFrame)
ConfirmResetFrame.Inset:Hide()
ConfirmResetFrame:SetFrameStrata("LOW")
ConfirmResetFrame:SetSize(400, 100)
ConfirmResetFrame:SetPoint("CENTER", PlusFrame, "CENTER", 100, 10)
ConfirmResetFrame:Hide()

local ConfirmResetText = ConfirmResetFrame:CreateFontString(nil, "OVERLAY")
ConfirmResetText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ConfirmResetText:SetPoint("CENTER")
ConfirmResetText:SetText(L["Confirm reset the pot?"])

local YesResetButton = CreateFrame("Button", nil, ConfirmResetFrame, "GameMenuButtonTemplate")
YesResetButton:SetPoint("BOTTOMLEFT", ConfirmResetFrame, "BOTTOM", 10, 10)
YesResetButton:SetSize(80, 25)
YesResetButton:SetText(L["Yes"])
YesResetButton:SetScript("OnClick", function()
    local channel = IsInRaid() and "RAID" or "PARTY"
    local displayName = playerName
    local status, result = pcall(function() return AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
    if status then displayName = result end
    C_ChatInfo.SendAddonMessage("PokerDice", "RESETPOT@" .. displayName, channel)
    resetRound(false)
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
ResetButton:SetPoint("BOTTOM", rollButton, "RIGHT", 100, -50)
ResetButton:SetSize(125, 25)
ResetButton:SetText(L["Reset the pot"])
ResetButton:SetNormalFontObject("GameFontNormalSmall")
ResetButton:SetHighlightFontObject("GameFontHighlightSmall")
ResetButton:SetScript("OnClick", function()
    ConfirmResetFrame:Show()
end)

-- Création de la boîte de dialogue de confirmation de reset de la partie
local ConfirmResetGameFrame = CreateFrame("Frame", "ConfirmResetGameFrame", PlusFrame, "ButtonFrameTemplate")
ButtonFrameTemplate_HideButtonBar(ConfirmResetGameFrame)
ButtonFrameTemplate_HidePortrait(ConfirmResetGameFrame)
ConfirmResetGameFrame.Inset:Hide()
ConfirmResetGameFrame:SetFrameStrata("LOW")
ConfirmResetGameFrame:SetSize(600, 100)
ConfirmResetGameFrame:SetPoint("CENTER", PlusFrame, "CENTER", 150, 120)
ConfirmResetGameFrame:Hide()

local ConfirmResetGameText = ConfirmResetGameFrame:CreateFontString(nil, "OVERLAY")
ConfirmResetGameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ConfirmResetGameText:SetPoint("CENTER")
ConfirmResetGameText:SetText(L["Confirm reset the game?"])

local YesResetGameButton = CreateFrame("Button", nil, ConfirmResetGameFrame, "GameMenuButtonTemplate")
YesResetGameButton:SetPoint("BOTTOMLEFT", ConfirmResetGameFrame, "BOTTOM", 10, 10)
YesResetGameButton:SetSize(80, 25)
YesResetGameButton:SetText(L["Yes"])
YesResetGameButton:SetScript("OnClick", function()
    local channel = IsInRaid() and "RAID" or "PARTY"
    local displayName = playerName
    local status, result = pcall(function() return AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
    if status then displayName = result end
    C_ChatInfo.SendAddonMessage("PokerDice", "RESETGAME@" .. displayName, channel)
    resetRound(true)
    ConfirmResetGameFrame:Hide()
end)

local NoResetGameButton = CreateFrame("Button", nil, ConfirmResetGameFrame, "GameMenuButtonTemplate")
NoResetGameButton:SetPoint("BOTTOMRIGHT", ConfirmResetGameFrame, "BOTTOM", -10, 10)
NoResetGameButton:SetSize(80, 25)
NoResetGameButton:SetText(L["No"])
NoResetGameButton:SetScript("OnClick", function()
    ConfirmResetGameFrame:Hide()
end)

-- Création du bouton de reset de la partie
local ResetGameButton = CreateFrame("Button", nil, PlusFrame, "GameMenuButtonTemplate")
ResetGameButton:SetPoint("BOTTOM", rollButton, "RIGHT", 100, -80)
ResetGameButton:SetSize(125, 25)
ResetGameButton:SetText(L["Reset the game"])
ResetGameButton:SetNormalFontObject("GameFontNormalSmall")
ResetGameButton:SetHighlightFontObject("GameFontHighlightSmall")
ResetGameButton:SetScript("OnClick", function()
    ConfirmResetGameFrame:Show()
end)

-- Création de la boîte de dialogue de confirmation de gage
local ConfirmPenaltyFrame = CreateFrame("Frame", "ConfirmPenaltyFrame", PlusFrame, "ButtonFrameTemplate")
ButtonFrameTemplate_HideButtonBar(ConfirmPenaltyFrame)
ButtonFrameTemplate_HidePortrait(ConfirmPenaltyFrame)
ConfirmPenaltyFrame.Inset:Hide()
ConfirmPenaltyFrame:SetFrameStrata("LOW")
ConfirmPenaltyFrame:SetSize(400, 120)
ConfirmPenaltyFrame:SetPoint("CENTER", PlusFrame, "CENTER", 100, -110)
ConfirmPenaltyFrame:Hide()

local ConfirmPenaltyText = ConfirmPenaltyFrame:CreateFontString(nil, "OVERLAY")
ConfirmPenaltyText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ConfirmPenaltyText:SetPoint("CENTER")
ConfirmPenaltyText:SetText(L["Do you really want a penalty for two coins?"])

local YesPenaltyButton = CreateFrame("Button", nil, ConfirmPenaltyFrame, "GameMenuButtonTemplate")
YesPenaltyButton:SetPoint("BOTTOMLEFT", ConfirmPenaltyFrame, "BOTTOM", 10, 10)
YesPenaltyButton:SetSize(80, 25)
YesPenaltyButton:SetText(L["Yes"])
YesPenaltyButton:SetScript("OnClick", function()
    SendChatMessage(L["has accepted a penalty for gaining two coins"], "EMOTE")
    state.penalty = state.penalty + 1
    state.gold = state.gold + 2
    goldText:SetText(state.gold)
    PlaySound(125355)
    ConfirmPenaltyFrame:Hide()
    refreshUI() -- réactive Miser/Suivre si le joueur était à 0 pièce
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
PenaltyButton:SetPoint("BOTTOM", rollButton, "RIGHT", 300, -50)
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

-- Fenêtre flottante et déplaçable, indépendante de PokerdiceFrame/PlusFrame
local ScoreboardFrame = CreateFrame("Frame", "PokerDiceScoreboardFrame", UIParent, "ButtonFrameTemplate")
ButtonFrameTemplate_HideButtonBar(ScoreboardFrame)
ButtonFrameTemplate_HidePortrait(ScoreboardFrame)
ScoreboardFrame.Inset:Hide()
ScoreboardFrame:SetFrameStrata("HIGH")
ScoreboardFrame:SetToplevel(true)
ScoreboardFrame:SetSize(400, 300)
ScoreboardFrame:SetPoint("TOPLEFT", PokerdiceFrame, "TOPRIGHT", 10, 0)
ScoreboardFrame:SetTitle(L["Scoreboard"])
ScoreboardFrame:Hide()
ScoreboardFrame:EnableMouse(true)
ScoreboardFrame:SetMovable(true)
ScoreboardFrame:RegisterForDrag("LeftButton")
ScoreboardFrame:SetScript("OnDragStart", ScoreboardFrame.StartMoving)
ScoreboardFrame:SetScript("OnDragStop", ScoreboardFrame.StopMovingOrSizing)

-- Bouton pour ouvrir/fermer le tableau des scores, à côté du bouton Plus
local ScoreButton = CreateFrame("Button", nil, PokerdiceFrame, "GameMenuButtonTemplate")
ScoreButton:SetPoint("RIGHT", PlusButton, "LEFT", 0, 0)
ScoreButton:SetSize(90, 22)
ScoreButton:SetText(L["Scores"])
ScoreButton:SetNormalFontObject("GameFontNormalSmall")
ScoreButton:SetHighlightFontObject("GameFontHighlightSmall")
ScoreButton:SetScript("OnClick", function()
    if ScoreboardFrame:IsShown() then
        ScoreboardFrame:Hide()
    else
        ScoreboardFrame:Show()
        ScoreboardFrame:Raise()
    end
end)

-- Création de la table d'affichage
displayTable = ScoreboardFrame:CreateFontString(nil, "OVERLAY")
displayTable:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
displayTable:SetPoint("TOPLEFT", ScoreboardFrame, "TOPLEFT", 15, -30)
displayTable:SetWidth(390)
displayTable:SetJustifyH("LEFT")
displayTable:SetJustifyV("TOP")
displayTable:SetWordWrap(true)
displayTable:SetText(L["Need to be in party"])

local statusLabels = {
    active = L["StatusInRound"],
    rolled = L["StatusRolled"],
    followed = L["StatusFollowed"],
    folded = L["StatusFolded"],
    locked = L["StatusReady"],
}

-- Mise à jour de la table d'affichage (or/mise/gage persistants + statut de manche en cours)
updateDisplayTable = function()
    local displayText = ""
    for name, player in pairs(players) do
        local roundInfo = state.roundPlayers[name]
        local statusStr = (roundInfo and statusLabels[roundInfo.status]) or "-"
        displayText = displayText .. "|cFF52BE80" .. name .. "|r : " .. player.tableGold .. L["coin(s)"] .. ", " .. player.tableBid .. L["bid"] .. ", " .. player.tablePenalty .. L["penalty"] .. " — " .. statusStr .. "\n"
    end
    displayTable:SetText(displayText)
end

-- Mise à jour de la table des participants lors de la réception d'un message SYNC
onSyncMessage = function(name, gold, bid, penalty)
    players[name] = {tableGold = gold, tableBid = bid, tablePenalty = penalty}
    updateDisplayTable()
end

-- Fonction pour envoyer les informations du scoreboard.
-- Utilise le vrai nom du personnage (playerName), pas le prénom RP : il doit
-- correspondre exactement aux clés de state.roundPlayers pour que le statut
-- de manche s'affiche correctement dans le tableau de scores.
sendInfo = function()
    -- SendAddonMessage ne renvoie jamais le message à son propre expéditeur :
    -- on met donc aussi à jour sa propre ligne directement en local.
    onSyncMessage(playerName, state.gold, state.bid, state.penalty)
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage("PokerDice", "SYNC@" .. playerName .. "@" .. state.gold .. "@" .. state.bid .. "@" .. state.penalty, channel)
end

-- Création du ticker (+ un premier appel immédiat pour ne pas attendre 4s avant de s'afficher soi-même)
local ticker = C_Timer.NewTicker(4, sendInfo)
sendInfo()

---------------------------
-- MACHINE A ETATS : UI  --
---------------------------

anySelected = function()
    for i = 1, 5 do
        if state.selected[i] then return true end
    end
    return false
end

updateRollButtonForSelection = function()
    if state.phase ~= Phase.ROLL2 then return end
    if anySelected() then
        rollButton:Enable()
        rollButton:SetText(L["Reroll the dice"])
    else
        rollButton:Disable()
        rollButton:SetText(L["Selection"])
    end
end

getMissingPlayers = function()
    local missing = {}
    for name, p in pairs(state.roundPlayers) do
        if p.status == "active" or p.status == "rolled" or p.status == "followed" then
            table.insert(missing, name)
        end
    end
    return missing
end

allActivePlayersLocked = function()
    return #getMissingPlayers() == 0
end

-- Vrai si tous les joueurs entrés dans la manche (ayant misé l'ante) ont lancé leurs
-- premiers dés. Le statut "active" signifie « a misé mais pas encore lancé » : tant
-- qu'un tel joueur subsiste, on ne peut pas suivre.
allEnteredPlayersRolled = function()
    for _, p in pairs(state.roundPlayers) do
        if p.status == "active" then return false end
    end
    return true
end

refreshUI = function()
    if state.phase == Phase.ANTE then
        rollButton:Show(); rollButton:Disable(); rollButton:SetText(L["Bet first!"])
        bidButton:Show(); bidButton:SetText(L["Bet"])
        if state.gold > 0 then bidButton:Enable() else bidButton:Disable() end
        foldButton:Hide()
        lockButton:Hide()
        statusText:SetText("")
    elseif state.phase == Phase.ROLL1_READY then
        rollButton:Show(); rollButton:Enable(); rollButton:SetText(L["Roll the dice"])
        bidButton:Hide()
        foldButton:Hide()
        lockButton:Hide()
        statusText:SetText("")
    elseif state.phase == Phase.DECISION2 then
        rollButton:Hide()
        bidButton:Show(); bidButton:SetText(L["Follow"])
        -- Suivre reste bloqué tant que tous les joueurs entrés n'ont pas lancé leurs dés (se coucher reste possible)
        if state.gold > 0 and allEnteredPlayersRolled() then bidButton:Enable() else bidButton:Disable() end
        foldButton:Show(); foldButton:Enable()
        lockButton:Hide()
        if allEnteredPlayersRolled() then
            statusText:SetText(L["StatusDecision2"])
        else
            statusText:SetText(L["WaitingForRolls"])
        end
    elseif state.phase == Phase.ROLL2 then
        rollButton:Show()
        bidButton:Hide()
        foldButton:Hide()
        lockButton:Show(); lockButton:Enable()
        statusText:SetText(L["StatusRoll2"])
        updateRollButtonForSelection()
    elseif state.phase == Phase.SHOWDOWN_WAIT then
        rollButton:Show(); rollButton:Disable(); rollButton:SetText(L["Finished"])
        bidButton:Hide()
        foldButton:Hide()
        lockButton:Hide()
        statusText:SetText(L["WaitingFor"] .. table.concat(getMissingPlayers(), ", "))
    elseif state.phase == Phase.RESULTS then
        rollButton:Hide()
        bidButton:Hide()
        foldButton:Hide()
        lockButton:Hide()
        -- statusText déjà renseigné par onResult/onNoWinner
    end
end

clearRoundState = function()
    state.phase = Phase.ANTE
    state.resolved = false
    state.bid = 0
    state.roundPlayers = {}
    state.selected = {false, false, false, false, false}
    state.dice = {0, 0, 0, 0, 0}
    for i = 1, 5 do
        dice[i]:SetText("-")
        dice[i]:SetTextColor(1, 1, 1)
    end
    updateDisplayTable()
    refreshUI()
end

resetRound = function(fullGameReset)
    clearRoundState()
    state.pot = 0
    potText:SetText(0)
    if fullGameReset then
        state.gold = 6
        state.penalty = 0
        goldText:SetText(6)
    end
end

lockHand = function(finalDiceValues)
    local diceCopy = {finalDiceValues[1], finalDiceValues[2], finalDiceValues[3], finalDiceValues[4], finalDiceValues[5]}
    state.roundPlayers[playerName] = {status = "locked", dice = diceCopy}
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage("PokerDice", "LOCK@" .. table.concat(diceCopy, ","), channel)
    state.phase = Phase.SHOWDOWN_WAIT
    updateDisplayTable()
    refreshUI()
    tryResolveShowdown()
end

lockButton:SetScript("OnClick", function()
    if state.phase ~= Phase.ROLL2 then return end
    lockHand(state.dice)
end)

---------------------------
-- RESOLUTION DE MANCHE  --
---------------------------

tryResolveShowdown = function()
    if state.resolved or not allActivePlayersLocked() then return end
    local locked = {}
    for name, p in pairs(state.roundPlayers) do
        if p.status == "locked" then
            table.insert(locked, {name = name, hand = Hands.Evaluate(p.dice)})
        end
    end
    local channel = IsInRaid() and "RAID" or "PARTY"
    if #locked == 0 then
        C_ChatInfo.SendAddonMessage("PokerDice", "NOWINNER", channel)
        onNoWinner()
        return
    end
    table.sort(locked, function(a, b) return Hands.Compare(a.hand, b.hand) > 0 end)
    local best = locked[1].hand
    local winners = {}
    for _, entry in ipairs(locked) do
        if Hands.Compare(entry.hand, best) == 0 then
            table.insert(winners, entry.name)
        end
    end
    local amountEach = math.floor(state.pot / #winners)
    local remainder = state.pot - amountEach * #winners
    C_ChatInfo.SendAddonMessage("PokerDice", "RESULT@" .. table.concat(winners, ",") .. "@" .. amountEach .. "@" .. best.handKey .. "@" .. remainder, channel)
    onResult(winners, amountEach, best.handKey, remainder)
end

onResult = function(winners, amountEach, handKey, remainder)
    if state.resolved then return end
    state.resolved = true
    local iWon = false
    for _, w in ipairs(winners) do
        if w == playerName then
            iWon = true
            state.gold = state.gold + amountEach
            goldText:SetText(state.gold)
        end
    end
    state.pot = remainder
    potText:SetText(remainder)
    statusText:SetText(table.concat(winners, ", ") .. L["wins the round with"] .. L[handKey])
    PlaySound(179341) -- son de pièces, joué par tout le monde quand le pot est distribué
    if iWon then
        -- diffusé en emote uniquement par le(s) gagnant(s), pour que tout le groupe le voie dans le chat
        SendChatMessage(L["wins the round with"] .. L[handKey] .. "!", "EMOTE")
    end
    state.phase = Phase.RESULTS
    refreshUI()
    C_Timer.After(4, clearRoundState)
end

onNoWinner = function()
    if state.resolved then return end
    state.resolved = true
    statusText:SetText(L["Everyone folded, pot carries over"])
    state.phase = Phase.RESULTS
    refreshUI()
    C_Timer.After(2, clearRoundState)
end

onPeerJoin = function(name, status)
    state.pot = state.pot + 1
    potText:SetText(state.pot)
    showFadeOutText(goldFrame, "+1")
    PlaySound(125355)
    state.roundPlayers[name] = {status = status}
    updateDisplayTable()
    refreshUI()
end

---------------------------
-- LANCEMENT DES DES ------
---------------------------

describeDice = function(diceValues)
    local sorted = {}
    for _, v in ipairs(diceValues) do table.insert(sorted, v) end
    table.sort(sorted, function(a, b) return a > b end)
    return table.concat(sorted, ", ")
end

rollButton:SetScript("OnClick", function()
    if state.phase == Phase.ROLL1_READY then
        for i = 1, 5 do
            local roll = math.random(1, 6)
            state.dice[i] = roll
            dice[i]:SetText(roll)
            dice[i]:SetTextColor(1, 1, 1)
        end
        PlaySound(36627)
        SendChatMessage(L["Rolls the dice and get "] .. describeDice(state.dice), "EMOTE")
        -- On signale aux autres qu'on a lancé nos premiers dés, pour débloquer le suivi
        state.roundPlayers[playerName].status = "rolled"
        local channel = IsInRaid() and "RAID" or "PARTY"
        C_ChatInfo.SendAddonMessage("PokerDice", "ROLL1", channel)
        state.phase = Phase.DECISION2
        updateDisplayTable()
        refreshUI()
    elseif state.phase == Phase.ROLL2 then
        if not anySelected() then return end
        for i = 1, 5 do
            if state.selected[i] then
                local roll = math.random(1, 6)
                state.dice[i] = roll
                dice[i]:SetText(roll)
                state.selected[i] = false
                dice[i]:SetTextColor(1, 1, 1)
            end
        end
        PlaySound(36627)
        SendChatMessage(L["Rerolls the dice and get "] .. describeDice(state.dice), "EMOTE")
        lockHand(state.dice)
    end
end)

------------------------------
-- GESTIONNAIRE D'EVENEMENT --
------------------------------

-- Création d'un cadre pour gérer les événements
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event ~= "CHAT_MSG_ADDON" or prefix ~= "PokerDice" then return end
    local senderName = strsplit("-", sender)
    local action, rest = strsplit("@", message, 2)

    if action == "SYNC" then
        local name, gold, bid, penalty = strsplit("@", rest)
        onSyncMessage(name, tonumber(gold), tonumber(bid), tonumber(penalty))
        return
    elseif action == "RESETPOT" or action == "RESETGAME" then
        resetRound(action == "RESETGAME")
        print("|cffffff00" .. rest .. (action == "RESETGAME" and L["has reset the game"] or L["has reset the pot to zero"]))
        return
    elseif action == "RESULT" then
        local winners, amountEach, handKey, remainder = strsplit("@", rest)
        onResult({strsplit(",", winners)}, tonumber(amountEach), handKey, tonumber(remainder))
        return
    elseif action == "NOWINNER" then
        onNoWinner()
        return
    end

    if senderName == playerName then return end -- actions de manche déjà appliquées au clic local

    if action == "ANTE" then
        onPeerJoin(senderName, "active")
    elseif action == "ROLL1" then
        if state.roundPlayers[senderName] then
            state.roundPlayers[senderName].status = "rolled"
        else
            state.roundPlayers[senderName] = {status = "rolled"}
        end
        updateDisplayTable()
        refreshUI()
    elseif action == "FOLLOW" then
        onPeerJoin(senderName, "followed")
    elseif action == "FOLD" then
        state.roundPlayers[senderName] = {status = "folded"}
        updateDisplayTable()
        refreshUI()
        tryResolveShowdown()
    elseif action == "LOCK" then
        local d1, d2, d3, d4, d5 = strsplit(",", rest)
        state.roundPlayers[senderName] = {status = "locked", dice = {tonumber(d1), tonumber(d2), tonumber(d3), tonumber(d4), tonumber(d5)}}
        updateDisplayTable()
        refreshUI()
        tryResolveShowdown()
    end
end)
