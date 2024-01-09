local _, core = ...
core.Locales = {}

local L = core.Locales


L["frFR"] = {
		["PokerDice is loaded"] = " |cFF808080est chargé. Pour jouer, assurez-vous d'être en groupe ou en raid avec les autres joueurs et tapez la commande /poker",
        ["Roll the dice"] = "Lancer les dés",
		["Reroll the dice"] = "Relancer ces dés",
		["Selection"] = "Selectionner",
		["Finished"] = "Terminé",
        ["Plus"] = "Plus >>",
		["Rolls the dice and get "] = "lance les dés et obtient ",
		["Rerolls the dice and get "] = "relance les dés et obtient ",
		["add "] = "ajoute ",
		["remove "] = "retire ",
		[" coin(s) to the pot"] = " pièce(s) au pot",
		[" coin(s) from the pot"] = " pièce(s) du pot",
		["Reset the pot"] = "Réinitialiser le pot",
		["Confirm reset the pot?"] = [[Souhaitez-vous vraiment réinitialiser le pot ?
Il sera remis à zéro pour tous les joueurs du groupe !]],
		["has reset the pot to zero"] = "a réinitialisé le pot à zéro",
		["Take a penalty, gain two coins"] = "Prenez un gage, gagnez deux pièces",
		["Do you really want a penalty for two coins?"] = [[Voulez-vous vraiment prendre un gage pour gagner deux 
pièces ? Assurez-vous que votre gage convienne aux
autres joueurs !]],
		["has accepted a penalty for gaining two coins"] = "a accepté un gage pour gagner deux pièces",
		["Yes"] = "Oui",
		["No"] = "Non",
		["coins"] = " pièce(s) ",
		["penalty"] = " gage(s)",
		["take the pot"] = "Gagner le pot",
		["has taken the pot!"] = "a gagné le pot et récupère ",
		["bid"] = " pièce(s) misées",
		["Confirm take the pot?"] = [[Vous êtes sur le point de prendre le contenu du pot !
Avez-vous gagné la manche ?]],
		["Need to be in party"] = " |cFFFC3232Vous devez être en groupe pour jouer à PokerDice !",
		["RuleTextLib"] = [[




Bienvenue sur PokerDice !

Cet add-on nécessite que les joueurs soient en groupe pour
fonctionner correctement.

Liste des combinaisons par ordre de valeur :

- |cFFdaa520Poker|r : Cinq dés de même valeur
- |cFFdaa520Carré|r : Quatre dés de même valeur
- |cFFdaa520Full|r : Un brelan + une paire
- |cFFdaa520Grande suite|r : Suite de dés allant de 2 à 6
- |cFFdaa520Petite suite|r : Suite de dés allant de 1 à 5
- |cFFdaa520Brelan|r : Trois dés de même valeur
- |cFFdaa520Double paire|r : Deux paires
- |cFFdaa520Paire|r : Deux dés de même valeur

Quand les combinaisons sont de valeur identique, celle qui
comporte les dés les plus hauts est déclarée gagnante !]]
    }
	
L["enUS"] = {
		["PokerDice is loaded"] = " |cFF808080is loaded. For playing, you need to be in the same party or raid as the other players, and type /poker for opening the interface.",
        ["Roll the dice"] = "Roll the dice",
		["Reroll the dice"] = "Reroll the dice",
		["Selection"] = "Select dice",
		["Finished"] = "Finished",
        ["Plus"] = "Plus >>",
		["Rolls the dice and get "] = "rolls the dice and get ",
		["Rerolls the dice and get "] = "rerolls the dice and get ",
		["add "] = "add ",
		["remove "] = "remove ",
		[" coin(s) to the pot"] = " coin(s) to the pot",
		[" coin(s) from the pot"] = " coin(s) from the pot",
		["Reset the pot"] = "Reset the pot",
		["Confirm reset the pot?"] = [[Do you really want to reset the pot?
The pot will be reset to zero for all players in the group!]],
		["has reset the pot to zero"] = "has reset the pot to zero",
		["Take a penalty, gain two coins"] = "Take a penalty, gain two coins",
		["Do you really want a penalty for two coins?"] = [[Do you really want to take a penalty and gain two 
coins? Be sure your penalty is accepted by the
other players!]],
		["has accepted a penalty for gaining two coins"] = "has accepted a penalty for gaining two coins",
		["Yes"] = "Yes",
		["No"] = "No",
		["coins"] = " coin(s) ",
		["penalty"] = " penalty",
		["take the pot"] = "Take the pot",
		["has taken the pot!"] = "has taken the pot and gains ",
		["bid"] = " coin(s) bet",
		["Confirm take the pot?"] = [[You are about to take the pot and gain all the coins!
Have you win the round?]],
		["Need to be in party"] = "|cFFFC3232You need to be in party for playing PokerDice!",
		["RuleTextLib"] = [[



Welcome to PokerDice!

This add-on need the players to join the same party
or raid to work properly.

List of combinations in order of value:

- |cFFdaa520Poker|r: Five dice of the same value
- |cFFdaa5204-of-a-Kind|r: Four dice of the same value
- |cFFdaa520Full House|r: A three-of-a-kind + a pair
- |cFFdaa520Great Straight|r: Dice sequence ranging from 2 to 6
- |cFFdaa520Small Straight|r: Dice sequence ranging from 1 to 5
- |cFFdaa5203-of-a-Kind|r: Three dice of the same value
- |cFFdaa520Double Pair|r: Two pairs
- |cFFdaa520Pair|r: Two dice of the same value

When the combinations are of equal value, the one that 
has the highest dice is declared the winner!]]
    }
    -- Ajoutez d'autres langues ici...
