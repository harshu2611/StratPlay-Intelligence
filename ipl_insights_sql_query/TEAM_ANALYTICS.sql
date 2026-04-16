-- ════════════════════════════════════════════════════════════
-- SECTION 3: TEAM ANALYTICS
-- ════════════════════════════════════════════════════════════

-- 3.1  Team Win-Loss Record by Season
SELECT
    m.season,
    m.team1                                         AS team,
    COUNT(*)                                         AS matches_played,
    SUM(CASE WHEN m.match_winner = m.team1 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN m.match_winner != m.team1 AND m.result != 'no result' THEN 1 ELSE 0 END) AS losses,
    SUM(CASE WHEN m.result = 'no result' THEN 1 ELSE 0 END) AS no_result,
    ROUND(SUM(CASE WHEN m.match_winner = m.team1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*),0), 2) AS win_pct
FROM (
    SELECT match_id, season, team1, match_winner, result FROM matches
    UNION ALL
    SELECT match_id, season, team2 AS team1, match_winner, result FROM matches
) m
WHERE m.result != 'no result'
GROUP BY m.season, m.team1
ORDER BY m.season, wins DESC;


-- 3.2  Average Team Score per Phase (Power Play / Middle / Death) per Season
SELECT
    m.season,
    d.team_batting,
    ROUND(AVG(CASE WHEN d.over_number BETWEEN 1  AND 6  THEN phase_runs END), 2) AS avg_pp_score,
    ROUND(AVG(CASE WHEN d.over_number BETWEEN 7  AND 15 THEN phase_runs END), 2) AS avg_mid_score,
    ROUND(AVG(CASE WHEN d.over_number BETWEEN 16 AND 20 THEN phase_runs END), 2) AS avg_death_score
FROM (
    SELECT match_id, team_batting, over_number, SUM(total_runs) AS phase_runs
    FROM deliveries
    WHERE is_super_over = FALSE AND innings IN (1,2)
    GROUP BY match_id, team_batting, over_number
) d
JOIN matches m ON d.match_id = m.match_id
GROUP BY m.season, d.team_batting
ORDER BY m.season, avg_death_score DESC;


-- 3.3  Toss Impact — Win Rate When Batting First vs Chasing
SELECT
    m.toss_decision,
    COUNT(*)                                                        AS matches,
    SUM(CASE WHEN m.toss_winner = m.match_winner THEN 1 ELSE 0 END) AS toss_winner_won,
    ROUND(SUM(CASE WHEN m.toss_winner = m.match_winner THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS toss_win_advantage_pct
FROM matches m
WHERE m.result NOT IN ('no result','tie')
GROUP BY m.toss_decision;


-- 3.4  Venue-wise Average Score & Highest Total
SELECT
    m.venue,
    m.city,
    COUNT(DISTINCT m.match_id)                                AS matches_hosted,
    ROUND(AVG(inns.total_score), 2)                           AS avg_1st_innings_score,
    MAX(inns.total_score)                                     AS highest_team_total,
    ROUND(AVG(CASE WHEN inns.innings = 2 THEN inns.total_score END), 2) AS avg_2nd_innings_score
FROM matches m
JOIN (
    SELECT match_id, innings, SUM(total_runs) AS total_score
    FROM deliveries
    WHERE is_super_over = FALSE AND innings IN (1,2)
    GROUP BY match_id, innings
) inns ON m.match_id = inns.match_id
GROUP BY m.venue, m.city
HAVING COUNT(DISTINCT m.match_id) >= 5
ORDER BY avg_1st_innings_score DESC;
