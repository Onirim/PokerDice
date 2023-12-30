local _, core = ...
core.Locales = {}

local L = core.Locales


L["frFR"] = {
        ["Roll the dice"] = "Lancer les dés",
		["Reroll the dice"] = "Relancer ces dés",
        ["Rules"] = "Règles >>",
		["Rolls the dice and get "] = "lance les dés et obtient ",
		["Rerolls the dice and get "] = "relance les dés et obtient ",
		["RuleTextLib"] = [[Il s'agit d'un jeu de Poker aux dés pour deux joueurs et plus.
L'objectif est de réaliser la meilleure combinaison en deux
lancers de dés. Le premier joueur est celui celui qui 
a gagné le tour précédent. Une partie normale se joue
avec six pièces par joueur.

- Tout le monde commence par miser une pièce.
- Ensuite les joueurs font tous un premier lancer de dé, dans
l'ordre des aiguilles d'une horloge.
- En commençant par le premier joueur, chacun peut 
annoncer s'il augmente la mise d'une pièce supplémentaire. 
Dans ce cas, tous ceux qui veulent suivre doivent également 
miser une pièce de plus. les joueurs qui ne suivent pas se 
couchent et sortent du tour en perdant leur mise. 
On ne peut augmenter la mise qu'une seule fois par tour,
tous joueurs confondus.
- Lorsque tout le monde a suivi ou s'est couché,
chaque joueur sélectionne les dés qu'il souhaite relancer,
puis les relance.

La combinaison de la plus haute valeur l'emporte et
le vainqueur rafle la mise !

Liste des combinaisons par ordre de valeur :

- POKER : Cinq dés de même valeur
- CARRÉ : Quatre dés de même valeur
- FULL : Un brelan + une paire
- GRANDE SUITE : Suite de dés allant de 2 à 6
- PETITE SUITE : Suite de dés allant de 1 à 5
- BRELAN : Trois dés de même valeur
- DOUBLE PAIRE : Deux paires
- PAIRE : Deux dés de même valeur

Quand les combinaisons sont de valeur identique, celle qui
comporte les dés les plus hauts est déclarée gagnante !]]
    }
	
L["enUS"] = {
        ["Roll the dice"] = "Roll the dice",
		["Reroll the dice"] = "Reroll the dice",
        ["Rules"] = "Rules >>",
		["Rolls the dice and get "] = "Rolls the dice and get ",
		["Rerolls the dice and get "] = "Rerolls the dice and get ",
		["RuleTextLib"] = [[This is a dice poker game for two or more players. 
The objective is to achieve the best combination in two dice 
rolls. The first player is the one who won the previous round. 
A normal game is played with six pieces per player.

- Everyone starts by betting one piece.
- Then the players all make a first roll of the dice, in 
clockwise order.
- Starting with the first player, each player can announce 
if they increase the bet by an additional piece. In this 
case, everyone who wants to follow must also bet one more 
piece. Players who do not follow fold and drop out of the 
round, losing their bet. The bet can only be increased once 
per round, for all players.
- When everyone has followed or folded, each player selects 
the dice they wish to reroll, then rerolls them.

The combination of the highest value wins and the 
winner takes the pot!

List of combinations in order of value:

- POKER: Five dice of the same value
- 4-OF-A-KIND: Four dice of the same value
- FULL HOUSE: A three-of-a-kind + a pair
- GREAT STRAIGHT: Dice sequence ranging from 2 to 6
- SMALL STRAIGHT Dice sequence ranging from 1 to 5
- 3-OF-A-KIND: Three dice of the same value
- DOUBLE PAIR: Two pairs
- PAIR: Two dice of the same value

When the combinations are of equal value, the one that 
has the highest dice is declared the winner!]]
    }
    -- Ajoutez d'autres langues ici...
