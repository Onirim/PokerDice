local _, core = ...
core.Hands = {}
local Hands = core.Hands

Hands.Rank = {
    HIGH_CARD = 1,
    PAIR = 2,
    TWO_PAIR = 3,
    THREE_KIND = 4,
    SMALL_STRAIGHT = 5,
    LARGE_STRAIGHT = 6,
    FULL_HOUSE = 7,
    FOUR_KIND = 8,
    FIVE_KIND = 9,
}

-- diceValues: table de 5 entiers 1..6
-- retourne { rank, tiebreak = {...}, handKey }
function Hands.Evaluate(diceValues)
    local counts = {0, 0, 0, 0, 0, 0}
    for _, v in ipairs(diceValues) do
        counts[v] = counts[v] + 1
    end

    -- groupes {value, count} triés par count desc puis value desc
    local groups = {}
    for v = 6, 1, -1 do
        if counts[v] > 0 then
            table.insert(groups, {value = v, count = counts[v]})
        end
    end
    table.sort(groups, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.value > b.value
    end)

    if groups[1].count == 5 then
        return {rank = Hands.Rank.FIVE_KIND, tiebreak = {groups[1].value}, handKey = "HandFiveKind"}
    end

    if groups[1].count == 4 then
        return {rank = Hands.Rank.FOUR_KIND, tiebreak = {groups[1].value, groups[2].value}, handKey = "HandFourKind"}
    end

    if groups[1].count == 3 and groups[2] and groups[2].count == 2 then
        return {rank = Hands.Rank.FULL_HOUSE, tiebreak = {groups[1].value, groups[2].value}, handKey = "HandFullHouse"}
    end

    -- grande suite : 5 valeurs distinctes formant 1-5 ou 2-6
    if #groups == 5 then
        if counts[1] > 0 and counts[2] > 0 and counts[3] > 0 and counts[4] > 0 and counts[5] > 0 then
            return {rank = Hands.Rank.LARGE_STRAIGHT, tiebreak = {5}, handKey = "HandLargeStraight"}
        end
        if counts[2] > 0 and counts[3] > 0 and counts[4] > 0 and counts[5] > 0 and counts[6] > 0 then
            return {rank = Hands.Rank.LARGE_STRAIGHT, tiebreak = {6}, handKey = "HandLargeStraight"}
        end
    end

    -- petite suite : fenêtre de 4 valeurs consécutives présentes, du plus haut vers le plus bas
    local windows = {{3, 4, 5, 6}, {2, 3, 4, 5}, {1, 2, 3, 4}}
    for _, w in ipairs(windows) do
        if counts[w[1]] > 0 and counts[w[2]] > 0 and counts[w[3]] > 0 and counts[w[4]] > 0 then
            return {rank = Hands.Rank.SMALL_STRAIGHT, tiebreak = {w[4]}, handKey = "HandSmallStraight"}
        end
    end

    if groups[1].count == 3 then
        local kickers = {groups[2].value, groups[3].value}
        table.sort(kickers, function(a, b) return a > b end)
        return {rank = Hands.Rank.THREE_KIND, tiebreak = {groups[1].value, kickers[1], kickers[2]}, handKey = "HandThreeKind"}
    end

    if groups[1].count == 2 and groups[2] and groups[2].count == 2 then
        return {rank = Hands.Rank.TWO_PAIR, tiebreak = {groups[1].value, groups[2].value, groups[3].value}, handKey = "HandTwoPair"}
    end

    if groups[1].count == 2 then
        local kickers = {groups[2].value, groups[3].value, groups[4].value}
        table.sort(kickers, function(a, b) return a > b end)
        return {rank = Hands.Rank.PAIR, tiebreak = {groups[1].value, kickers[1], kickers[2], kickers[3]}, handKey = "HandPair"}
    end

    local sorted = {}
    for _, v in ipairs(diceValues) do table.insert(sorted, v) end
    table.sort(sorted, function(a, b) return a > b end)
    return {rank = Hands.Rank.HIGH_CARD, tiebreak = sorted, handKey = "HandHighCard"}
end

-- retourne 1 si a > b, -1 si a < b, 0 si égalité stricte
function Hands.Compare(a, b)
    if a.rank ~= b.rank then
        return a.rank > b.rank and 1 or -1
    end
    for i = 1, #a.tiebreak do
        if a.tiebreak[i] ~= b.tiebreak[i] then
            return a.tiebreak[i] > b.tiebreak[i] and 1 or -1
        end
    end
    return 0
end
