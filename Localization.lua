local _, core = ...
core.Locales = {}

local L = core.Locales


L["frFR"] = {
		["PokerDice is loaded"] = " |cFF808080est chargé. Pour jouer, assurez-vous d'être en groupe ou en raid avec les autres joueurs et tapez la commande /poker ou utiliser le bouton de la minimap.",
        ["Open/Close minimap button"] = "|cFF7cfc00Clic-gauche|r |cFFFFFFFF: Ouvrir/Fermer PokerDice|r",
		["Roll the dice"] = "Lancer les dés",
		["Bet first!"] = "Misez d'abord !",
		["Bet"] = "Miser",
		["Reroll the dice"] = "Relancer ces dés",
		["Selection"] = "Selectionner",
		["Finished"] = "Terminé",
        ["Plus"] = "Plus >>",
		["Rolls the dice and get "] = "lance les dés et obtient ",
		["Rerolls the dice and get "] = "relance les dés et obtient ",
		["add "] = "ajoute ",
		["remove "] = "retire ",
		["Follow"] = "Suivre",
		["Fold"] = "Se coucher",
		["Keep all"] = "Garder tout",
		["StatusInRound"] = "En jeu",
		["StatusFollowed"] = "A suivi",
		["StatusFolded"] = "Couché",
		["StatusReady"] = "Prêt",
		["WaitingFor"] = "En attente de : ",
		["StatusDecision2"] = "Suivez ou couchez-vous",
		["StatusRoll2"] = "Sélectionnez vos dés à relancer, ou gardez tout",
		["wins the round with"] = " remporte la manche avec ",
		["Everyone folded, pot carries over"] = "Tout le monde s'est couché, le pot est conservé pour la manche suivante.",
		["HandFiveKind"] = "Poker",
		["HandFourKind"] = "Carré",
		["HandFullHouse"] = "Full House",
		["HandLargeStraight"] = "Grande suite",
		["HandSmallStraight"] = "Petite suite",
		["HandThreeKind"] = "Brelan",
		["HandTwoPair"] = "Double paire",
		["HandPair"] = "Paire",
		["HandHighCard"] = "Rien",
		["add a coin to the pot"] = "ajoute une pièce au pot",
		[" coin(s) to the pot"] = " pièce(s) au pot",
		[" coin(s) from the pot"] = " pièce(s) du pot",
		["Reset the pot"] = "Réinitialiser le pot",
		["has reset the game"] = " a réinitialisée la partie",
		["Confirm reset the pot?"] = [[Souhaitez-vous vraiment réinitialiser le pot ?
Il sera remis à zéro pour tous les joueurs du groupe !]],
		["Confirm reset the game?"] = [[Souhaitez-vous vraiment réinitialiser la partie ?
Le pot, les pièces et les mises seront réinitialisés pour tous les joueurs du groupe !]],
		["has reset the pot to zero"] = " a réinitialisé le pot à zéro",
		["Reset the game"] = "Réinitialiser la partie",
		["Take a penalty, gain two coins"] = "Prenez un gage, gagnez deux pièces",
		["Do you really want a penalty for two coins?"] = [[Voulez-vous vraiment prendre un gage pour gagner deux 
pièces ? Assurez-vous que votre gage convienne aux
autres joueurs !]],
		["has accepted a penalty for gaining two coins"] = "a accepté un gage pour gagner deux pièces",
		["Yes"] = "Oui",
		["No"] = "Non",
		["coin(s)"] = " pièce(s) ",
		["penalty"] = " gage(s)",
		["bid"] = " pièce(s) misées",
		["Need to be in party"] = " |cFFFC3232Vous devez être en groupe pour jouer à PokerDice !",
		["RuleTextLib"] = [[




Bienvenue sur PokerDice !

Cet add-on nécessite que les joueurs soient en groupe pour
fonctionner correctement.

Déroulé d'une manche :
- Misez pour rejoindre la manche, puis lancez vos 5 dés.
- Suivez (nouvelle mise) pour continuer, ou couchez-vous
  pour abandonner (votre mise reste dans le pot).
- Relancez les dés de votre choix, ou gardez-les tous :
  dans les deux cas cela valide votre tirage final.
- Les tirages restent cachés tant que tous les joueurs
  encore en lice n'ont pas validé. Le résultat est alors
  révélé pour tout le monde en même temps et le pot est
  attribué automatiquement au vainqueur.

Liste des combinaisons par ordre de valeur :

- |cFFdaa520Poker|r : Cinq dés de même valeur
- |cFFdaa520Carré|r : Quatre dés de même valeur
- |cFFdaa520Full|r : Un brelan + une paire
- |cFFdaa520Grande suite|r : Suite de 5 dés
- |cFFdaa520Petite suite|r : Suite de 4 dés
- |cFFdaa520Brelan|r : Trois dés de même valeur
- |cFFdaa520Double paire|r : Deux paires
- |cFFdaa520Paire|r : Deux dés de même valeur

Quand les combinaisons sont de valeur identique, celle qui
comporte les dés les plus hauts est déclarée gagnante !
En cas d'égalité parfaite, le pot est partagé également
entre les gagnants.

Si tous les joueurs se couchent après le premier lancer,
personne ne gagne : le pot est conservé pour la manche
suivante.]]
    }
	
L["enUS"] = {
		["PokerDice is loaded"] = " |cFF808080is loaded. For playing, you need to be in the same party or raid as the other players, and type /poker or use the minimap button for opening the interface.",
        ["Open/Close minimap button"] = "|cFF7cfc00Left-click|r |cFFFFFFFF: Open/Close PokerDice|r",
		["Roll the dice"] = "Roll the dice",
		["Bet first!"] = "Bet first!",
		["Bet"] = "Bet",
		["Reroll the dice"] = "Reroll the dice",
		["Selection"] = "Select dice",
		["Finished"] = "Finished",
        ["Plus"] = "Plus >>",
		["Rolls the dice and get "] = "rolls the dice and get ",
		["Rerolls the dice and get "] = "rerolls the dice and get ",
		["Follow"] = "Follow",
		["Fold"] = "Fold",
		["Keep all"] = "Keep all",
		["StatusInRound"] = "In round",
		["StatusFollowed"] = "Followed",
		["StatusFolded"] = "Folded",
		["StatusReady"] = "Ready",
		["WaitingFor"] = "Waiting for: ",
		["StatusDecision2"] = "Follow or fold",
		["StatusRoll2"] = "Select dice to reroll, or keep all",
		["wins the round with"] = " wins the round with ",
		["Everyone folded, pot carries over"] = "Everyone folded, the pot carries over to the next round.",
		["HandFiveKind"] = "Poker",
		["HandFourKind"] = "4-of-a-Kind",
		["HandFullHouse"] = "Full House",
		["HandLargeStraight"] = "Great Straight",
		["HandSmallStraight"] = "Small Straight",
		["HandThreeKind"] = "3-of-a-Kind",
		["HandTwoPair"] = "Double Pair",
		["HandPair"] = "Pair",
		["HandHighCard"] = "Nothing",
		["add "] = "add ",
		["add a coin to the pot"] = "add a coin to the pot",
		["remove "] = "remove ",
		[" coin(s) to the pot"] = " coin(s) to the pot",
		[" coin(s) from the pot"] = " coin(s) from the pot",
		["Reset the pot"] = "Reset the pot",
		["Confirm reset the pot?"] = [[Do you really want to reset the pot?
The pot will be reset to zero for all players in the group!]],
		["Confirm reset the game?"] = [[Do you really want to reset the entire game?
The pot, coins and bids will be reset for all players in the group!]],
		["has reset the pot to zero"] = " has reset the pot to zero",
		["Reset the game"] = "Reset the game",
		["has reset the game"] = " has reset the game",
		["Take a penalty, gain two coins"] = "Take a penalty, gain two coins",
		["Do you really want a penalty for two coins?"] = [[Do you really want to take a penalty and gain two 
coins? Be sure your penalty is accepted by the
other players!]],
		["has accepted a penalty for gaining two coins"] = "has accepted a penalty for gaining two coins",
		["Yes"] = "Yes",
		["No"] = "No",
		["coin(s)"] = " coin(s) ",
		["penalty"] = " penalty",
		["bid"] = " coin(s) bet",
		["Need to be in party"] = "|cFFFC3232You need to be in party for playing PokerDice!",
		["RuleTextLib"] = [[




Welcome to PokerDice!

This add-on need the players to join the same party
or raid to work properly.

Round flow:
- Bet to join the round, then roll your 5 dice.
- Follow (bet again) to continue, or fold to drop out
  (your bet stays in the pot).
- Reroll the dice you want, or keep them all: either
  way, this locks in your final roll.
- Rolls stay hidden until every player still in the
  round has locked in. Results are then revealed for
  everyone at the same time and the pot is awarded to
  the winner automatically.

List of combinations in order of value:

- |cFFdaa520Poker|r: Five dice of the same value
- |cFFdaa5204-of-a-Kind|r: Four dice of the same value
- |cFFdaa520Full House|r: A three-of-a-kind + a pair
- |cFFdaa520Great Straight|r: Dice sequence of 5 dices
- |cFFdaa520Small Straight|r: Dice sequence of 4 dices
- |cFFdaa5203-of-a-Kind|r: Three dice of the same value
- |cFFdaa520Double Pair|r: Two pairs
- |cFFdaa520Pair|r: Two dice of the same value

When the combinations are of equal value, the one that
has the highest dice is declared the winner!
In case of a perfect tie, the pot is split evenly
between the winners.

If every player folds after the first roll, no one
wins: the pot carries over to the next round.]]
    }
    -- Ajoutez d'autres langues ici...

