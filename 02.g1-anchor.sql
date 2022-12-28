WITH    g1s AS MATERIALIZED
        (
        SELECT  0 AS depth, 0 AS distance,
                '000000000000' AS state,
                ARRAY[]::TEXT[] AS moves
        )
SELECT  *
FROM    g1s