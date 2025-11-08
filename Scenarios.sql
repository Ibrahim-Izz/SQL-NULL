SELECT '╔════════════════════════════════════════════╗';
SELECT '║  NULL KILLER #1: LEFT JOIN + WHERE        ║';
SELECT '╚════════════════════════════════════════════╝';

-- Request: Get all players and their goals in completed matches
-- Critical: Hazard and Bale are RETIRED - they have NO recent goals!

SELECT '❌ WRONG (WHERE clause)' AS test;
SELECT 
    p.player_id,
    p.player_name,
    p.position,
    p.current_team_id,
    g.goal_id,
    g.minute,
    g.goal_type
FROM players p
LEFT JOIN goals g ON p.player_id = g.player_id
LEFT JOIN matches m ON g.match_id = m.match_id
WHERE m.status = 'completed'
ORDER BY p.player_id;
-- Expected: 8 players with goals
-- Lost: De Bruyne (4 - playmaker), Busquets (9 - defensive mid), Hazard (10 - retired), 
--       Bale (11 - retired), Youth Prospect (12 - no goals yet)


SELECT '✅ CORRECT (ON clause)' AS test;
SELECT 
    p.player_id,
    p.player_name,
    p.position,
    p.current_team_id,
    g.goal_id,
    g.minute,
    g.goal_type
FROM players p
LEFT JOIN goals g ON p.player_id = g.player_id
LEFT JOIN matches m ON g.match_id = m.match_id 
    AND m.status = 'completed'
ORDER BY p.player_id;
-- Expected: ALL 12 players shown (retired players and midfielders included with NULL goals)

-- Count comparison

SELECT '📊 COUNT COMPARISON' AS test;
SELECT 
    'WHERE clause' AS method,
    COUNT(DISTINCT p.player_id) AS players_shown,
    COUNT(g.goal_id) AS goals_shown
FROM players p
LEFT JOIN goals g ON p.player_id = g.player_id
LEFT JOIN matches m ON g.match_id = m.match_id
WHERE m.status = 'completed'
UNION ALL
SELECT 
    'ON clause' AS method,
    COUNT(DISTINCT p.player_id) AS players_shown,
    COUNT(g.goal_id) AS goals_shown
FROM players p
LEFT JOIN goals g ON p.player_id = g.player_id
LEFT JOIN matches m ON g.match_id = m.match_id 
    AND m.status = 'completed';


-- ============================================
-- NULL KILLER #2: WHERE col <> value
-- ============================================


SELECT '╔════════════════════════════════════════════╗';
SELECT '║  NULL KILLER #2: <> Comparison            ║';
SELECT '╚════════════════════════════════════════════╝';

-- Scenario A: Get all players that are NOT Forwards
-- Critical: Hazard and Bale are retired with NULL position!

SELECT '❌ WRONG: Retired players with NULL position excluded' AS test;
SELECT player_id, player_name, position, nationality, current_team_id
FROM players
WHERE position <> 'Forward'
ORDER BY player_id;
-- Expected: 2 rows (De Bruyne, Busquets - both midfielders)
-- Lost: Hazard (10) and Bale (11) with NULL position (retired)


SELECT '✅ CORRECT: NULL positions included' AS test;
SELECT player_id, player_name, position, nationality, current_team_id
FROM players
WHERE position <> 'Forward'
   OR position IS NULL
ORDER BY player_id;
-- Expected: 4 rows (includes retired players)

-- Scenario B: Goals NOT scored with penalties

SELECT '❌ WRONG: Goals with NULL type excluded' AS test;
SELECT goal_id, player_id, minute, goal_type, penalty
FROM goals
WHERE goal_type <> 'penalty'
ORDER BY goal_id;
-- Expected: 11 rows
-- Lost: Goals 305 and 314 with NULL type (data entry incomplete)


SELECT '✅ CORRECT: NULL goal types included' AS test;
SELECT goal_id, player_id, minute, goal_type, penalty
FROM goals
WHERE goal_type <> 'penalty'
   OR goal_type IS NULL
ORDER BY goal_id;
-- Expected: 13 rows (includes incomplete data)


-- ============================================
-- NULL KILLER #3: Aggregations Ignore NULL
-- ============================================


SELECT '╔════════════════════════════════════════════╗';
SELECT '║  NULL KILLER #3: Aggregations              ║';
SELECT '╚════════════════════════════════════════════╝';

-- Scenario A: Average player market value
-- Critical: Hazard and Bale have NULL value (retired, no market)!

SELECT '❌ MISLEADING: Retired players not counted in average' AS test;
SELECT
    AVG(market_value) AS avg_value,
    COUNT(market_value) AS players_with_value,
    COUNT(*) AS total_players
FROM players;
-- Shows: avg of only active players (10 out of 12 counted)


SELECT '✅ CORRECT: Shows NULL gap explicitly' AS test;
SELECT
    SUM(market_value) / COUNT(*) AS avg_including_retired,
    AVG(market_value) AS avg_active_only,
    COUNT(*) AS total_players,
    COUNT(market_value) AS active_players,
    SUM(CASE WHEN market_value IS NULL THEN 1 ELSE 0 END) AS retired_players
FROM players;

-- Scenario B: Average transfer fees
-- Critical: Many transfers have NULL fees (free transfers, undisclosed)!


SELECT '❌ MISLEADING: Free transfers and undisclosed fees ignored' AS test;
SELECT
    SUM(fee) AS total_fees_paid,
    AVG(fee) AS avg_fee,
    COUNT(fee) AS transfers_with_fee
FROM transfers;
-- Lost: 5 transfers with NULL fee aren't counted!


SELECT '✅ CORRECT: Shows full picture' AS test;
SELECT
    SUM(fee) AS total_disclosed_fees,
    SUM(COALESCE(fee, 0)) AS total_treating_null_as_zero,
    COUNT(*) AS total_transfers,
    COUNT(fee) AS transfers_with_disclosed_fee,
    SUM(CASE WHEN fee IS NULL THEN 1 ELSE 0 END) AS free_or_undisclosed
FROM transfers;

-- Scenario C: Player ratings in matches

SELECT '💎 Match Ratings Analysis' AS test;
SELECT
    'Excluding NULLs' AS method,
    AVG(rating) AS average_rating,
    COUNT(*) AS rated_performances
FROM match_appearances
WHERE rating IS NOT NULL
UNION ALL
SELECT
    'All appearances' AS method,
    AVG(COALESCE(rating, 6.0)) AS average_rating_default_6,
    COUNT(*) AS total_appearances
FROM match_appearances;


-- ============================================
-- NULL KILLER #4: NOT IN with NULL
-- ============================================


SELECT '╔════════════════════════════════════════════╗';
SELECT '║  NULL KILLER #4: NOT IN                   ║';
SELECT '╚════════════════════════════════════════════╝';

-- Scenario A: Players NOT from Brazil or Argentina
-- Critical: Youth prospect has NULL nationality (dual citizen deciding)!

SELECT '❌ WRONG: Returns ZERO rows because of NULL!' AS test;
SELECT player_id, player_name, nationality, position
FROM players
WHERE nationality NOT IN ('BR', 'AR', NULL)
ORDER BY player_id;
-- Expected: ZERO rows! NULL in list kills everything!


SELECT '✅ CORRECT (Method 1): Handle NULL explicitly' AS test;
SELECT player_id, player_name, nationality, position
FROM players
WHERE (nationality NOT IN ('BR', 'AR') OR nationality IS NULL)
ORDER BY player_id;
-- Expected: 8 rows (includes Youth Prospect with undecided nationality)


SELECT '✅ CORRECT (Method 2): COALESCE' AS test;
SELECT player_id, player_name, nationality, position
FROM players
WHERE COALESCE(nationality, 'UNKNOWN') NOT IN ('BR', 'AR')
ORDER BY player_id;
-- Expected: 8 rows

-- Scenario B: Leagues NOT in tier 1

SELECT '❌ WRONG: NULL tier kills query' AS test;
SELECT league_id, league_name, country, tier
FROM leagues
WHERE tier NOT IN (1, NULL)
ORDER BY league_id;
-- Expected: ZERO rows!


SELECT '✅ CORRECT: Include leagues without official tier' AS test;
SELECT league_id, league_name, country, tier
FROM leagues
WHERE (tier NOT IN (1) OR tier IS NULL)
ORDER BY league_id;
-- Expected: 1 row (MLS without official tier ranking)