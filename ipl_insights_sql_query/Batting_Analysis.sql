-- ════════════════════════════════════════════════════════════
-- SECTION 1: BATTING ANALYTICS
-- ════════════════════════════════════════════════════════════
 
-- 1.1  All-time Batting Leaderboard with Strike Rate, Average & Boundary %

SELECT
    d.batter,
    p.player_full_name,
    COUNT(DISTINCT d.match_id)                                          AS matches_played,
    SUM(d.batter_runs)                                                  AS total_runs,
    ROUND(SUM(d.batter_runs) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE d.is_wide_ball = FALSE), 0), 2) AS strike_rate,
    ROUND(SUM(d.batter_runs) * 1.0
          / NULLIF(COUNT(DISTINCT CASE WHEN d.is_wicket THEN d.match_id || '-' || d.innings END), 0), 2)
                                                                        AS batting_average,
    SUM(CASE WHEN d.batter_runs = 4 THEN 1 ELSE 0 END)                 AS fours,
    SUM(CASE WHEN d.batter_runs = 6 THEN 1 ELSE 0 END)                 AS sixes,
    ROUND(
        (SUM(CASE WHEN d.batter_runs IN (4,6) THEN 1 ELSE 0 END) * 100.0)
        / NULLIF(COUNT(*) FILTER (WHERE d.is_wide_ball = FALSE), 0), 2) AS boundary_pct
FROM deliveries d
LEFT JOIN players p ON d.batter = p.player_name
WHERE d.is_super_over = FALSE
GROUP BY d.batter, p.player_full_name
HAVING SUM(d.batter_runs) >= 500
ORDER BY total_runs DESC;
 
 
-- 1.2  Season-wise Orange Cap Race (Top Run-scorer per Season)

WITH season_runs AS (
    SELECT
        m.season,
        d.batter,
        SUM(d.batter_runs) AS runs,
        ROUND(SUM(d.batter_runs) * 100.0
              / NULLIF(COUNT(*) FILTER (WHERE d.is_wide_ball = FALSE), 0), 2) AS sr
    FROM deliveries d
    JOIN matches m ON d.match_id = m.match_id
    WHERE d.is_super_over = FALSE
    GROUP BY m.season, d.batter
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY season ORDER BY runs DESC) AS rnk
    FROM season_runs
)
SELECT season, batter, runs, sr AS strike_rate
FROM ranked
WHERE rnk = 1
ORDER BY season;
 
 
-- 1.3  Batter Performance in Death Overs (16–20) vs Power Play (1–6)

SELECT
    d.batter,
    SUM(CASE WHEN d.over_number BETWEEN 1  AND 6  THEN d.batter_runs ELSE 0 END) AS pp_runs,
    ROUND(SUM(CASE WHEN d.over_number BETWEEN 1  AND 6  THEN d.batter_runs ELSE 0 END) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE d.over_number BETWEEN 1 AND 6 AND d.is_wide_ball = FALSE), 0), 2)
                                                                           AS pp_sr,
    SUM(CASE WHEN d.over_number BETWEEN 16 AND 20 THEN d.batter_runs ELSE 0 END) AS death_runs,
    ROUND(SUM(CASE WHEN d.over_number BETWEEN 16 AND 20 THEN d.batter_runs ELSE 0 END) * 100.0
          / NULLIF(COUNT(*) FILTER (WHERE d.over_number BETWEEN 16 AND 20 AND d.is_wide_ball = FALSE), 0), 2)
                                                                           AS death_sr
FROM deliveries d
WHERE d.is_super_over = FALSE
GROUP BY d.batter
HAVING SUM(d.batter_runs) >= 300
ORDER BY death_sr DESC;
 
 
-- 1.4  Century & Half-Century Counter per Batter

WITH innings_scores AS (
    SELECT
        d.match_id,
        d.innings,
        d.batter,
        SUM(d.batter_runs) AS inns_runs
    FROM deliveries d
    WHERE d.is_super_over = FALSE
    GROUP BY d.match_id, d.innings, d.batter
)
SELECT
    batter,
    COUNT(*)                                       AS innings,
    SUM(CASE WHEN inns_runs >= 100 THEN 1 ELSE 0 END) AS centuries,
    SUM(CASE WHEN inns_runs BETWEEN 50 AND 99 THEN 1 ELSE 0 END) AS half_centuries,
    MAX(inns_runs)                                 AS highest_score,
    ROUND(AVG(inns_runs), 2)                       AS avg_score
FROM innings_scores
GROUP BY batter
HAVING COUNT(*) >= 20
ORDER BY centuries DESC, half_centuries DESC;