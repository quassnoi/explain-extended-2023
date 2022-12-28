WITH    RECURSIVE
        basicMoves (initial, cornerMove, edgeMove, cornerTurn, edgeTurn) AS
        (
        VALUES
                (
                'U',
                ARRAY[ 4,  1,  2,  7,  3,  5,  6,  0]::INT[],  ARRAY[ 8,  1,  2, 11,  4,  5,  6,  7,  3,  9, 10,  0]::INT[],
                ARRAY[ 2,  0,  0,  2,  1,  0,  0,  1]::INT[],  ARRAY[ 1,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  1]::INT[]
                ),
                (
                'D',
                ARRAY[ 0,  5,  6,  3,  4,  2,  1,  7]::INT[],  ARRAY[ 0, 10,  9,  3,  4,  5,  6,  7,  8,  1,  2, 11]::INT[],
                ARRAY[ 0,  2,  2,  0,  0,  1,  1,  0]::INT[],  ARRAY[ 0,  1,  1,  0,  0,  0,  0,  0,  0,  1,  1,  0]::INT[]
                ),
                (
                'F',
                ARRAY[ 0,  6,  2,  4,  1,  5,  3,  7]::INT[],  ARRAY[ 0,  1,  2,  3,  4,  9,  8,  7,  5,  6, 10, 11]::INT[],
                ARRAY[ 0,  1,  0,  1,  2,  0,  2,  0]::INT[],  ARRAY[ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]::INT[]
                ),
                (
                'B',
                ARRAY[ 7,  1,  5,  3,  4,  0,  6,  2]::INT[],  ARRAY[ 0,  1,  2,  3, 11,  5,  6, 10,  8,  9,  4,  7]::INT[],
                ARRAY[ 1,  0,  1,  0,  0,  2,  0,  2]::INT[],  ARRAY[ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]::INT[]
                ),
                (
                'L',
                ARRAY[ 5,  4,  2,  3,  0,  1,  6,  7]::INT[],  ARRAY[ 4,  5,  2,  3,  1,  0,  6,  7,  8,  9, 10, 11]::INT[],
                ARRAY[ 0,  0,  0,  0,  0,  0,  0,  0]::INT[],  ARRAY[ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]::INT[]
                ),
                (
                'R',
                ARRAY[ 0,  1,  7,  6,  4,  5,  2,  3]::INT[],  ARRAY[ 0,  1,  7,  6,  4,  5,  2,  3,  8,  9, 10, 11]::INT[],
                ARRAY[ 0,  0,  0,  0,  0,  0,  0,  0]::INT[],  ARRAY[ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]::INT[]
                )
        ),
        moves (turns, initial, move, cornerMove, edgeMove, cornerTurn, edgeTurn) AS MATERIALIZED
        (
        SELECT  1 AS turns, initial, bm.*
        FROM    basicMoves bm
        UNION ALL
        SELECT  turns + 1, move,
                CASE turns + 1 WHEN 2 THEN initial || '2' WHEN 3 THEN LOWER(initial) END,
                t.*
        FROM    moves am
        JOIN    basicMoves bm
        USING   (initial)
        CROSS JOIN LATERAL
                turn(am.cornerMove, am.edgeMove, am.cornerTurn, am.edgeTurn, bm.cornerMove, bm.edgeMove, bm.cornerTurn, bm.edgeTurn) t
        WHERE   turns <= 2
        ),
        g1s AS MATERIALIZED
        (
        SELECT  0 AS depth, 0 AS distance,
                '000000000000' AS state,
                ARRAY[]::TEXT[] AS moves
        ),
        pass1 AS
        (
        SELECT  distance, state, moves
        FROM    g1s
        UNION ALL
        SELECT  DISTINCT ON (newState)
                distance + 1, newState, moves || move
        FROM    g1s
        CROSS JOIN
                moves
        CROSS JOIN LATERAL
                (
                SELECT  STRING_AGG(((SUBSTRING(state FROM source + 1 FOR 1)::INT + edgeTurn[destination] + 2) % 2)::TEXT, '')
                FROM    UNNEST(edgeMove) WITH ORDINALITY AS move (source, destination)
                ) AS n1 (newState)
        WHERE   newState NOT IN
                (
                SELECT  state
                FROM    g1s
                )
        )
SELECT  distance, state, moves
FROM    pass1
UNION ALL
SELECT  DISTINCT ON (newState)
        distance + 1, newState, moves || move
FROM    pass1
CROSS JOIN
        moves
CROSS JOIN LATERAL
        (
        SELECT  STRING_AGG(((SUBSTRING(state FROM source + 1 FOR 1)::INT + edgeTurn[destination] + 2) % 2)::TEXT, '')
        FROM    UNNEST(edgeMove) WITH ORDINALITY AS move (source, destination)
        ) AS n1 (newState)
WHERE   newState NOT IN
        (
        SELECT  state
        FROM    pass1
        )
