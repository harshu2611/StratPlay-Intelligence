-- ════════════════════════════════════════════════════════════
-- SECTION 2: BOWLING ANALYTICS
-- ════════════════════════════════════════════════════════════
 
-- 2.1  All-time Bowling Leaderboard — Wickets, Economy, Average, SR

SELECT
    d.bowler,
    p.player_full_name,
    COUNT(DISTINCT d.match_id)                                                  AS matches,
    SUM(CASE WHEN d.is_wicket AND d.wicket_kind NOT IN ('run out','retired hurt','obstructing the field')
             THEN 1 ELSE 0 END)                                                 AS wickets,
    ROUND(
        SUM(d.total_runs - d.wide_ball_runs - d.no_ball_runs) * 6.0
        / NULLIF(COUNT(*) FILTER (WHERE d.is_wide_ball = FALSE AND d.is_no_ball = FALSE), 0), 2)
                                                                                AS economy,
    ROUND(
        SUM(d.total_runs - d.wide_ball_runs - d.no_ball_runs) * 1.0
        / NULLIF(SUM(CASE WHEN d.is_wicket AND d.wicket_kind NOT IN ('run out','retired hurt','obstructing the field')
                          THEN 1 ELSE 0 END), 0), 2)                           AS bowling_avg,
    ROUND(
        COUNT(*) FILTER (WHERE d.is_wide_ball = FALSE AND d.is_no_ball = FALSE) * 1.0
        / NULLIF(SUM(CASE WHEN d.is_wicket AND d.wicket_kind NOT IN ('run out','retired hurt','obstructing the field')
                          THEN 1 ELSE 0 END), 0), 2)                           AS bowling_sr
FROM deliveries d
LEFT JOIN players p ON d.bowler = p.player_name
WHERE d.is_super_over = FALSE
GROUP BY d.bowler, p.player_full_name
HAVING SUM(CASE WHEN d.is_wicket AND d.wicket_kind NOT IN ('run out','retired hurt','obstructing the field')
                THEN 1 ELSE 0 END) >= 30
ORDER BY wickets DESC;
 
 
-- 2.2  Purple Cap — Season-wise Top Wicket Takers

WITH season_wickets AS (
    SELECT
        m.season,
        d.bowler,
        SUM(CASE WHEN d.is_wicket AND d.wicket_kind NOT IN ('run out','retired hurt','obstructing the field')
                 THEN 1 ELSE 0 END) AS wickets,
        ROUND(SUM(d.total_runs - d.wide_ball_runs - d.no_ball_runs) * 6.0
              / NULLIF(COUNT(*) FILTER (WHERE d.is_wide_ball = FALSE AND d.is_no_ball = FALSE), 0), 2) AS economy
    FROM deliveries d
    JOIN matches m ON d.match_id = m.match_id
    WHERE d.is_super_over = FALSE
    GROUP BY m.season, d.bowler
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY season ORDER BY wickets DESC, economy ASC) AS rnk
    FROM season_wickets
)
SELECT season, bowler, wickets, economy
FROM ranked
WHERE rnk = 1
ORDER BY season;
 
 
-- 2.3  Bowler Effectiveness in Power Play vs Death Overs

SELECT
    d.bowler,
    d.bowler_type,
    ROUND(SUM(CASE WHEN d.over_number BETWEEN 1 AND 6 THEN d.total_runs ELSE 0 END) * 6.0
          / NULLIF(COUNT(*) FILTER (WHERE d.over_number BETWEEN 1 AND 6
                                     AND d.is_wide_ball = FALSE AND d.is_no_ball = FALSE), 0), 2) AS pp_economy,
    ROUND(SUM(CASE WHEN d.over_number BETWEEN 16 AND 20 THEN d.total_runs ELSE 0 END) * 6.0
          / NULLIF(COUNT(*) FILTER (WHERE d.over_number BETWEEN 16 AND 20
                                     AND d.is_wide_ball = FALSE AND d.is_no_ball = FALSE), 0), 2) AS death_economy,
    SUM(CASE WHEN d.is_wicket THEN 1 ELSE 0 END) AS total_wickets
FROM deliveries d
WHERE d.is_super_over = FALSE
GROUP BY d.bowler, d.bowler_type
HAVING COUNT(DISTINCT d.match_id) >= 15
ORDER BY death_economy ASC;
 
 
-- 2.4  Five-wicket Haul Tracker

WITH match_wickets AS (
    SELECT
        d.match_id,
        d.innings,
        d.bowler,
        m.season,
        SUM(CASE WHEN d.is_wicket AND d.wicket_kind NOT IN ('run out','retired hurt','obstructing the field')
                 THEN 1 ELSE 0 END) AS wickets_in_innings
    FROM deliveries d
    JOIN matches m ON d.match_id = m.match_id
    WHERE d.is_super_over = FALSE
    GROUP BY d.match_id, d.innings, d.bowler, m.season
)
SELECT
    bowler,
    COUNT(*) FILTER (WHERE wickets_in_innings >= 5) AS five_wicket_hauls,
    COUNT(*) FILTER (WHERE wickets_in_innings >= 4) AS four_plus_wicket_hauls,
    MAX(wickets_in_innings)                          AS best_bowling_figures
FROM match_wickets
GROUP BY bowler
HAVING COUNT(*) FILTER (WHERE wickets_in_innings >= 4) > 0
ORDER BY five_wicket_hauls DESC, four_plus_wicket_hauls DESC;